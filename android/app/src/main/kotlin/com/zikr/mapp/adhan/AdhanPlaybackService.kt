package com.zikr.mapp.adhan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import androidx.core.app.NotificationCompat

/**
 * Foreground service that plays the full adhan clip ([R.raw] resource named by
 * the [AdhanAlarmScheduler.EXTRA_RAW] extra) at prayer time. Shows an ongoing
 * notification with a Stop action and tears itself down when playback finishes
 * or the user stops it. Declared with `mediaPlayback` foreground type.
 */
class AdhanPlaybackService : Service(), SensorEventListener {

    private var player: MediaPlayer? = null

    private var sensors: SensorManager? = null

    /**
     * True once the device has been seen NOT face-down since this adhan began.
     *
     * Turning the phone over is the gesture; *already lying* face-down is not.
     * Without this, a phone left screen-down on a desk — the normal way plenty
     * of people leave it — would silence every adhan the moment it started, and
     * the user would never hear one again without knowing why.
     */
    private var flipArmed = false

    /** Uptime millis since the device went face-down, or 0 when it isn't. */
    private var faceDownSince = 0L

    /**
     * The alarm id this run was started with. It doubles as the id of the Dart
     * companion notification scheduled by `AdhanScheduler` for the same prayer,
     * which is what [stopEverything] has to cancel — stopping the service only
     * removes the service's OWN notification, leaving the companion sitting in
     * the tray with the adhan already silenced.
     */
    private var alarmId: Int = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopEverything()
            return START_NOT_STICKY
        }

        alarmId = intent?.getIntExtra(AdhanAlarmScheduler.EXTRA_ID, 0) ?: 0
        val rawRes = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_RAW).orEmpty()
        val title = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_TITLE) ?: "الأذان"
        val body = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_BODY).orEmpty()
        val stopLabel = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_STOP) ?: "إيقاف"
        val openLabel = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_OPEN) ?: "فتح التطبيق"
        val prayerKey = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_PRAYER).orEmpty()
        val fullScreen = intent?.getBooleanExtra(AdhanAlarmScheduler.EXTRA_FULLSCREEN, true) ?: true
        val volume = intent?.getIntExtra(
            AdhanAlarmScheduler.EXTRA_VOLUME,
            AdhanAlarmScheduler.DEFAULT_VOLUME,
        ) ?: AdhanAlarmScheduler.DEFAULT_VOLUME

        // Before anything else: heal a level a previous run never restored (see
        // [AdhanAlarmVolume]), then raise the ALARM stream for this adhan. Done
        // here rather than in playAdhan so a raw-resource failure — which exits
        // through stopEverything — still passes through the restore path.
        AdhanAlarmVolume.boost(this, volume)

        startInForeground(
            buildNotification(title, body, stopLabel, openLabel, prayerKey, fullScreen),
        )
        if (fullScreen) {
            launchAlarmActivity(
                alarmActivityIntent(title, body, stopLabel, openLabel, prayerKey),
            )
        }
        playAdhan(rawRes)
        return START_NOT_STICKY
    }

    /**
     * Starts [AdhanAlarmActivity] directly, on top of whatever the user is
     * doing.
     *
     * The full-screen intent alone is not enough: Android only auto-launches an
     * FSI Activity when the screen is off or locked — with the device unlocked
     * and in use it deliberately degrades to a heads-up notification, so the
     * adhan screen never appears "over apps". A direct start is normally blocked
     * by the Android 10+ background-activity-start rules, but holding
     * SYSTEM_ALERT_WINDOW ("Display over other apps") is a documented exemption,
     * and it's also the flag Xiaomi/Oppo/Vivo check before allowing a background
     * launch at all.
     *
     * Gated on the permission being actually granted; when it isn't, this is a
     * no-op and the full-screen-intent notification stays the only path (which
     * still covers the screen-off / locked case). Never fatal — the audio and
     * the notification are already running by this point.
     */
    private fun launchAlarmActivity(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            !Settings.canDrawOverlays(this)
        ) {
            return
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Background start refused by the OS/OEM — the full-screen-intent
            // notification remains as the fallback.
        }
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

    /**
     * Resolves a raw resource name, falling back to the non-Fajr recording when
     * a `_fajr` variant isn't bundled.
     *
     * Fajr sound names carry a `_fajr` stem (`adhan_makkah_fajr_full`). A build
     * that ships the Dart side without the matching raw would otherwise hit the
     * `resId == 0` path below and go completely silent at Fajr — the one prayer
     * where a missed alarm actually costs the user a prayer. Dropping the
     * suffix gives them the daytime adhan instead of nothing.
     */
    private fun resolveRaw(rawRes: String): Int {
        val direct = resources.getIdentifier(rawRes, "raw", packageName)
        if (direct != 0 || !rawRes.contains("_fajr")) return direct
        val fallback = rawRes.replace("_fajr", "")
        return resources.getIdentifier(fallback, "raw", packageName)
    }

    private fun playAdhan(rawRes: String) {
        releasePlayer()
        val resId = resolveRaw(rawRes)
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
        startFlipToSilence()
    }

    /**
     * Starts watching the accelerometer so turning the phone face-down silences
     * the adhan, the same way the Stop action does.
     *
     * Cheap to run: it only lives for the length of one adhan, and the service
     * already holds a partial wake lock through [MediaPlayer.setWakeMode], so
     * events keep arriving with the screen off. A device with no accelerometer
     * simply keeps the notification and full-screen Stop buttons.
     */
    private fun startFlipToSilence() {
        val sm = getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return
        val accelerometer = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        flipArmed = false
        faceDownSince = 0L
        sensors = sm
        // SENSOR_DELAY_UI (~60ms) is far finer than this needs, but it is the
        // slowest rate the platform guarantees to keep delivering promptly; the
        // hold below — not the sample rate — is what debounces the gesture.
        try {
            sm.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
        } catch (e: Exception) {
            sensors = null
        }
    }

    private fun stopFlipToSilence() {
        try {
            sensors?.unregisterListener(this)
        } catch (e: Exception) {
            // Nothing to do — the service is going away regardless.
        }
        sensors = null
        flipArmed = false
        faceDownSince = 0L
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    /**
     * Face-down detection off the Z axis, which reads about +9.8 with the screen
     * up, 0 on edge, and about -9.8 with the screen down.
     *
     * The two thresholds are deliberately far apart: anything above [FACE_UP_Z]
     * re-arms the gesture, anything below [FACE_DOWN_Z] counts as face-down, and
     * the band between them changes nothing. That hysteresis keeps a phone
     * resting near the boundary — or wobbling as it is set down — from flickering
     * between the two states. The adhan is only cut once the device has *stayed*
     * face-down for [FACE_DOWN_HOLD_MS], so brushing past that angle while
     * picking the phone up cannot stop the call to prayer by accident.
     */
    override fun onSensorChanged(event: SensorEvent?) {
        val z = event?.values?.getOrNull(2) ?: return

        if (z >= FACE_UP_Z) {
            flipArmed = true
            faceDownSince = 0L
            return
        }
        if (z > FACE_DOWN_Z) return

        if (!flipArmed) return
        val now = SystemClock.elapsedRealtime()
        if (faceDownSince == 0L) {
            faceDownSince = now
            return
        }
        if (now - faceDownSince >= FACE_DOWN_HOLD_MS) stopEverything()
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

    /**
     * The single exit path: normal completion, the Stop action, the swipe-away
     * delete intent, flip-to-silence, the full-screen alarm's dismiss, and every
     * playback setup failure all land here. Restoring the ALARM volume first
     * means it is put back even if the teardown below throws.
     */
    private fun stopEverything() {
        AdhanAlarmVolume.restoreIfPending(this)
        stopFlipToSilence()
        releasePlayer()
        // Tells a visible AdhanAlarmActivity to dismiss itself, whether the
        // adhan finished on its own or was stopped from the notification.
        sendBroadcast(Intent(ACTION_FINISHED).setPackage(packageName))
        clearCompanionNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    /**
     * Removes the Dart-scheduled adhan notification for this prayer.
     *
     * Two notifications exist at prayer time: the one this service posts (which
     * `stopForeground(STOP_FOREGROUND_REMOVE)` takes down) and the companion
     * `AdhanScheduler` scheduled through flutter_local_notifications, posted
     * under the SAME integer id and no tag. Stopping the adhan has to clear both
     * or the user silences the audio and still finds an adhan alert waiting in
     * the notification centre.
     */
    private fun clearCompanionNotification() {
        if (alarmId == 0) return
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(alarmId)
        } catch (e: Exception) {
            // Never let tray cleanup keep the service alive.
        }
    }

    override fun onDestroy() {
        // Backstop for the paths stopEverything never sees — the system
        // reclaiming the service, or a task-swipe that tears it down directly.
        // A no-op when stopEverything already restored.
        AdhanAlarmVolume.restoreIfPending(this)
        stopFlipToSilence()
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
        // Android 14 lets the user swipe away an ongoing foreground-service
        // notification (setOngoing no longer prevents it). Without a delete
        // intent the adhan then keeps playing with its only stop control gone,
        // so dismissal is treated exactly like tapping Stop. A distinct request
        // code keeps it from colliding with stopPi's PendingIntent.
        val dismissPi = PendingIntent.getService(
            this,
            4,
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
            .setDeleteIntent(dismissPi)
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

        /** Z (m/s²) at or below which the device counts as screen-down. */
        private const val FACE_DOWN_Z = -8.0f

        /** Z at or above which the gesture re-arms — roughly on edge or higher. */
        private const val FACE_UP_Z = -4.0f

        /** How long the device must stay face-down before the adhan is cut. */
        private const val FACE_DOWN_HOLD_MS = 700L
    }
}
