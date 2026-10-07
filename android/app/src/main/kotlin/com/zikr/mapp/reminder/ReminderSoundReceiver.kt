package com.zikr.mapp.reminder

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import com.zikr.mapp.adhan.AdhanAlarmVolume
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Plays a reminder's clip at its scheduled minute, on the ALARM stream, so the
 * reminder is heard even while the phone is silenced — see
 * [ReminderSoundScheduler] for why the notification channel can't do this.
 *
 * The matching notification is posted separately by Dart (on a silent channel),
 * so this receiver never touches the notification tray: it plays four seconds
 * of audio, re-arms itself for tomorrow (unless it was a one-shot), and gets
 * out of the way. No foreground
 * service, and therefore no second notification — playing audio from the
 * background is unrestricted; only *starting a foreground service* from the
 * background is, and a clip this short doesn't need one.
 *
 * Volume works like the adhan's: the ALARM stream is raised (or lowered) to the
 * alarm's volume for the length of the clip and put back afterwards, through
 * the same [AdhanAlarmVolume] marker so the two features can't restore each
 * other's levels in the wrong order.
 */
class ReminderSoundReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderSoundScheduler.EXTRA_ID, 0)
        val rawRes = intent.getStringExtra(ReminderSoundScheduler.EXTRA_RAW).orEmpty()
        val hour = intent.getIntExtra(ReminderSoundScheduler.EXTRA_HOUR, -1)
        val minute = intent.getIntExtra(ReminderSoundScheduler.EXTRA_MINUTE, -1)
        val volume = intent.getIntExtra(
            ReminderSoundScheduler.EXTRA_VOLUME,
            ReminderSoundScheduler.NO_VOLUME,
        )
        val throughSilent = intent.getBooleanExtra(ReminderSoundScheduler.EXTRA_THROUGH_SILENT, true)
        val once = intent.getBooleanExtra(ReminderSoundScheduler.EXTRA_ONCE, false)

        // Re-arm first: a failure in playback must not break the daily chain,
        // and the app may never be opened again to rebuild it. A one-shot has
        // no chain — its clip belongs to today alone — so it only clears
        // itself out of the reboot mirror.
        if (once) {
            ReminderSoundScheduler.forgetPlayedOnce(context)
        } else if (id != 0 && hour in 0..23 && minute in 0..59) {
            ReminderSoundScheduler.scheduleDaily(
                context,
                id,
                hour,
                minute,
                rawRes,
                volume,
                throughSilent,
            )
        }

        // Volume 0 is the user muting this feature's sound outright — no need
        // to touch the stream for silence.
        if (volume == 0) return
        if (!throughSilent && !deviceAllowsSound(context)) return

        play(context, rawRes, volume)
    }

    /**
     * Whether a sound that should behave like a notification's may play now.
     *
     * The clip is played on the ALARM stream, which silent/vibrate don't mute —
     * that is what lets "remind while silenced" work at all. Every other clip
     * must therefore check for itself what the OS would have checked for a
     * channel sound: the ringer is silent or on vibrate, Do Not Disturb is
     * filtering, or the phone is ringing or in a call.
     */
    private fun deviceAllowsSound(context: Context): Boolean {
        try {
            val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audio != null) {
                if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return false
                when (audio.mode) {
                    AudioManager.MODE_IN_CALL,
                    AudioManager.MODE_IN_COMMUNICATION,
                    AudioManager.MODE_RINGTONE,
                    -> return false
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                val filter = nm?.currentInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_UNKNOWN
                if (filter != NotificationManager.INTERRUPTION_FILTER_ALL &&
                    filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
                ) {
                    return false
                }
            }
        } catch (e: Exception) {
            // A state we can't read is no reason to drop the reminder's sound.
        }
        return true
    }

    /**
     * Fire-and-forget playback held open by [goAsync] so the receiver isn't
     * torn down mid-clip.
     *
     * Every exit path — completion, error, setup failure, the watchdog — runs
     * through [finish] exactly once, because leaving a PendingResult unfinished
     * is an ANR and leaving a MediaPlayer unreleased leaks an audio session.
     */
    @Suppress("DEPRECATION") // Stream-based audio focus: matches AdhanPlaybackService.
    private fun play(context: Context, rawRes: String, volume: Int) {
        val pending = goAsync()
        val app = context.applicationContext
        val audio = app.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

        val resId = app.resources.getIdentifier(rawRes, "raw", app.packageName)
        if (resId == 0) {
            pending.finish()
            return
        }
        val afd = try {
            app.resources.openRawResourceFd(resId)
        } catch (e: Exception) {
            null
        }
        if (afd == null) {
            pending.finish()
            return
        }

        var player: MediaPlayer? = null
        val done = AtomicBoolean(false)
        val finish = {
            if (done.compareAndSet(false, true)) {
                try {
                    player?.release()
                } catch (e: Exception) {
                    // Already gone — nothing left to do.
                }
                player = null
                // Only this clip's own boost: if an adhan started meanwhile, the
                // marker is now the adhan's and must survive until it ends.
                AdhanAlarmVolume.restoreIfOwnedBy(app, AdhanAlarmVolume.OWNER_REMINDER)
                try {
                    audio?.abandonAudioFocus(null)
                } catch (e: Exception) {
                    // Focus was never granted; ignore.
                }
                pending.finish()
            }
        }

        // A pending boost means an adhan owns the stream right now (or one never
        // got to restore) — play at the level it set rather than moving it.
        if (volume in 1..100 && !AdhanAlarmVolume.isBoostPending(app)) {
            AdhanAlarmVolume.boost(app, volume, AdhanAlarmVolume.OWNER_REMINDER)
        }

        // Duck whatever is playing for the length of the clip rather than
        // pausing it — a four-second reminder shouldn't stop a recitation.
        try {
            audio?.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
        } catch (e: Exception) {
            // Non-fatal — play anyway.
        }

        val mp = MediaPlayer()
        player = mp
        mp.setAudioAttributes(
            AudioAttributes.Builder()
                // USAGE_ALARM is what makes this audible while the ringer is
                // silenced: it follows the ALARM volume slider, which the
                // silent/vibrate modes don't touch.
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build(),
        )
        // Keeps the CPU alive for the clip on a dozing device (WAKE_LOCK is
        // already declared for the adhan).
        mp.setWakeMode(app, PowerManager.PARTIAL_WAKE_LOCK)
        try {
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        } catch (e: Exception) {
            try {
                afd.close()
            } catch (e2: Exception) {
                // ignore
            }
            finish()
            return
        }
        try {
            afd.close()
        } catch (e: Exception) {
            // ignore
        }
        mp.setOnCompletionListener { finish() }
        mp.setOnErrorListener { _, _, _ ->
            finish()
            true
        }
        mp.setOnPreparedListener { it.start() }
        // Watchdog: a codec that never reaches onPrepared/onCompletion would
        // otherwise hold the broadcast open until the system kills it.
        Handler(Looper.getMainLooper()).postDelayed({ finish() }, PLAYBACK_TIMEOUT_MS)
        try {
            mp.prepareAsync()
        } catch (e: Exception) {
            finish()
        }
    }

    private companion object {
        /** Generous ceiling for a clip that runs about four seconds. */
        const val PLAYBACK_TIMEOUT_MS = 30_000L
    }
}
