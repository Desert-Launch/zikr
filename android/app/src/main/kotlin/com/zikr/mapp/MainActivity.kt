package com.zikr.mapp

import com.ryanheise.audioservice.AudioServiceActivity
import com.zikr.mapp.adhan.AdhanAlarmPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Bridge for arming the native full-adhan alarms (Android background
        // auto-play). Only registered on the UI engine — background isolates
        // gracefully fall back to the notification-sound path.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AdhanAlarmPlugin.CHANNEL)
            .setMethodCallHandler(AdhanAlarmPlugin(applicationContext))
    }
}
