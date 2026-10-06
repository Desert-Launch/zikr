import Flutter
import GoogleMaps
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

    // Dart hands the Maps SDK its key before the nearby-mosques map is built.
    if let registrar = registrar(forPlugin: "MapsSdkChannel") {
      Self.registerMapsSdk(with: registrar.messenger())
    }

    // Adhan alarm bridge (AlarmKit on iOS 26+, critical alerts below that).
    // Registered after GeneratedPluginRegistrant so it can't be clobbered by a
    // plugin claiming the same channel name.
    if let controller = window?.rootViewController as? FlutterViewController {
      AdhanAlarmChannel.register(with: controller.binaryMessenger)
    }

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

  /// `ensureReady({apiKey})` gives `GMSServices` the key Dart was built with and
  /// answers whether a map may now be created. A map view created without a
  /// key aborts the app inside the SDK, so Dart never builds one on `false`.
  ///
  /// The key comes from Dart, not the native build, so the two can't disagree:
  /// the Codemagic build only compiles the key into Dart (see MapsSdk).
  private static func registerMapsSdk(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.zikr.mapp/maps_sdk", binaryMessenger: messenger)
    // The SDK takes a key once per launch; a hot restart asks again.
    var provided = false
    channel.setMethodCallHandler { call, result in
      guard call.method == "ensureReady" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if !provided,
         let key = (call.arguments as? [String: Any])?["apiKey"] as? String,
         !key.isEmpty {
        provided = GMSServices.provideAPIKey(key)
      }
      result(provided)
    }
  }
}
