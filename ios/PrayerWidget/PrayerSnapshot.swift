import Foundation

/// The `prayer_widget_v1` snapshot the app publishes through `home_widget`,
/// and the clock arithmetic the widget does over it.
///
/// The extension runs with no Flutter engine, so everything it prints has to
/// be in here already: every timing is an epoch instant paired with the
/// string the app would show for it, every label is pre-localised, and the
/// Hijri and Gregorian dates are pre-formatted per day. What is left is to
/// pick rows against the clock — which salah is next, which window we are in,
/// whether the chip row should have rolled into tomorrow — using the same
/// rules as the app's `UCGetNextPrayer` / `SPrayerTimes` and the Android
/// `PrayerWidgetSnapshot`, so no two surfaces ever disagree.
///
/// Shape: `docs/plans/Prayer_Home_Widget_Plan.md` §3; producer:
/// `lib/modules/prayer/data/models/m_prayer_widget_snapshot.dart`.
struct PrayerSnapshot: Decodable {

    struct Slot: Decodable {
        let k: String
        let at: Int64
        let t: String

        /// Sunrise is listed but is not a salah: never "next", never a window start.
        var isSalah: Bool { k != "sunrise" }
        var date: Date { Date(timeIntervalSince1970: TimeInterval(at) / 1000) }
    }

    struct Day: Decodable {
        let date: String
        let gregorian: String
        let hijri: String
        let slots: [Slot]
    }

    struct Labels: Decodable {
        let caption: String
        let nextName: String
        let after: String?
        let remainingHm: String
        let remaining1Hm: String?
        let remainingM: String
        let tomorrow: String
        let empty: String
        let prayers: [String: String]

        func prayer(_ key: String) -> String { prayers[key] ?? key }
    }

    /// What the widget shows for one instant.
    struct Resolution {
        /// Today in the location's zone.
        let today: Day
        /// Today until its last salah has gone, then tomorrow.
        let displayDay: Day
        let next: Slot
        /// The salah whose window we are inside; nil only before the earliest one known.
        let windowStart: Date?
        /// `displayDay`'s six slots, `next` included — the row under the bar.
        let chips: [Slot]

        var isShowingTomorrow: Bool { displayDay.date != today.date }

        /// Fraction of the current window elapsed at `now`, 0…1.
        func progress(at now: Date) -> Double {
            guard let start = windowStart else { return 0 }
            let total = next.date.timeIntervalSince(start)
            guard total > 0 else { return 0 }
            return min(max(now.timeIntervalSince(start) / total, 0), 1)
        }

        /// `بعد ساعة و 15 دقيقة` — minutes rounded up, so the last minute reads "1", not "0".
        func remaining(at now: Date, labels: Labels) -> String {
            let seconds = max(next.date.timeIntervalSince(now), 0)
            let minutes = Int((seconds + 59) / 60)
            let h = minutes / 60
            let m = minutes % 60
            if h <= 0 {
                return labels.remainingM.replacingOccurrences(of: "{{m}}", with: String(m))
            }
            if h == 1 {
                let template = labels.remaining1Hm ?? labels.remainingHm.replacingOccurrences(of: "{{h}}", with: "1")
                return template.replacingOccurrences(of: "{{m}}", with: String(m))
            }
            return labels.remainingHm
                .replacingOccurrences(of: "{{h}}", with: String(h))
                .replacingOccurrences(of: "{{m}}", with: String(m))
        }
    }

    static let version = 1
    static let storageKey = "prayer_widget_v1"

    /// Shared container the app writes into. Must match `Runner.entitlements`,
    /// `PrayerWidget.entitlements` and `DSPrayerWidget.appGroupId` in Dart.
    static let appGroup = "group.com.zikr.mapp"

    let v: Int
    let lang: String
    let rtl: Bool
    let tz: String
    let city: String
    let generatedAt: Int64
    let labels: Labels
    let days: [Day]

    var timeZone: TimeZone { TimeZone(identifier: tz) ?? .current }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    // MARK: Loading

    static func load() -> PrayerSnapshot? {
        guard let raw = UserDefaults(suiteName: appGroup)?.string(forKey: storageKey) else { return nil }
        return parse(raw)
    }

