package com.zikr.mapp.reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar
import org.json.JSONArray
import org.json.JSONObject

/**
 * Daily exact alarms whose ONLY job is to play a short bundled clip at the
 * moment a reminder notification is posted.
 *
 * # Why this exists
 *
 * A notification channel's sound is played by the OS, and every OEM gets to
 * decide when that happens. Samsung's "Mute" sound mode drops app notification
 * sounds outright — even on a channel built with `USAGE_ALARM`, which follows
 * the ALARM volume and is exactly what the platform documents for "audible
 * while silenced". Verified on a Galaxy Tab: the notification posts on the
 * alarm-usage channel, `zen_mode=0`, `STREAM_ALARM` unmuted at 11/15 — and no
 * audio player is ever created.
 *
 * Audio the APP plays is not subject to that: it follows the stream it asks
 * for, and the ALARM stream is not muted by the ringer. That is why the full
 * adhan is audible in Mute mode while the salawat channel sound was not. This
 * object is that same technique, reduced to what a reminder needs.
 *
 * # Deliberately NOT an alarm clock
 *
 * Unlike `AdhanAlarmScheduler` this uses [AlarmManager.setExactAndAllowWhileIdle],
 * not `setAlarmClock`: no status-bar alarm icon, no "next alarm" on the
 * lockscreen, no full-screen UI. The user asked for a normal notification that
 * can be heard — not an alarm going off. The notification itself is still
 * posted by Dart through flutter_local_notifications, on a SILENT channel, so
 * exactly one notification appears and exactly one sound plays.
 *
 * # Durability
 *
 * Every armed alarm is mirrored into its own SharedPreferences file so
 * `AdhanBootReceiver` can re-arm the still-future ones after a reboot (the OS
 * clears pending alarms on boot). The mirror is separate from the adhan's, so
 * the adhan's `cancelAll` — which runs on every prayer-window rebuild — can
 * never sweep these away. Each daily alarm also re-arms itself for the next
 * day when it fires, so the reminders keep sounding even if the app is never
 * opened again. A one-shot ([scheduleOnce]) plays once and is then dropped
 * from the mirror.
 *
 * # Volume
 *
 * This is also the ONLY place a reminder's loudness can be controlled — the OS
 * plays a channel sound at whatever the system slider says. So the salawat
 * reminder and the hourly zekr play through here on Android whatever the
 * silent-mode setting is, each alarm carrying its feature's volume (0–100) and
 * whether it may sound through silent mode. Both are baked into the alarm, like
 * the adhan's volume, because the receiver has no Flutter isolate to ask.
 */
object ReminderSoundScheduler {
    private const val PREFS = "reminder_sound_alarms"
    private const val KEY = "armed"

    const val EXTRA_ID = "id"
    const val EXTRA_RAW = "raw"
    const val EXTRA_HOUR = "hour"
    const val EXTRA_MINUTE = "minute"
    const val EXTRA_VOLUME = "volume"
    const val EXTRA_THROUGH_SILENT = "throughSilent"
    const val EXTRA_ONCE = "once"

    /** Volume sentinel: leave the ALARM stream where the user has it. Also what
     *  alarms mirrored before the volume setting existed decode to. */
    const val NO_VOLUME = -1

    /** True when exact alarms are allowed (always pre-API-31; gated after). */
    fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    /**
     * Arms [id] to play `res/raw/[rawRes]` at the next [hour]:[minute], and
     * every day after. Re-arming an existing id replaces it.
     *
     * [volume] is 0–100 of the ALARM stream's maximum, or [NO_VOLUME]. With
     * [throughSilent] false the clip behaves like a notification sound and stays
     * quiet on silent/vibrate, in Do Not Disturb and during a call.
     */
    fun scheduleDaily(
        context: Context,
        id: Int,
        hour: Int,
        minute: Int,
        rawRes: String,
        volume: Int,
        throughSilent: Boolean,
    ) {
        val trigger = nextOccurrence(hour, minute)
        arm(context, id, trigger, hour, minute, rawRes, volume, throughSilent, once = false)
        persist(context, id, trigger, hour, minute, rawRes, volume, throughSilent, once = false)
    }

    /**
     * Arms [id] to play `res/raw/[rawRes]` once, at [triggerAtMillis], replacing
     * any alarm already armed under that id. A trigger already past arms
     * nothing.
     *
     * For a clip that differs from one day to the next (the hourly zekr when
     * its azkar rotate over several days), so it is NOT re-armed after it
     * plays — Dart re-arms the next few days each time it reschedules. It is
     * still mirrored, so a reboot before it fires doesn't lose it.
     */
    fun scheduleOnce(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        rawRes: String,
        volume: Int,
        throughSilent: Boolean,
    ) {
        if (triggerAtMillis <= System.currentTimeMillis()) return
        arm(context, id, triggerAtMillis, -1, -1, rawRes, volume, throughSilent, once = true)
        persist(context, id, triggerAtMillis, -1, -1, rawRes, volume, throughSilent, once = true)
    }

    /**
     * Drops one-shot alarms whose time has passed from the mirror, so a reboot
     * doesn't try to re-arm them and the mirror doesn't grow by a day's worth
     * of entries every day. Called by the receiver when a one-shot plays.
     */
    fun forgetPlayedOnce(context: Context) {
        val now = System.currentTimeMillis()
        val all = read(context)
        val out = JSONArray()
        for (i in 0 until all.length()) {
            val o = all.getJSONObject(i)
            if (o.optBoolean("once", false) && o.optLong("trigger", 0L) <= now) continue
            out.put(o)
        }
        write(context, out)
    }

