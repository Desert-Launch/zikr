import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
