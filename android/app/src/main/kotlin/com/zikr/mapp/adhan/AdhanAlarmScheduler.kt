package com.zikr.mapp.adhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * Schedules exact, device-waking alarms that fire [AdhanAlarmReceiver] at each
 * prayer time so the FULL adhan can play even when the app is killed.
 *
 * Every armed alarm is mirrored into SharedPreferences so [AdhanBootReceiver]
 * can re-arm the still-future ones after a reboot (the OS clears all pending
 * alarms on boot). Dart owns the schedule and re-arms the rolling window on
 * every app open; this object is the durable native floor under that.
 */
object AdhanAlarmScheduler {
    private const val PREFS = "adhan_audio_alarms"
    private const val KEY = "armed"

    const val EXTRA_ID = "id"
    const val EXTRA_RAW = "raw"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"
    const val EXTRA_STOP = "stop"

    /** True when exact alarms are allowed (always pre-API-31; gated after). */
    fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    fun schedule(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        rawRes: String,
        title: String,
        body: String,
        stopLabel: String,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = receiverPendingIntent(context, id, rawRes, title, body, stopLabel)
        try {
            if (canScheduleExact(context)) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            } else {
                // No exact-alarm grant: fall back to an inexact idle-safe alarm
                // rather than dropping the adhan entirely.
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
        persist(context, id, triggerAtMillis, rawRes, title, body, stopLabel)
    }

    fun cancel(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(receiverPendingIntent(context, id, "", "", "", ""))
        remove(context, id)
    }

    fun cancelAll(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val all = read(context)
        for (i in 0 until all.length()) {
            am.cancel(receiverPendingIntent(context, all.getJSONObject(i).getInt("id"), "", "", "", ""))
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(KEY).apply()
    }

    /** Re-arms every persisted alarm still in the future. Called after reboot. */
    fun reArmAll(context: Context) {
        val now = System.currentTimeMillis()
        val all = read(context)
        for (i in 0 until all.length()) {
            val o = all.getJSONObject(i)
            val trigger = o.getLong("trigger")
            if (trigger <= now) continue
            schedule(
                context,
                o.getInt("id"),
                trigger,
                o.getString("raw"),
                o.getString("title"),
                o.getString("body"),
                o.getString("stop"),
            )
        }
    }

    private fun receiverPendingIntent(
        context: Context,
        id: Int,
        rawRes: String,
        title: String,
        body: String,
        stopLabel: String,
    ): PendingIntent {
        // The per-id action keeps each PendingIntent distinct for cancellation
        // (extras are ignored by Intent.filterEquals, the action is not).
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = "com.zikr.mapp.adhan.FIRE_$id"
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_RAW, rawRes)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_STOP, stopLabel)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getBroadcast(context, id, intent, flags)
    }

    // --- SharedPreferences mirror -------------------------------------------

    private fun read(context: Context): JSONArray {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "[]")
        return try {
            JSONArray(raw)
        } catch (e: Exception) {
            JSONArray()
        }
    }

    private fun write(context: Context, array: JSONArray) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, array.toString()).apply()
    }

    private fun persist(
        context: Context,
        id: Int,
        trigger: Long,
        raw: String,
        title: String,
        body: String,
        stop: String,
    ) {
        val out = withoutId(read(context), id)
        out.put(
            JSONObject().apply {
                put("id", id)
                put("trigger", trigger)
                put("raw", raw)
                put("title", title)
                put("body", body)
                put("stop", stop)
            },
        )
        write(context, out)
    }

    private fun remove(context: Context, id: Int) {
        write(context, withoutId(read(context), id))
    }

    private fun withoutId(array: JSONArray, id: Int): JSONArray {
        val out = JSONArray()
        for (i in 0 until array.length()) {
            val o = array.getJSONObject(i)
            if (o.getInt("id") != id) out.put(o)
        }
        return out
    }
}
