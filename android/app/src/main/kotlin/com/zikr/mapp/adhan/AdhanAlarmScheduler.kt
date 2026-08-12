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
    const val EXTRA_OPEN = "open"
    const val EXTRA_PRAYER = "prayer"
    const val EXTRA_FULLSCREEN = "fullScreen"

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
        openLabel: String,
        prayerKey: String,
        fullScreen: Boolean,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = receiverPendingIntent(
            context, id, rawRes, title, body, stopLabel, openLabel, prayerKey, fullScreen,
        )
        try {
            // setAlarmClock is the strongest guarantee Android offers: it is
            // treated as a user-visible alarm, so it pierces Doze and App
            // Standby buckets that delay setExactAndAllowWhileIdle, and it
            // surfaces the status-bar alarm icon. Paired with USE_EXACT_ALARM
            // in the manifest (an "alarm clock" app is exactly our case), it
            // also survives the SCHEDULE_EXACT_ALARM revoke on Android 13+.
            val show = showPendingIntent(
                context, id, title, body, stopLabel, openLabel, prayerKey,
            )
            am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAtMillis, show), pi)
        } catch (e: SecurityException) {
            // No exact-alarm grant at all: degrade rather than drop the adhan.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
        persist(
            context, id, triggerAtMillis, rawRes, title, body, stopLabel,
            openLabel, prayerKey, fullScreen,
        )
    }

    fun cancel(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(cancellationPendingIntent(context, id))
        remove(context, id)
    }

    /**
     * Cancels every armed alarm whose id is not in [except].
     *
     * Dart rebuilds its rolling window by cancelling everything and re-arming
     * it, so the default really is "clear the lot". [except] is for alarms that
     * are NOT part of that window and therefore never get re-armed — the
     * one-shot test alarm. Sweeping one of those away silently kills an alarm
     * the user armed seconds earlier: the audio, the foreground service and the
     * full-screen Activity all hang off this alarm, so what's left is the
     * companion notification alone, which is posted on a deliberately silent
     * channel precisely because this alarm was meant to carry the sound.
     *
     * Excepted ids stay in the mirror too, so a reboot still re-arms them.
     */
    fun cancelAll(context: Context, except: Set<Int> = emptySet()) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val all = read(context)
        val kept = JSONArray()
        for (i in 0 until all.length()) {
            val entry = all.getJSONObject(i)
            val id = entry.getInt("id")
            if (id in except) {
                kept.put(entry)
                continue
            }
            am.cancel(cancellationPendingIntent(context, id))
        }
        write(context, kept)
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
                o.optString("open"),
                o.optString("prayer"),
                o.optBoolean("fullScreen", true),
            )
        }
    }

    private fun pendingIntentFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    private fun receiverPendingIntent(
        context: Context,
        id: Int,
        rawRes: String,
        title: String,
        body: String,
        stopLabel: String,
        openLabel: String,
        prayerKey: String,
        fullScreen: Boolean,
    ): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, AdhanAlarmReceiver::class.java).apply {
            // The per-id action keeps each PendingIntent distinct for
            // cancellation (extras are ignored by Intent.filterEquals, the
            // action is not).
            action = "com.zikr.mapp.adhan.FIRE_$id"
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_RAW, rawRes)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_STOP, stopLabel)
            putExtra(EXTRA_OPEN, openLabel)
            putExtra(EXTRA_PRAYER, prayerKey)
            putExtra(EXTRA_FULLSCREEN, fullScreen)
        },
        pendingIntentFlags(),
    )

    /**
     * Matches [receiverPendingIntent] for `AlarmManager.cancel`, which compares
     * with `Intent.filterEquals` — only the component and action matter, so the
     * extras are deliberately omitted here.
     */
    private fun cancellationPendingIntent(context: Context, id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, AdhanAlarmReceiver::class.java).apply {
                action = "com.zikr.mapp.adhan.FIRE_$id"
            },
            pendingIntentFlags(),
        )

    /**
     * What the user reaches by tapping the status-bar alarm icon before the
     * adhan fires: the same full-screen alarm UI, so the pending prayer is
     * identifiable at a glance.
     */
    private fun showPendingIntent(
        context: Context,
        id: Int,
        title: String,
        body: String,
        stopLabel: String,
        openLabel: String,
        prayerKey: String,
    ): PendingIntent = PendingIntent.getActivity(
        context,
        id,
        Intent(context, AdhanAlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_STOP, stopLabel)
            putExtra(EXTRA_OPEN, openLabel)
            putExtra(EXTRA_PRAYER, prayerKey)
        },
        pendingIntentFlags(),
    )

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
        open: String,
        prayer: String,
        fullScreen: Boolean,
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
                put("open", open)
                put("prayer", prayer)
                put("fullScreen", fullScreen)
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