    fun cancel(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(cancellationPendingIntent(context, id))
        write(context, withoutId(read(context), id))
    }

    /**
     * Cancels each of [ids] in one pass over the mirror. Each feature clears
     * only its own block this way — `cancelAll` would take the other feature's
     * clips with it.
     */
    fun cancelIds(context: Context, ids: List<Int>) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        var remaining = read(context)
        for (id in ids) {
            am.cancel(cancellationPendingIntent(context, id))
            remaining = withoutId(remaining, id)
        }
        write(context, remaining)
    }

    /** Cancels every reminder-sound alarm this object ever armed. */
    fun cancelAll(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val all = read(context)
        for (i in 0 until all.length()) {
            am.cancel(cancellationPendingIntent(context, all.getJSONObject(i).getInt("id")))
        }
        write(context, JSONArray())
    }

    /**
     * Re-arms every mirrored alarm at its next occurrence. Called after a
     * reboot or an app update, when the OS has dropped the pending alarms but
     * the user's reminder settings are unchanged.
     *
     * Daily repeats roll a past time forward to tomorrow rather than dropping
     * it — a stored time that has already passed today is still wanted
     * tomorrow. One-shots are re-armed only while still ahead; a passed one is
     * dropped, since the clip it carried belonged to that day alone.
     */
    fun reArmAll(context: Context) {
        val now = System.currentTimeMillis()
        val all = read(context)
        for (i in 0 until all.length()) {
            val o = all.getJSONObject(i)
            if (o.optBoolean("once", false)) {
                val trigger = o.optLong("trigger", 0L)
                if (trigger > now) {
                    scheduleOnce(
                        context,
                        o.getInt("id"),
                        trigger,
                        o.getString("raw"),
                        o.optInt("volume", NO_VOLUME),
                        o.optBoolean("throughSilent", true),
                    )
                } else {
                    write(context, withoutId(read(context), o.getInt("id")))
                }
                continue
            }
            scheduleDaily(
                context,
                o.getInt("id"),
                o.getInt("hour"),
                o.getInt("minute"),
                o.getString("raw"),
                // Absent on alarms mirrored before these settings existed —
                // all of them salawat "remind while silenced" clips played at
                // the stream's own level, which is exactly what these restore.
                o.optInt("volume", NO_VOLUME),
                o.optBoolean("throughSilent", true),
            )
        }
    }

    /** The next future [hour]:[minute] in local wall-clock time. */
    private fun nextOccurrence(hour: Int, minute: Int): Long {
        val now = System.currentTimeMillis()
        val c = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        // Recomputed from the wall clock every day rather than by adding 24h,
        // so a DST shift moves the reminder with the clock instead of dragging
        // it an hour off.
        if (c.timeInMillis <= now) c.add(Calendar.DAY_OF_YEAR, 1)
        return c.timeInMillis
    }

    private fun arm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        hour: Int,
        minute: Int,
        rawRes: String,
        volume: Int,
        throughSilent: Boolean,
        once: Boolean,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = receiverPendingIntent(context, id, hour, minute, rawRes, volume, throughSilent, once)
        try {
            // ...AndAllowWhileIdle so Doze delays it by seconds rather than
            // holding it until the next maintenance window. Reminders sit hours
            // apart, so the idle-quota on this call is never a factor.
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        } catch (e: SecurityException) {
            // Exact-alarm grant revoked: an inexact alarm still plays the clip,
            // a few minutes late, instead of leaving the reminder silent.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
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
        hour: Int,
        minute: Int,
        rawRes: String,
        volume: Int,
        throughSilent: Boolean,
        once: Boolean,
    ): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, ReminderSoundReceiver::class.java).apply {
            // Per-id action: extras are ignored by Intent.filterEquals, the
            // action is not, so this is what keeps each alarm cancellable.
            action = "com.zikr.mapp.reminder.PLAY_$id"
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_RAW, rawRes)
            putExtra(EXTRA_HOUR, hour)
            putExtra(EXTRA_MINUTE, minute)
            putExtra(EXTRA_VOLUME, volume)
            putExtra(EXTRA_THROUGH_SILENT, throughSilent)
            putExtra(EXTRA_ONCE, once)
        },
        pendingIntentFlags(),
    )

    /** Matches [receiverPendingIntent] for `AlarmManager.cancel`, which compares
     *  with `Intent.filterEquals` — component and action only. */
    private fun cancellationPendingIntent(context: Context, id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, ReminderSoundReceiver::class.java).apply {
                action = "com.zikr.mapp.reminder.PLAY_$id"
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
        hour: Int,
        minute: Int,
        raw: String,
        volume: Int,
        throughSilent: Boolean,
        once: Boolean,
    ) {
        val out = withoutId(read(context), id)
        out.put(
            JSONObject().apply {
                put("id", id)
                put("trigger", trigger)
                put("hour", hour)
                put("minute", minute)
                put("raw", raw)
                put("volume", volume)
                put("throughSilent", throughSilent)
                put("once", once)
            },
        )
        write(context, out)
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
