package com.zikr.mapp.adhan

import android.content.Context
import android.media.AudioManager
import kotlin.math.roundToInt

/**
 * Raises the device's ALARM stream for the duration of one adhan, and puts it
 * back afterwards.
 *
 * There is no per-app "play louder than everything" volume on Android. The
 * adhan already rides `USAGE_ALARM`, so it follows the ALARM slider rather than
 * media/notification volume — but if the user has left that slider low, the
 * call to prayer is quiet no matter what the app does. The only real lever is
 * to move the system slider itself for the length of the adhan.
 *
 * That makes restoring non-negotiable: a missed restore leaves the user's alarm
 * volume changed permanently, which would also affect their morning alarm. The
 * previous level is therefore mirrored in SharedPreferences rather than held in
 * memory, so it survives the service being killed mid-adhan, and
 * [restoreIfPending] is called from every path that can end an adhan — plus at
 * the START of the next one, on boot, and on app launch, to heal a run that
 * never got to restore at all.
 *
 * Every entry point is idempotent and never throws: volume is a nicety, and it
 * must never take the adhan down with it.
 */
object AdhanAlarmVolume {
    private const val PREFS = "adhan_alarm_volume"

    /** Mirrored ALARM level to restore, or absent when no boost is active. */
    private const val KEY_PREVIOUS = "previous"

    /** Sentinel for "nothing to restore" — real levels are always >= 0. */
    private const val NONE = -1

    /**
     * Applies [percent] (0–100) of the device's maximum ALARM volume, after
     * healing any level a previous run failed to restore.
     *
     * Both directions are honoured: the slider IS the adhan's loudness, and it
     * is put back the moment the adhan ends, so lowering is as safe as raising.
     * A percent outside 1–99 that resolves to the current level is a no-op, and
     * critically leaves NO marker behind — writing one would mean a later
     * restore "restores" a level that was never changed.
     */
    fun boost(context: Context, percent: Int) {
        restoreIfPending(context)
        if (percent !in 0..100) return
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            if (max <= 0) return
            val current = am.getStreamVolume(AudioManager.STREAM_ALARM)
            // Round rather than truncate, and never resolve a non-zero request
            // to silence: at max=7, 10% truncates to 0 and would mute the adhan
            // outright — the one outcome this feature must never produce.
            val target = (max * percent / 100.0).roundToInt().coerceIn(
                if (percent > 0) 1 else 0,
                max,
            )
            if (target == current) return
            prefs(context).edit().putInt(KEY_PREVIOUS, current).apply()
            am.setStreamVolume(AudioManager.STREAM_ALARM, target, 0)
        } catch (e: Exception) {
            // SecurityException here is the common one: changing stream volume
            // is refused while Do Not Disturb is on without
            // ACCESS_NOTIFICATION_POLICY. The adhan still plays at whatever the
            // device is set to, which is the correct degradation.
        }
    }

    /**
     * Puts the ALARM stream back to the mirrored level, if a boost is pending.
     *
     * Safe to call any number of times and from any path — the marker is
     * cleared whether or not the write succeeds, so a device that refuses the
     * change (DND) doesn't leave a marker that would later stomp a level the
     * user set themselves in the meantime.
     */
    fun restoreIfPending(context: Context) {
        try {
            val store = prefs(context)
            val previous = store.getInt(KEY_PREVIOUS, NONE)
            if (previous == NONE) return
            try {
                val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                am?.setStreamVolume(AudioManager.STREAM_ALARM, previous, 0)
            } finally {
                store.edit().remove(KEY_PREVIOUS).apply()
            }
        } catch (e: Exception) {
            // Never let volume bookkeeping break a caller — every one of them is
            // either starting or ending an adhan.
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
