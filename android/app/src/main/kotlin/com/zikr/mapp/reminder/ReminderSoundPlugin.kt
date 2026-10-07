package com.zikr.mapp.reminder

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge that lets Dart arm/cancel the reminder-sound alarms —
 * the app-played clip that makes a reminder audible while the phone is silenced
 * (see [ReminderSoundScheduler]).
 *
 * Registered against the app's FlutterEngine in MainActivity, so it is only
 * reachable from the UI isolate. Background isolates get a
 * MissingPluginException, which Dart treats as a no-op: the alarms stay exactly
 * as the UI isolate (or the boot receiver) last armed them.
 */
class ReminderSoundPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleDaily" -> {
                val id = call.argument<Int>("id")
                val hour = call.argument<Int>("hour")
                val minute = call.argument<Int>("minute")
                val rawRes = call.argument<String>("rawRes")
                if (id == null || hour == null || minute == null || rawRes.isNullOrEmpty()) {
                    result.error("bad_args", "id, hour, minute and rawRes are required", null)
                    return
                }
                val volume = call.argument<Int>("volume") ?: ReminderSoundScheduler.NO_VOLUME
                val throughSilent = call.argument<Boolean>("throughSilent") ?: true
                ReminderSoundScheduler.scheduleDaily(
                    context,
                    id,
                    hour,
                    minute,
                    rawRes,
                    volume,
                    throughSilent,
                )
                result.success(true)
            }
            "scheduleOnce" -> {
                val id = call.argument<Int>("id")
                // A Dart int arrives as Integer or Long depending on its size.
                val trigger = call.argument<Number>("triggerAtMillis")?.toLong()
                val rawRes = call.argument<String>("rawRes")
                if (id == null || trigger == null || rawRes.isNullOrEmpty()) {
                    result.error("bad_args", "id, triggerAtMillis and rawRes are required", null)
                    return
                }
                val volume = call.argument<Int>("volume") ?: ReminderSoundScheduler.NO_VOLUME
                val throughSilent = call.argument<Boolean>("throughSilent") ?: true
                ReminderSoundScheduler.scheduleOnce(
                    context,
                    id,
                    trigger,
                    rawRes,
                    volume,
                    throughSilent,
                )
                result.success(true)
            }
            "cancel" -> {
                val id = call.argument<Int>("id")
                if (id == null) {
                    result.error("bad_args", "id is required", null)
                    return
                }
                ReminderSoundScheduler.cancel(context, id)
                result.success(true)
            }
            "cancelIds" -> {
                val ids = call.argument<List<Int>>("ids")
                if (ids == null) {
                    result.error("bad_args", "ids is required", null)
                    return
                }
                ReminderSoundScheduler.cancelIds(context, ids)
                result.success(true)
            }
            "cancelAll" -> {
                ReminderSoundScheduler.cancelAll(context)
                result.success(true)
            }
            "canScheduleExact" -> result.success(ReminderSoundScheduler.canScheduleExact(context))
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.zikr.mapp/reminder_sound"
    }
}