    /// Nil for a missing, malformed or newer-versioned snapshot — never throws.
    static func parse(_ raw: String) -> PrayerSnapshot? {
        guard let data = raw.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode(PrayerSnapshot.self, from: data),
              snapshot.v == version
        else { return nil }
        return snapshot
    }

    // MARK: Resolution

    /// Resolves the widget's content for `now`, or nil when the snapshot has
    /// nothing usable — no row for today, or every known salah has passed —
    /// in which case the widget shows its empty state rather than a stale one.
    func resolve(at now: Date) -> Resolution? {
        guard let todayIndex = todayIndex(at: now) else { return nil }
        let today = days[todayIndex]
        let nowMillis = Int64(now.timeIntervalSince1970 * 1000)

        var next: Slot?
        var windowStart: Slot?
        outer: for day in days {
            for slot in day.slots where slot.isSalah {
                if slot.at > nowMillis {
                    next = slot
                    break outer
                }
                windowStart = slot
            }
        }
        guard let resolvedNext = next else { return nil }

        let hasSalahLeft = today.slots.contains { $0.isSalah && $0.at > nowMillis }
        let displayDay = hasSalahLeft ? today : (days.indices.contains(todayIndex + 1) ? days[todayIndex + 1] : today)

        return Resolution(
            today: today,
            displayDay: displayDay,
            next: resolvedNext,
            windowStart: windowStart?.date,
            chips: displayDay.slots
        )
    }

    /// The calendar day of `now` **in the location's zone**, if the snapshot has it.
    func todayIndex(at now: Date) -> Int? {
        let key = Self.isoDate(now, in: calendar)
        return days.firstIndex { $0.date == key }
    }

    /// The next local midnight after `now` — when the date row changes.
    func nextMidnight(after now: Date) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86_400)
    }

    /// Every salah instant strictly after `now`, in order.
    func salahDates(after now: Date) -> [Date] {
        days.flatMap { $0.slots }.filter { $0.isSalah && $0.date > now }.map(\.date)
    }

    private static func isoDate(_ date: Date, in calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

// MARK: - Sample data (widget gallery + placeholder)

extension PrayerSnapshot {

    /// A Doha day with the mock's numbers, laid over today so the gallery
    /// preview looks alive rather than dated. Arabic, because the app is.
    static func sample(now: Date = Date()) -> PrayerSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let startOfToday = calendar.startOfDay(for: now)

        func day(offset: Int) -> Day {
            let base = calendar.date(byAdding: .day, value: offset, to: startOfToday) ?? startOfToday
            func slot(_ key: String, _ hour: Int, _ minute: Int, _ label: String) -> Slot {
                let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
                return Slot(k: key, at: Int64(date.timeIntervalSince1970 * 1000), t: label)
            }
            let c = calendar.dateComponents([.year, .month, .day], from: base)
            return Day(
                date: String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0),
                gregorian: "السبت، 29 أغسطس 2026",
                hijri: "15 ربيع الأول 1448 هـ",
                slots: [
                    slot("fajr", 5, 15, "5:15"),
                    slot("sunrise", 6, 45, "6:45"),
                    slot("dhuhr", 12, 30, "12:30"),
                    slot("asr", 15, 45, "3:45"),
                    slot("maghrib", 18, 15, "6:15"),
                    slot("isha", 19, 45, "7:45"),
                ]
            )
        }

        return PrayerSnapshot(
            v: version,
            lang: "ar",
            rtl: true,
            tz: TimeZone.current.identifier,
            city: "الدوحة",
            generatedAt: Int64(now.timeIntervalSince1970 * 1000),
            labels: Labels(
                caption: "الصلاة القادمة بتوقيت الدوحة",
                nextName: "صلاة {{name}}",
                after: "بعد",
                remainingHm: "بعد {{h}} ساعة و {{m}} دقيقة",
                remaining1Hm: "بعد ساعة و {{m}} دقيقة",
                remainingM: "بعد {{m}} دقيقة",
                tomorrow: "الغد",
                empty: "افتح التطبيق لتحديد مواقيت الصلاة",
                prayers: [
                    "fajr": "الفجر",
                    "sunrise": "الشروق",
                    "dhuhr": "الظهر",
                    "asr": "العصر",
                    "maghrib": "المغرب",
                    "isha": "العشاء",
                ]
            ),
            days: [day(offset: -1), day(offset: 0), day(offset: 1)]
        )
    }
}
