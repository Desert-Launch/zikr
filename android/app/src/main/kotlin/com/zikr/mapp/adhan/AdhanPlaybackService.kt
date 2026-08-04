package com.zikr.mapp.adhan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Foreground service that plays the full adhan clip ([R.raw] resource named by
 * the [AdhanAlarmScheduler.EXTRA_RAW] extra) at prayer time. Shows an ongoing
 * notification with a Stop action and tears itself down when playback finishes
 * or the user stops it. Declared with `mediaPlayback` foreground type.
 */
class AdhanPlaybackService : Service() {

    private var player: MediaPlayer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopEverything()
            return START_NOT_STICKY
        }

        val rawRes = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_RAW).orEmpty()
        val title = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_TITLE) ?: "الأذان"
        val body = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_BODY).orEmpty()
        val stopLabel = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_STOP) ?: "إيقاف"
        val openLabel = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_OPEN) ?: "فتح التطبيق"
        val prayerKey = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_PRAYER).orEmpty()
        val fullScreen = intent?.getBooleanExtra(AdhanAlarmScheduler.EXTRA_FULLSCREEN, true) ?: true

        startInForeground(
            buildNotification(title, body, stopLabel, openLabel, prayerKey, fullScreen),
        )
        playAdhan(rawRes)
        return START_NOT_STICKY
    }

    /**
     * Intent for the full-screen alarm UI. Carries the already-localized labels
     * so [AdhanAlarmActivity] never has to touch resources or Flutter.
     */
    private fun alarmActivityIntent(
        title: String,
        body: String,
        stopLabel: String,
        openLabel: String,
        prayerKey: String,
    ) = Intent(this, AdhanAlarmActivity::class.java).apply {
        addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_NO_USER_ACTION,
        )
        putExtra(AdhanAlarmScheduler.EXTRA_TITLE, title)
        putExtra(AdhanAlarmScheduler.EXTRA_BODY, body)
        putExtra(AdhanAlarmScheduler.EXTRA_STOP, stopLabel)
        putExtra(AdhanAlarmScheduler.EXTRA_OPEN, openLabel)
        putExtra(AdhanAlarmScheduler.EXTRA_PRAYER, prayerKey)
    }

    private fun startInForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun playAdhan(rawRes: String) {
        releasePlayer()
        val resId = resources.getIdentifier(rawRes, "raw", packageName)
        if (resId == 0) {
            stopEverything()
            return
        }
        val afd = try {
            resources.openRawResourceFd(resId)
        } catch (e: Exception) {
            null
        }
        if (afd == null) {
            stopEverything()
            return
        }

        // Duck/pause other media for the call to prayer.
        try {
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            @Suppress("DEPRECATION")
            am.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        } catch (e: Exception) {
            // Non-fatal — play anyway.
        }

        val mp = MediaPlayer()
        mp.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build(),
        )
        // Keeps the CPU alive for the duration so the adhan isn't cut on a
        // dozing device (needs WAKE_LOCK, already declared).
        mp.setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
        try {
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        } catch (e: Exception) {
            afd.close()
            mp.release()
            stopEverything()
            return
        }
        afd.close()
        mp.setOnCompletionListener { stopEverything() }
        mp.setOnErrorListener { _, _, _ ->
            stopEverything()
            true
        }
        mp.setOnPreparedListener { it.start() }
        mp.prepareAsync()
        player = mp
    }

    private fun releasePlayer() {
        player?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (e: Exception) {
                // ignore
            }
            it.release()
        }
        player = null
    }

    private fun stopEverything() {
        releasePlayer()
        // Tells a visible AdhanAlarmActivity to dismiss itself, whether the
        // adhan finished on its own or was stopped from the notification.
        sendBroadcast(Intent(ACTION_FINISHED).setPackage(packageName))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        releasePlayer()
        super.onDestroy()
    }

    private fun buildNotification(
        title: String,
        body: String,
        stopLabel: String,
        openLabel: String,
        prayerKey: String,
        fullScreen: Boolean,
    ): Notification {
        ensureChannel()

        var piFlags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            piFlags = piFlags or PendingIntent.FLAG_IMMUTABLE
        }

        val stopPi = PendingIntent.getService(
            this,
            1,
            Intent(this, AdhanPlaybackService::class.java).apply { action = ACTION_STOP },
            piFlags,
        )
        val alarmPi = PendingIntent.getActivity(
            this,
            3,
            alarmActivityIntent(title, body, stopLabel, openLabel, prayerKey),
            piFlags,
        )
        val launchPi = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 2, it, piFlags)
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, stopLabel, stopPi)

        if (fullScreen) {
            // The ONLY reliable way to launch an Activity from the background on
            // Android 10+. When the device is locked or the screen is off the
            // system launches AdhanAlarmActivity directly; when the user is
            // actively using the phone it degrades to a heads-up notification,
            // which is the intended, OS-enforced behaviour.
            //
            // On Android 14+ this additionally requires the USE_FULL_SCREEN_INTENT
            // grant (declared in the manifest, revocable in app settings) — if the
            // user revoked it, the heads-up path is the graceful degradation.
            builder.setFullScreenIntent(alarmPi, true)
                .setContentIntent(alarmPi)
        } else {
            builder.setContentIntent(launchPi)
        }

        return builder.build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Adhan playback",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Plays the full adhan at prayer time"
            // The audio comes from MediaPlayer, not the channel — keep it silent
            // so we don't double up with a notification tone.
            setSound(null, null)
            enableVibration(false)
        }
        nm.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_STOP = "com.zikr.mapp.adhan.STOP"

        /** Broadcast when playback ends, so [AdhanAlarmActivity] can dismiss. */
        const val ACTION_FINISHED = "com.zikr.mapp.adhan.FINISHED"
        private const val CHANNEL_ID = "adhan_playback_channel"
        private const val NOTIF_ID = 920100
    }
}
