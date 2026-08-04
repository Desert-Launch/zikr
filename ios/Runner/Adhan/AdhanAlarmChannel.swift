import Flutter
import Foundation
import UIKit

/// iOS side of the `com.zikr.mapp/adhan_alarm` method channel.
///
/// # The iOS ceiling — read this before trying to "fix" it
///
/// On Android this channel drives a real full-screen Activity that appears over
/// the lockscreen from a killed app. **iOS cannot do that, by design.** There is
/// no API — public or private — that lets a third-party app present its own UI
/// at a scheduled time while the app is not running. Apps that appear to do it
/// (alarm clocks, prayer apps) are either playing silent audio to stay alive
/// (battery-hostile, and rejected by review when it's the only justification) or
/// using one of the two supported paths below.
///
/// Do not spend time looking for a way to show a custom Flutter screen at fire
/// time from a terminated app. It does not exist. The two supported paths are:
///
///  1. **AlarmKit (iOS 26+)** — `AdhanAlarmKit`. A real system alarm: breaks
///     Silent mode and Focus, shows Apple's own alarm UI on the Lock Screen with
///     a Stop button, plays at alarm volume. This is Clock-app parity and the
///     closest iOS gets to the Android experience.
///
///  2. **Critical alerts (all versions)** — `AdhanCriticalFallback`. A
///     `UNNotificationRequest` with `interruptionLevel = .critical`, which also
///     pierces Silent/Focus and plays at a volume we choose. Requires an Apple
///     entitlement (see `docs/ios_critical_alerts_justification.md`). Sound is
///     capped at ~30s by iOS, so the bundled `.caf` is the short adhan clip, not
///     the full multi-minute recording.
///
/// Both paths fail soft: any error returns `false` to Dart, which then keeps its
/// own scheduled notification so the user is never left with silence.
final class AdhanAlarmChannel {

    static let channelName = "com.zikr.mapp/adhan_alarm"

    private let fallback = AdhanCriticalFallback()

    /// Registers the channel against [messenger]. Called from `AppDelegate`.
    static func register(with messenger: FlutterBinaryMessenger) {
        let instance = AdhanAlarmChannel()
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            instance.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "schedule":
            schedule(args, result: result)
        case "cancel":
            guard let id = args["id"] as? Int else {
                result(FlutterError(code: "bad_args", message: "id is required", details: nil))
                return
            }
            cancel(id: id, result: result)
        case "cancelAll":
            cancelAll(result: result)
        case "permissions":
            permissions(result: result)
        case "requestAuthorization":
            requestAuthorization(result: result)
        case "openOsSettings":
            openSettings(result: result)
        case "canScheduleExact":
            // No such concept on iOS — scheduling is always "exact" within the
            // limits of the delivery path.
            result(true)
        case "manufacturer":
            result("apple")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Scheduling

    private func schedule(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let id = args["id"] as? Int,
              let triggerMillis = args["triggerAtMillis"] as? NSNumber
        else {
            result(FlutterError(
                code: "bad_args",
                message: "id and triggerAtMillis are required",
                details: nil,
            ))
            return
        }

        let request = AdhanAlarmRequest(
            id: id,
            fireDate: Date(timeIntervalSince1970: triggerMillis.doubleValue / 1000.0),
            soundName: args["rawRes"] as? String ?? "",
            title: args["title"] as? String ?? "",
            body: args["body"] as? String ?? "",
            stopLabel: args["stopLabel"] as? String ?? "",
            openLabel: args["openLabel"] as? String ?? "",
            prayerKey: args["prayerKey"] as? String ?? "",
        )

        // A fire date in the past would either throw or fire immediately.
        guard request.fireDate > Date() else {
            result(false)
            return
        }

        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            Task {
                let armed = await AdhanAlarmKit.shared.schedule(request)
                if armed {
                    result(true)
                } else {
                    // AlarmKit unavailable or unauthorized — critical alert.
                    self.fallback.schedule(request) { ok in result(ok) }
                }
            }
            return
        }
        #endif

        fallback.schedule(request) { ok in result(ok) }
    }

    private func cancel(id: Int, result: @escaping FlutterResult) {
        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            AdhanAlarmKit.shared.cancel(id: id)
        }
        #endif
        fallback.cancel(id: id)
        result(true)
    }

    private func cancelAll(result: @escaping FlutterResult) {
        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            AdhanAlarmKit.shared.cancelAll()
        }
        #endif
        fallback.cancelAll()
        result(true)
    }

    // MARK: - Authorization

    /// iOS has no exact-alarm, battery-optimization or OEM-autostart concept, so
    /// those three always report "fine". Only the alert authorization is real,
    /// and it maps onto `canUseFullScreenIntent` — the flag Dart uses to decide
    /// whether the unmissable path is actually available.
    private func permissions(result: @escaping FlutterResult) {
        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            Task {
                let authorized = await AdhanAlarmKit.shared.isAuthorized()
                result(self.permissionMap(authorized: authorized))
            }
            return
        }
        #endif

        fallback.isAuthorized { authorized in
            result(self.permissionMap(authorized: authorized))
        }
    }

    private func permissionMap(authorized: Bool) -> [String: Any] {
        [
            "canScheduleExact": true,
            "canUseFullScreenIntent": authorized,
            "isBatteryOptimized": false,
            "hasOemAutostartManager": false,
        ]
    }

    private func requestAuthorization(result: @escaping FlutterResult) {
        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            Task {
                let granted = await AdhanAlarmKit.shared.requestAuthorization()
                if granted {
                    result(true)
                } else {
                    // Fall back to asking for critical-alert authorization, which
                    // is a separate prompt and may still be granted.
                    self.fallback.requestAuthorization { ok in result(ok) }
                }
            }
            return
        }
        #endif

        fallback.requestAuthorization { ok in result(ok) }
    }

    /// iOS exposes only one settings destination per app, so every
    /// `AdhanOsSetting` value lands on the same page.
    private func openSettings(result: @escaping FlutterResult) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            result(false)
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
        }
    }
}
