package com.zikr.mapp.widget

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge for the lock-screen prayer notification
 * ([PrayerLockNotification]): the Settings switch, and a refresh the app runs
 * on launch to bring back a notification a force-stop took down.
 *
 * Registered in MainActivity, so only the UI isolate reaches it. Background
 * isolates don't need it: a snapshot they publish reaches the notification
 * through the widget provider's `APPWIDGET_UPDATE`.
 */
class PrayerLockScreenPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isEnabled" -> result.success(PrayerLockNotification.isEnabled(context))
            "setEnabled" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled == null) {
                    result.error("bad_args", "enabled is required", null)
                    return
                }
                // Switching on something that can't be seen would leave the
                // switch lying; Dart turns this false into a prompt instead.
                if (enabled && !PrayerLockNotification.canShow(context)) {
                    result.success(false)
                    return
                }
                PrayerLockNotification.setEnabled(context, enabled)
                PrayerWidgetProvider.refreshAll(context)
                result.success(true)
            }
            "refresh" -> {
                PrayerWidgetProvider.refreshAll(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.zikr.mapp/prayer_lock_screen"
    }
}
