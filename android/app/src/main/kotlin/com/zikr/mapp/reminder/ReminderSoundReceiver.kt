package com.zikr.mapp.reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Plays a reminder's clip at its scheduled minute, on the ALARM stream, so the
 * reminder is heard even while the phone is silenced — see
 * [ReminderSoundScheduler] for why the notification channel can't do this.
 *
 * The matching notification is posted separately by Dart (on a silent channel),
 * so this receiver never touches the notification tray: it plays four seconds
 * of audio, re-arms itself for tomorrow, and gets out of the way. No foreground
 * service, and therefore no second notification — playing audio from the
 * background is unrestricted; only *starting a foreground service* from the
 * background is, and a clip this short doesn't need one.
 */
class ReminderSoundReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderSoundScheduler.EXTRA_ID, 0)
        val rawRes = intent.getStringExtra(ReminderSoundScheduler.EXTRA_RAW).orEmpty()
        val hour = intent.getIntExtra(ReminderSoundScheduler.EXTRA_HOUR, -1)
        val minute = intent.getIntExtra(ReminderSoundScheduler.EXTRA_MINUTE, -1)

        // Re-arm first: a failure in playback must not break the daily chain,
        // and the app may never be opened again to rebuild it.
        if (id != 0 && hour in 0..23 && minute in 0..59) {
            ReminderSoundScheduler.scheduleDaily(context, id, hour, minute, rawRes)
        }

        play(context, rawRes)
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
    private fun play(context: Context, rawRes: String) {
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
                try {
                    audio?.abandonAudioFocus(null)
                } catch (e: Exception) {
                    // Focus was never granted; ignore.
                }
                pending.finish()
            }
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
