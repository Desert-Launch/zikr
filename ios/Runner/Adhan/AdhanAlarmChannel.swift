import Flutter
import Foundation
import UIKit

/// iOS side of the `com.zikr.mapp/adhan_alarm` method channel.
///
/// # This channel no longer arms alarms on iOS
///
/// The adhan on iOS is a **plain scheduled notification**, posted by Dart
/// through `flutter_local_notifications` with the bundled short `.caf`. Neither
/// AlarmKit nor the critical-alert path is used, and nothing here ever prompts
/// for alarm authorization:
///
///   * `schedule` returns `false` immediately, which is Dart's documented
///     signal (`AdhanAudioAlarms.schedule`) to keep its own notification.
///   * `requestAuthorization` returns `false` without showing a prompt.
///   * `permissions` answers from a constant — no probing, no dialogs.
///
/// `cancel` / `cancelAll` stay fully wired, and [purgeLegacyAlarms] runs once
/// per launch, so alarms armed by an EARLIER build of the app are torn down
/// instead of firing forever. Do not make those no-ops.
///
/// `AdhanAlarmKit` and `AdhanCriticalFallback` are kept in the target rather
/// than deleted: they are the working implementations of the two supported
/// paths, and the notes below are why they are shaped the way they are. To turn
/// the alarm path back on, restore the AlarmKit/fallback calls in [schedule],
/// [requestAuthorization] and [permissions], and flip `AdhanScheduler` back to
/// arming iOS alarms. `NSAlarmKitUsageDescription` is still in `Info.plist`, so
/// nothing else is needed.
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
        instance.purgeLegacyAlarms()
    }

    /// Tears down anything a PREVIOUS build armed natively.
    ///
    /// Alarms outlive app updates: an AlarmKit alarm and a pending
    /// `UNNotificationRequest` both survive in the system, so a user upgrading
    /// from a build that armed them would keep getting the old alert alongside
    /// the notification Dart now schedules — a double adhan, and one of them
    /// unstoppable from the app.
    ///
    /// Dart's `cancelAll` covers the rolling window, but deliberately spares the
    /// one-shot test id, and it only runs when a reschedule happens. Sweeping
    /// unconditionally at launch is what guarantees nothing is left behind.
    /// Cheap once the purge has nothing to find, which is the steady state.
    private func purgeLegacyAlarms() {
        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            AdhanAlarmKit.shared.purgeAll()
        }
        #endif
        fallback.cancelAll()
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
            cancelAll(except: Set(args["exceptIds"] as? [Int] ?? []), result: result)
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

    /// Always declines. Returning `false` is not an error path — it is the
    /// contract `AdhanAudioAlarms.schedule` documents for "not armed
    /// natively", and Dart responds by scheduling its own notification for this
    /// prayer. Arming nothing here is what keeps iOS on the notification path
    /// and keeps the alarm authorization prompt from ever appearing.
    private func schedule(_ args: [String: Any], result: @escaping FlutterResult) {
        result(false)
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

    private func cancelAll(except: Set<Int>, result: @escaping FlutterResult) {
        #if canImport(AlarmKit) && !ADHAN_DISABLE_ALARMKIT
        if #available(iOS 26.0, *) {
            AdhanAlarmKit.shared.cancelAll(except: except)
        }
        #endif
        fallback.cancelAll(except: except)
        result(true)
    }

    // MARK: - Authorization

    /// Reports "nothing is blocking the adhan", unconditionally.
    ///
    /// Three of these four flags describe Android concepts iOS doesn't have
    /// (exact alarms, battery optimization, OEM autostart). The fourth,
    /// `canUseFullScreenIntent`, used to carry the real alarm/critical-alert
    /// authorization — but with no alarm being armed there is no such grant to
    /// report, and answering `false` would make the app warn about a permission
    /// that no longer affects anything.
    private func permissions(result: @escaping FlutterResult) {
        // Every flag is "nothing is blocking us", because nothing here can be
        // blocked any more: no alarm is armed, so there is no alarm grant to
        // report. Dart renders no permission rows on iOS (`alarmPermissionInfos`
        // returns an empty list off Android), so this only has to avoid
        // reporting a false problem.
        result([
            "canScheduleExact": true,
            "canUseFullScreenIntent": true,
            "isBatteryOptimized": false,
            "hasOemAutostartManager": false,
        ])
    }

    /// Declines without prompting. The only authorization the adhan needs on
    /// iOS is the ordinary alert/sound/badge grant, which
    /// `NotificationsService.requestPermission` already asks for through
    /// `flutter_local_notifications`. Asking for AlarmKit or `.criticalAlert`
    /// here would put a second, unexplained system dialog in front of the user
    /// for a delivery path the app does not use.
    private func requestAuthorization(result: @escaping FlutterResult) {
        result(false)
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
