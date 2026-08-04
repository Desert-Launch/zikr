import Foundation
import UserNotifications

/// Pre-iOS-26 "unmissable" path: a critical alert.
///
/// `interruptionLevel = .critical` is the only supported way for a third-party
/// app to pierce **Silent mode and every Focus mode**, and it plays at a volume
/// the app chooses rather than the ringer's. That makes it the closest thing to
/// an alarm available before AlarmKit existed.
///
/// # Two hard limits, both Apple-imposed
///
///  1. **Entitlement required.** `com.apple.developer.usernotifications.critical-alerts`
///     is not self-service — it must be requested from Apple and approved per
///     App ID. Until it is granted, `requestAuthorization` with `.criticalAlert`
///     silently returns `false` for that option and the notification is
///     delivered as a normal (Silent-mode-respecting) alert. The justification
///     text to submit is in `docs/ios_critical_alerts_justification.md`.
///
///  2. **~30 second sound cap.** iOS truncates any notification sound longer
///     than 30 seconds. The bundled `.caf` files are therefore the SHORT adhan
///     clips, not the full multi-minute recording. There is no way around this
///     on the notification path — the full adhan on iOS only plays when the app
///     is foregrounded (handled in Dart by `CBAdhanPlayer`) or, on iOS 26+,
///     through AlarmKit.
///
/// Every method fails soft — the caller falls back to Dart's own scheduled
/// notification rather than leaving the user with silence.
final class AdhanCriticalFallback {

    private let center = UNUserNotificationCenter.current()

    /// Category carrying the Stop / Open actions. Registered lazily on first
    /// schedule so a user who never enables the adhan doesn't pay for it.
    private static let categoryIdentifier = "ADHAN_ALARM"
    private var categoryRegistered = false

    func schedule(_ request: AdhanAlarmRequest, completion: @escaping (Bool) -> Void) {
        registerCategoryIfNeeded(stopLabel: request.stopLabel, openLabel: request.openLabel)

        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["type": "adhan", "prayer": request.prayerKey]

        // .critical is the whole point of this path; iOS quietly downgrades it
        // to .timeSensitive when the entitlement isn't provisioned, so there's
        // no need to branch on that here. The property itself is iOS 15+; on
        // iOS 14 the critical SOUND below still plays at full volume, which is
        // most of the benefit.
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .critical
            content.relevanceScore = 1.0
        }

        if request.soundName.isEmpty {
            content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        } else {
            // Full volume regardless of the ringer position — an adhan the user
            // opted into per prayer should not be missed because the phone was
            // on silent.
            content.sound = UNNotificationSound.criticalSoundNamed(
                UNNotificationSoundName(request.soundFileName),
                withAudioVolume: 1.0,
            )
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: request.fireDate,
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        center.add(
            UNNotificationRequest(
                identifier: request.requestIdentifier,
                content: content,
                trigger: trigger,
            ),
        ) { error in
            DispatchQueue.main.async { completion(error == nil) }
        }
    }

    func cancel(id: Int) {
        let identifier = "adhan_alarm_\(id)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    /// Removes every pending adhan alarm, leaving other features' notifications
    /// (reminders, azkar, hourly zekr) untouched.
    func cancelAll() {
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("adhan_alarm_") }
            guard !ids.isEmpty else { return }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// True only when the critical-alert entitlement is provisioned AND the user
    /// granted it. A plain notification grant is not enough — that path can't
    /// break Silent mode, so reporting it as authorized would overstate what the
    /// app can actually deliver.
    func isAuthorized(_ completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            let granted = settings.criticalAlertSetting == .enabled
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { _, _ in
            // The `granted` flag reflects the whole request, not the critical
            // option specifically — re-read the settings for the truth.
            self.isAuthorized(completion)
        }
    }

    private func registerCategoryIfNeeded(stopLabel: String, openLabel: String) {
        guard !categoryRegistered else { return }
        categoryRegistered = true

        let stop = UNNotificationAction(
            identifier: "ADHAN_STOP",
            title: stopLabel,
            options: [],
        )
        let open = UNNotificationAction(
            identifier: "ADHAN_OPEN",
            title: openLabel,
            options: [.foreground],
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [stop, open],
            intentIdentifiers: [],
            options: [],
        )
        // Merge rather than replace — flutter_local_notifications registers its
        // own categories and overwriting them would break other features' taps.
        center.getNotificationCategories { existing in
            var merged = existing.filter { $0.identifier != Self.categoryIdentifier }
            merged.insert(category)
            self.center.setNotificationCategories(merged)
        }
    }
}
