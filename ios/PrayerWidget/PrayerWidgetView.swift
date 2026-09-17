import SwiftUI
import WidgetKit

// MARK: - Palette (asset catalog colours, light + dark)

private enum Palette {
    static let card = Color("WidgetBackground")
    static let ink = Color("WidgetTextPrimary")
    static let muted = Color("WidgetTextSecondary")
    static let track = Color("WidgetTrack")
    static let green = Color("WidgetGreen")
    static let gold = Color("WidgetGold")

    /// Chip disc colours, keyed by slot — the same six as the in-app card.
    static func chip(_ key: String) -> Color {
        switch key {
        case "fajr": return Color(red: 0.886, green: 0.439, blue: 0.357)     // E2705B
        case "sunrise": return Color(red: 0.949, green: 0.639, blue: 0.235)  // F2A33C
        case "dhuhr": return Color(red: 0.949, green: 0.753, blue: 0.216)    // F2C037
        case "asr": return Color(red: 0.247, green: 0.663, blue: 0.769)      // 3FA9C4
        case "maghrib": return Color(red: 0.910, green: 0.455, blue: 0.231)  // E8743B
        case "isha": return Color(red: 0.424, green: 0.388, blue: 0.710)     // 6C63B5
        default: return Color.gray
        }
    }

    static func emoji(_ key: String) -> String {
        switch key {
        case "fajr": return "🌅"
        case "sunrise": return "☀️"
        case "dhuhr": return "🌤️"
        case "asr": return "🌥️"
        case "maghrib": return "🌇"
        case "isha": return "🌙"
        default: return ""
        }
    }
}

/// Where a tap goes. The `homeWidget` query flag is what the plugin keys on
/// to recognise the URL as its own in `application(_:open:options:)`.
private let launchURL = URL(string: "zikr://prayer?homeWidget")

// MARK: - Root

/// Picks the layout for the family and wraps it in the card, the layout
/// direction the app's language wants, and the tap target.
struct PrayerWidgetView: View {
    let entry: PrayerEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.layoutDirection, (entry.snapshot?.rtl ?? true) ? .rightToLeft : .leftToRight)
            .widgetURL(launchURL)
            .cardBackground(Palette.card)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot, let resolution = entry.resolution {
            switch family {
            case .systemSmall:
                SmallPrayerView(now: entry.date, snapshot: snapshot, resolution: resolution)
            default:
                MediumPrayerView(now: entry.date, snapshot: snapshot, resolution: resolution)
            }
        } else {
            EmptyPrayerView(snapshot: entry.snapshot, compact: family == .systemSmall)
        }
    }
}

private extension View {
    /// iOS 17 wants the widget's background declared as a container
    /// background (it is what StandBy and the Lock Screen strip away); older
    /// versions just paint it.
    @ViewBuilder
    func cardBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }
}

// MARK: - Medium (the mock)

private struct MediumPrayerView: View {
    let now: Date
    let snapshot: PrayerSnapshot
    let resolution: PrayerSnapshot.Resolution

    var body: some View {
        let labels = snapshot.labels
        VStack(alignment: .leading, spacing: 8) {
            // Date row — today's, even while the chip row shows tomorrow.
            HStack(spacing: 8) {
                Text(resolution.today.gregorian)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(resolution.today.hijri)
                    .lineLimit(1)
            }
            .font(.system(size: 11))
            .foregroundColor(Palette.muted)

            // Head row.
            HStack(alignment: .center, spacing: 10) {
                Emblem(size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(resolution.isShowingTomorrow ? "\(labels.caption) · \(labels.tomorrow)" : labels.caption)
                        .font(.system(size: 11))
                        .foregroundColor(Palette.muted)
                        .lineLimit(1)
                    Text(labels.nextName.replacingOccurrences(of: "{{name}}", with: labels.prayer(resolution.next.k)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(resolution.next.t)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Palette.green)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Circle().fill(Palette.green).frame(width: 6, height: 6)
                        Text(resolution.remaining(at: now, labels: labels))
                            .font(.system(size: 10))
                            .foregroundColor(Palette.muted)
                            .lineLimit(1)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            ProgressTrack(fraction: resolution.progress(at: now))
                .frame(height: 6)
                .padding(.top, 2)

            // The day's six slots, the featured prayer included.
            HStack(spacing: 0) {
                ForEach(resolution.chips, id: \.k) { slot in
                    ChipView(slot: slot, label: labels.prayer(slot.k))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Small

/// Next prayer, its time and the countdown — the medium card without the
/// date row and chips, for a 2×2 cell.
private struct SmallPrayerView: View {
    let now: Date
    let snapshot: PrayerSnapshot
    let resolution: PrayerSnapshot.Resolution

    var body: some View {
        let labels = snapshot.labels
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Emblem(size: 30)
                Text(resolution.today.hijri)
                    .font(.system(size: 10))
                    .foregroundColor(Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            Text(labels.nextName.replacingOccurrences(of: "{{name}}", with: labels.prayer(resolution.next.k)))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(resolution.next.t)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Palette.green)
                .lineLimit(1)
            HStack(spacing: 5) {
                Circle().fill(Palette.green).frame(width: 6, height: 6)
                Text(resolution.remaining(at: now, labels: labels))
                    .font(.system(size: 10))
                    .foregroundColor(Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            ProgressTrack(fraction: resolution.progress(at: now))
                .frame(height: 5)
        }
    }
}

// MARK: - Empty

/// Before the app has ever resolved prayer times, or once a snapshot has run
/// past its window: emblem plus a one-line invitation.
private struct EmptyPrayerView: View {
    let snapshot: PrayerSnapshot?
    let compact: Bool

    var body: some View {
        let text = snapshot?.labels.empty.isEmpty == false
            ? (snapshot?.labels.empty ?? "")
            : "افتح التطبيق لتحديد مواقيت الصلاة"
        if compact {
            VStack(alignment: .leading, spacing: 8) {
                Emblem(size: 36)
                Spacer(minLength: 0)
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
        } else {
            HStack(spacing: 12) {
                Emblem(size: 44)
                Text(text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Pieces

/// The launcher artwork clipped to a circle inside a thin gold ring.
private struct Emblem: View {
    let size: CGFloat

    var body: some View {
        Image("WidgetLogo")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size - 4, height: size - 4)
            .clipShape(Circle())
            .padding(2)
            .overlay(Circle().strokeBorder(Palette.gold, lineWidth: 1.5))
            .frame(width: size, height: size)
    }
}

/// Window progress: a hairline track with a green→gold fill growing from the
/// leading edge — which is the right edge under an Arabic snapshot, because
/// the whole card runs right-to-left.
private struct ProgressTrack: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.track)
                Capsule()
                    .fill(LinearGradient(colors: [Palette.green, Palette.gold], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(geometry.size.width * CGFloat(fraction), fraction > 0 ? 6 : 0))
            }
        }
    }
}

private struct ChipView: View {
    let slot: PrayerSnapshot.Slot
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().fill(Palette.chip(slot.k).opacity(0.16))
                Text(Palette.emoji(slot.k)).font(.system(size: 16))
            }
            .frame(width: 34, height: 34)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(slot.t)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
        }
    }
}

// MARK: - Previews

struct PrayerWidget_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        let sample = PrayerSnapshot.sample(now: now)
        Group {
            PrayerWidgetView(entry: PrayerEntry.at(now, snapshot: sample))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            PrayerWidgetView(entry: PrayerEntry.at(now, snapshot: sample))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            PrayerWidgetView(entry: PrayerEntry(date: now, snapshot: nil, resolution: nil))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
