package com.zikr.mapp.adhan

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge that lets Dart arm/cancel the native full-adhan alarms.
 * Registered against the app's FlutterEngine in MainActivity, so it is only
 * reachable from the UI isolate (background isolates fall back to the
 * notification-sound path, which is why Dart treats MissingPluginException as a
 * no-op).
 */
class AdhanAlarmPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedule" -> {
                val id = call.argument<Int>("id")
                val trigger = call.argument<Number>("triggerAtMillis")?.toLong()
                if (id == null || trigger == null) {
                    result.error("bad_args", "id and triggerAtMillis are required", null)
                    return
                }
                AdhanAlarmScheduler.schedule(
                    context,
                    id,
                    trigger,
                    call.argument<String>("rawRes").orEmpty(),
                    call.argument<String>("title") ?: "الأذان",
                    call.argument<String>("body").orEmpty(),
                    call.argument<String>("stopLabel") ?: "إيقاف",
                )
                result.success(true)
            }
            "cancel" -> {
                val id = call.argument<Int>("id")
                if (id == null) {
                    result.error("bad_args", "id is required", null)
                    return
                }
                AdhanAlarmScheduler.cancel(context, id)
                result.success(true)
            }
            "cancelAll" -> {
                AdhanAlarmScheduler.cancelAll(context)
                result.success(true)
            }
            "canScheduleExact" -> result.success(AdhanAlarmScheduler.canScheduleExact(context))
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.zikr.mapp/adhan_alarm"
    }
}
