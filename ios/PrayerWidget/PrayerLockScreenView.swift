import SwiftUI
import WidgetKit

// MARK: - Lock Screen (iOS 16+)

/// The Lock Screen faces of the prayer widget — iOS's counterpart to the
/// Android app's pinned notification. Only the user can place them (long-press
/// the Lock Screen → Customize); iOS gives apps no way to, which is why the
/// app's Settings explains how rather than offering a switch.
///
/// The system draws these in its vibrant, monochrome style over the
/// wallpaper, so they carry no palette: hierarchy comes from weight and the
/// primary/secondary styles. The countdown is a live timer text, so it ticks
/// by the second between the provider's minute entries.
@available(iOS 16.0, *)
struct LockScreenPrayerView: View {
    let entry: PrayerEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .environment(\.layoutDirection, (entry.snapshot?.rtl ?? true) ? .rightToLeft : .leftToRight)
            .widgetURL(launchURL)
            .clearWidgetBackground()
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot, let resolution = entry.resolution {
            switch family {
            case .accessoryInline:
                InlinePrayerView(snapshot: snapshot, resolution: resolution)
            case .accessoryCircular:
                CircularPrayerView(now: entry.date, snapshot: snapshot, resolution: resolution)
            default:
                RectangularPrayerView(now: entry.date, snapshot: snapshot, resolution: resolution)
            }
        } else {
            LockScreenEmptyView(snapshot: entry.snapshot, family: family)
        }
    }
}

@available(iOS 16.0, *)
extension WidgetFamily {
    var isLockScreen: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
        default: return false
        }
    }
}

private extension PrayerSnapshot.Resolution {
    /// `صلاة العصر` — the same heading as the home card and the widget.
    func nextTitle(_ labels: PrayerSnapshot.Labels) -> String {
        labels.nextName.replacingOccurrences(of: "{{name}}", with: labels.prayer(next.k))
    }
}

/// The rectangle under the clock: next prayer and its time, the live
/// countdown, and today's Hijri date.
@available(iOS 16.0, *)
private struct RectangularPrayerView: View {
    let now: Date
    let snapshot: PrayerSnapshot
    let resolution: PrayerSnapshot.Resolution

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(resolution.nextTitle(snapshot.labels)) · \(resolution.next.t)")
                .font(.headline)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            // H:MM:SS, counting down; it holds at zero rather than counting
            // up, and the provider's entry a second past the salah moves on.
            Text(timerInterval: now...max(now, resolution.next.date), countsDown: true)
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                .lineLimit(1)
                .multilineTextAlignment(.leading)
            Text(resolution.today.hijri)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The single line above the clock.
@available(iOS 16.0, *)
private struct InlinePrayerView: View {
    let snapshot: PrayerSnapshot
    let resolution: PrayerSnapshot.Resolution

    var body: some View {
        Text("\(snapshot.labels.prayer(resolution.next.k)) · \(resolution.next.t)")
    }
}

/// The small circle: the next prayer and its time inside a ring that fills
/// as the current window runs out — the home widget's progress bar, bent.
@available(iOS 16.0, *)
private struct CircularPrayerView: View {
    let now: Date
    let snapshot: PrayerSnapshot
    let resolution: PrayerSnapshot.Resolution

    var body: some View {
        let name = snapshot.labels.prayer(resolution.next.k)
        Gauge(value: resolution.progress(at: now)) {
            Text(name)
        } currentValueLabel: {
            VStack(spacing: 0) {
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
                Text(resolution.next.t)
                    .font(.system(size: 13, weight: .bold))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }
}

/// Before the app has published prayer times, or once they have run out.
@available(iOS 16.0, *)
private struct LockScreenEmptyView: View {
    let snapshot: PrayerSnapshot?
    let family: WidgetFamily

    var body: some View {
        let text = snapshot?.labels.empty.isEmpty == false
            ? (snapshot?.labels.empty ?? "")
            : "افتح التطبيق لتحديد مواقيت الصلاة"
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
            }
        case .accessoryInline:
            Text(text)
        default:
            Text(text)
                .font(.caption)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension View {
    /// iOS 17 requires every widget to declare a container background; a
    /// Lock Screen widget's is clear, the wallpaper showing through.
    @ViewBuilder
    func clearWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color.clear }
        } else {
            self
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, *)
struct PrayerLockScreen_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        let entry = PrayerEntry.at(now, snapshot: PrayerSnapshot.sample(now: now))
        Group {
            LockScreenPrayerView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            LockScreenPrayerView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            LockScreenPrayerView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }
}
