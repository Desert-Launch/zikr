import SwiftUI
import WidgetKit

/// One rendered moment of the widget.
struct PrayerEntry: TimelineEntry {
    let date: Date
    let snapshot: PrayerSnapshot?
    let resolution: PrayerSnapshot.Resolution?

    static func at(_ date: Date, snapshot: PrayerSnapshot?) -> PrayerEntry {
        PrayerEntry(date: date, snapshot: snapshot, resolution: snapshot?.resolve(at: date))
    }
}

/// Builds the timeline from whatever snapshot the app last wrote.
///
/// The countdown text changes every minute and the featured prayer flips at
/// each salah, so the timeline is one entry per minute up to
/// `horizon` ahead (or the next salah, if sooner), then `.atEnd` asks for a
/// fresh one. That is a handful of reloads a day — well inside WidgetKit's
/// budget — and the app's own `reloadTimelines` after a new snapshot adds a
/// few more. No entry is ever generated from a clock guess: every one is
/// resolved from the snapshot exactly as the Android widget resolves it.
struct PrayerProvider: TimelineProvider {

    /// How far one timeline reaches before asking for another.
    private let horizon: TimeInterval = 4 * 60 * 60

    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry.at(Date(), snapshot: PrayerSnapshot.sample())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        let now = Date()
        // The gallery gets the sample; a placed widget gets the real thing.
        let snapshot = context.isPreview ? PrayerSnapshot.sample(now: now) : (PrayerSnapshot.load() ?? PrayerSnapshot.sample(now: now))
        completion(PrayerEntry.at(now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let now = Date()
        guard let snapshot = PrayerSnapshot.load(), snapshot.resolve(at: now) != nil else {
            // Nothing to count down to. The app's next publish reloads us;
            // until then, look again in an hour in case a snapshot arrives
            // through a path that forgot to ask.
            let entry = PrayerEntry.at(now, snapshot: PrayerSnapshot.load())
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60 * 60))))
            return
        }

        var entries: [PrayerEntry] = [PrayerEntry.at(now, snapshot: snapshot)]

        // The moments the layout changes on its own: the next salah and the
        // next local midnight (date row). Whichever comes first ends this
        // timeline, one second past so the boundary is strictly behind us.
        let nextSalah = snapshot.salahDates(after: now).first ?? now.addingTimeInterval(horizon)
        let end = min(nextSalah, snapshot.nextMidnight(after: now), now.addingTimeInterval(horizon))

        // One entry per minute, aligned to the minute, up to the end.
        var tick = Self.nextMinute(after: now)
        while tick < end {
            entries.append(PrayerEntry.at(tick, snapshot: snapshot))
            tick.addTimeInterval(60)
        }
        entries.append(PrayerEntry.at(end.addingTimeInterval(1), snapshot: snapshot))

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private static func nextMinute(after date: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        return Date(timeIntervalSince1970: (seconds / 60).rounded(.down) * 60 + 60)
    }
}

/// The home-screen prayer widget: next prayer, countdown, window progress,
/// today's dates and the day's other prayer times.
struct PrayerWidget: Widget {

    /// Must match `DSPrayerWidget.iosKind` in Dart — it is what
    /// `WidgetCenter.reloadTimelines(ofKind:)` is called with.
    static let kind = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة")
        .description("الصلاة القادمة، العدّ التنازلي، ومواقيت اليوم")
        .supportedFamilies([.systemSmall, .systemMedium])
        // The card pads itself (see PrayerWidgetView) so it looks the same on
        // iOS 15–16, where the system adds no margins, and on 17+, where it
        // would otherwise add its own on top.
        .contentMarginsDisabled()
    }
}
