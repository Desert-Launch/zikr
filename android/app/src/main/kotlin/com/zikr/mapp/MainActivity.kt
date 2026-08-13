package com.zikr.mapp

import com.ryanheise.audioservice.AudioServiceActivity
import com.zikr.mapp.adhan.AdhanAlarmPlugin
import com.zikr.mapp.adhan.AdhanAlarmVolume
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Force-stopping the app mid-adhan kills the playback service without
        // running any of its stop paths, so the raised ALARM volume would stay
        // raised indefinitely. Opening the app is the soonest the user can
        // reach us again — heal it here rather than waiting for the next adhan.
        AdhanAlarmVolume.restoreIfPending(applicationContext)
        // Bridge for arming the native full-adhan alarms (Android background
        // auto-play). Only registered on the UI engine — background isolates
        // gracefully fall back to the notification-sound path.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AdhanAlarmPlugin.CHANNEL)
            .setMethodCallHandler(AdhanAlarmPlugin(applicationContext))
    }
}
