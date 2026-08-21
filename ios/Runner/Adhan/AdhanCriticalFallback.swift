import Foundation
import UserNotifications

/// Pre-iOS-26 "unmissable" path: a critical alert.
///
/// `interruptionLevel = .critical` is the only supported way for a third-party
/// app to pierce **Silent mode and every Focus mode**, and it plays at a volume
/// the app chooses rather than the ringer's. That makes it the closest thing to
/// an alarm available before AlarmKit existed.
///
/// # Three hard limits
///
///  1. **Entitlement required.** `com.apple.developer.usernotifications.critical-alerts`
///     is not self-service — it must be requested from Apple and approved per
///     App ID. Until it is granted, `requestAuthorization` with `.criticalAlert`
///     silently returns `false` for that option and the notification is
///     delivered as a normal (Silent-mode-respecting) alert. The justification
///     text to submit is in `docs/ios_critical_alerts_justification.md`.
///
///     Because of that, the critical sound and interruption level are requested
///     ONLY when [criticalPathAvailable] says so — asking unconditionally
///     crashes SpringBoard on the simulator. Read that method before touching
///     [add] or [sound].
///
///  2. **~30 second sound cap.** iOS truncates any notification sound longer
///     than 30 seconds. The bundled `.caf` files are therefore the SHORT adhan
///     clips, not the full multi-minute recording. There is no way around this
///     on the notification path — the full adhan on iOS only plays when the app
///     is foregrounded (handled in Dart by `CBAdhanPlayer`) or, on iOS 26+,
///     through AlarmKit.
///
///  3. **No critical alerts on the simulator.** See [criticalPathAvailable].
///     The adhan is still delivered there, just as an ordinary alert.
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

        criticalPathAvailable { critical in
            self.add(request, critical: critical, completion: completion)
        }
    }

    /// Whether this build may actually ask for the critical-alert audio path.
    ///
    /// **Never request a critical sound without checking this.** Two gates, and
    /// both are load-bearing:
    ///
    ///  1. **Simulator.** The simulator does not enforce entitlements, so it
    ///     accepts a critical alert and then takes the whole simulated device
    ///     down when the alert fires: SpringBoard aborts inside
    ///     `-[TLAlertQueuePlayerController _prepareAudioEnvironmentForStateDescriptor:isForMusicPlayback:]`
    ///     with `doesNotRecognizeSelector:` — the simulated audio route has no
    ///     critical-alert environment to prepare. That is a SpringBoard crash,
    ///     not an app crash, which is why it shows up as a black screen /
    ///     relaunching Home screen rather than a Flutter error.
    ///
    ///  2. **Device.** `criticalAlertSetting` is `.enabled` only when the
    ///     entitlement is provisioned AND the user granted it. Until Apple
    ///     approves the request (see the entitlements file) the answer is `no`,
    ///     and asking anyway buys nothing — the notification is delivered
    ///     either way, just without piercing Silent mode.
    private func criticalPathAvailable(_ completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        completion(false)
        #else
        center.getNotificationSettings { settings in
            completion(settings.criticalAlertSetting == .enabled)
        }
        #endif
    }

    private func add(
        _ request: AdhanAlarmRequest,
        critical: Bool,
        completion: @escaping (Bool) -> Void,
    ) {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["type": "adhan", "prayer": request.prayerKey]

        // .critical is the whole point of this path, but only when it is really
        // available. `.timeSensitive` is the honest second best: it still breaks
        // through most Focus modes, it just respects the ringer switch.
        if #available(iOS 15.0, *) {
            content.interruptionLevel = critical ? .critical : .timeSensitive
            content.relevanceScore = 1.0
        }
        content.sound = sound(for: request, critical: critical)

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

    /// The bundled clip, played at full volume when the critical path is open —
    /// an adhan the user opted into per prayer should not be missed because the
    /// phone was on silent — and at ringer volume otherwise.
    private func sound(for request: AdhanAlarmRequest, critical: Bool) -> UNNotificationSound {
        guard !request.soundName.isEmpty else {
            return critical ? .defaultCriticalSound(withAudioVolume: 1.0) : .default
        }
        let name = UNNotificationSoundName(request.soundFileName)
        return critical
            ? UNNotificationSound.criticalSoundNamed(name, withAudioVolume: 1.0)
            : UNNotificationSound(named: name)
    }

    func cancel(id: Int) {
        let identifier = AdhanAlarmRequest.requestIdentifier(for: id)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    /// Removes every pending adhan alarm apart from [except], leaving other
    /// features' notifications (reminders, azkar, hourly zekr) untouched. See
    /// the Android `AdhanAlarmScheduler.cancelAll` for why the exception exists.
    func cancelAll(except: Set<Int> = []) {
        let spared = Set(except.map(AdhanAlarmRequest.requestIdentifier(for:)))
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("adhan_alarm_") && !spared.contains($0) }
            guard !ids.isEmpty else { return }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// True only when the critical-alert entitlement is provisioned AND the user
    /// granted it. A plain notification grant is not enough — that path can't
    /// break Silent mode, so reporting it as authorized would overstate what the
    /// app can actually deliver.
    func isAuthorized(_ completion: @escaping (Bool) -> Void) {
        criticalPathAvailable { granted in
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
