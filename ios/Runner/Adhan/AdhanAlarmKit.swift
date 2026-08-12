import Foundation

#if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT

import ActivityKit
import AlarmKit
import SwiftUI

/// iOS 26+ primary path: a real system alarm via AlarmKit.
///
/// This is as close as iOS gets to the Android full-screen alarm. AlarmKit
/// alarms are the same class of object the built-in Clock app schedules, so they:
///   * break Silent mode and every Focus mode without a special entitlement;
///   * present Apple's own alarm UI on the Lock Screen with a Stop button;
///   * play at alarm volume rather than notification volume;
///   * fire with the app fully terminated.
///
/// What it still cannot do is present *our* UI — the alert is Apple's, styled by
/// the tint colour and the button labels we supply. See `AdhanAlarmChannel` for
/// why a custom full-screen at fire time is impossible on iOS.
///
/// ## Requirements
///   * Xcode 26 / iOS 26 SDK (guarded by `canImport(AlarmKit)` — on an older
///     toolchain this whole file compiles to nothing and the critical-alert
///     fallback handles every version).
///   * `NSAlarmKitUsageDescription` in `Info.plist`.
///   * User authorization, requested through `requestAuthorization()`.
///
/// ## Kill switch
/// If this file fails to build against a future AlarmKit revision, add
/// `-D ADHAN_DISABLE_ALARMKIT` to *Other Swift Flags* for the Runner target.
/// The app then falls back to `AdhanCriticalFallback` on every iOS version —
/// degraded, but fully functional.
///
/// Every entry point fails soft and returns `false`, which tells Dart to keep
/// its own notification so a failure here never means silence at prayer time.
@available(iOS 26.0, *)
final class AdhanAlarmKit {

    static let shared = AdhanAlarmKit()

    private init() {}

    /// Alarms armed in this process, so [cancelAll] can tear down exactly what
    /// we scheduled. Rebuilt on every reschedule (Dart cancels before it
    /// re-arms), and AlarmKit itself drops alarms once they fire.
    private var armed = Set<UUID>()

    // MARK: - Authorization

    func isAuthorized() async -> Bool {
        AlarmManager.shared.authorizationState == .authorized
    }

    /// Prompts for alarm authorization if it hasn't been decided yet. Returns
    /// the resulting state; a denial is final until the user changes it in
    /// Settings (reachable via the channel's `openOsSettings`).
    func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        default:
            do {
                let state = try await manager.requestAuthorization()
                return state == .authorized
            } catch {
                return false
            }
        }
    }

    // MARK: - Scheduling

    func schedule(_ request: AdhanAlarmRequest) async -> Bool {
        guard await requestAuthorization() else { return false }

        let stopButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: request.stopLabel),
            textColor: .white,
            systemImageName: "stop.circle",
        )

        // Deliberately no secondary ("Open app") button. AlarmKit routes the
        // secondary action through a `LiveActivityIntent`, which requires a
        // Widget Extension target that this app doesn't have — declaring
        // `.custom` without one gives a button that does nothing. The Android
        // alarm keeps both actions; iOS gets Stop only, which is also what the
        // system Clock app offers.
        //
        // `init(title:stopButton:...)` is deprecated in 26.1 in favour of a
        // variant that drops stopButton entirely, but that one is 26.1+ only.
        // Using it here would leave iOS 26.0 unbuildable, so we take the
        // deprecation warning until the deployment floor moves past 26.1.
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: request.title),
            stopButton: stopButton,
        )

        let attributes = AlarmAttributes<AdhanAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: AdhanAlarmMetadata(prayerKey: request.prayerKey),
            // Matches AppColorsLight.primary (#0E6B47) so the system alarm reads
            // as part of the app.
            tintColor: Color(red: 0.055, green: 0.42, blue: 0.278),
        )

        let configuration = AlarmManager.AlarmConfiguration<AdhanAlarmMetadata>.alarm(
            schedule: .fixed(request.fireDate),
            attributes: attributes,
            sound: alertSound(for: request),
        )

        do {
            let id = request.alarmUUID
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            armed.insert(id)
            return true
        } catch {
            return false
        }
    }

    /// The bundled short adhan `.caf`. AlarmKit, like the notification path,
    /// won't play a multi-minute recording, so this is the same clip the
    /// critical-alert fallback uses — not the full adhan.
    private func alertSound(for request: AdhanAlarmRequest) -> AlertConfiguration.AlertSound {
        request.soundName.isEmpty ? .default : .named(request.soundFileName)
    }

    // MARK: - Cancellation

    func cancel(id: Int) {
        let uuid = AdhanAlarmRequest.alarmUUID(for: id)
        try? AlarmManager.shared.cancel(id: uuid)
        armed.remove(uuid)
    }

    /// Cancels everything armed here except [except] — see the Android
    /// `AdhanAlarmScheduler.cancelAll` for why the exception exists.
    func cancelAll(except: Set<Int> = []) {
        let spared = Set(except.map(AdhanAlarmRequest.alarmUUID(for:)))
        for id in armed where !spared.contains(id) {
            try? AlarmManager.shared.cancel(id: id)
        }
        armed.formIntersection(spared)
    }
}

/// Payload carried on the alarm so a Stop/Open tap can be attributed to the
/// right prayer. AlarmKit requires the metadata type to be `AlarmMetadata`
/// (Codable + Hashable + Sendable).
@available(iOS 26.0, *)
struct AdhanAlarmMetadata: AlarmMetadata {
    let prayerKey: String

    init(prayerKey: String = "") {
        self.prayerKey = prayerKey
    }
}

#endif
