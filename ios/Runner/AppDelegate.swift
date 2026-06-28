import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by flutter_local_notifications so the background isolate can
    // register plugins, and so foreground notifications are presented + taps
    // are routed. Without the UNUserNotificationCenter delegate, iOS suppresses
    // notifications while the app is in the foreground and tap callbacks never
    // reach Dart. Must be set before GeneratedPluginRegistrant.register.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    // Best-effort weekly adhan refresh. iOS decides when (or whether) this
    // runs; the reliable path is rescheduling on app open/resume. The
    // identifier must match Info.plist's BGTaskSchedulerPermittedIdentifiers
    // and the Dart `_iosTaskId`.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.app.quran.adhanRefresh",
      frequency: NSNumber(value: 12 * 60 * 60)
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
