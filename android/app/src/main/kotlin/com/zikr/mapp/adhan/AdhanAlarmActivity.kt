package com.zikr.mapp.adhan

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import com.zikr.mapp.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The unmissable full-screen alarm shown at prayer time — over the lockscreen,
 * from a killed app, with the screen turned on.
 *
 * Launched by [AdhanPlaybackService]'s full-screen-intent notification, which is
 * the only reliable way to start an Activity from the background on Android 10+.
 * The service owns the audio; this Activity is purely the UI and the two
 * controls (Stop / Open app). It finishes itself when the service broadcasts
 * [AdhanPlaybackService.ACTION_FINISHED] — i.e. when the adhan completes or is
 * stopped from the notification instead.
 *
 * Deliberately plain-framework (`android.app.Activity` + a static XML layout)
 * rather than Flutter: at fire time from a cold process, spinning up a
 * FlutterEngine costs seconds the user is staring at a black screen, and it can
 * fail outright under memory pressure. The in-app Flutter equivalent
 * (`SNAdhanRinging`) covers the case where the app is already foregrounded.
 */
class AdhanAlarmActivity : Activity() {

    /** Finishes this screen when the service stops the adhan by any other route. */
    private val finishReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            finishAndRemoveTask()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockscreen()
        setContentView(R.layout.activity_adhan_alarm)

        val title = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_TITLE).orEmpty()
        val body = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_BODY).orEmpty()
        val stopLabel = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_STOP) ?: "إيقاف"
        val openLabel = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_OPEN) ?: "فتح التطبيق"

        // App name + launcher icon, read from ApplicationInfo so this screen
        // never carries a second copy of the branding to keep in sync.
        findViewById<ImageView>(R.id.adhan_alarm_logo)
            .setImageDrawable(applicationInfo.loadIcon(packageManager))
        findViewById<TextView>(R.id.adhan_alarm_app).text =
            applicationInfo.loadLabel(packageManager)

        findViewById<TextView>(R.id.adhan_alarm_title).text = title
        findViewById<TextView>(R.id.adhan_alarm_body).text = body
        findViewById<TextView>(R.id.adhan_alarm_clock).text =
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())

        findViewById<TextView>(R.id.adhan_alarm_stop).apply {
            text = stopLabel
            setOnClickListener { stopAdhan() }
        }
        findViewById<TextView>(R.id.adhan_alarm_open).apply {
            text = openLabel
            setOnClickListener { openApp() }
        }

        // Android 14 requires an explicit export flag for runtime receivers.
        // Kept on the platform API rather than ContextCompat so the build
        // doesn't depend on a particular androidx.core version.
        val filter = IntentFilter(AdhanPlaybackService.ACTION_FINISHED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(finishReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(finishReceiver, filter)
        }
    }

    /**
     * Turns the screen on and draws above the keyguard. The API 27+ calls are
     * the supported path; the window flags are the pre-27 equivalent and are
     * deprecated but still required there.
     */
    private fun showOverLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            // Dismisses only a swipe keyguard; a secure lock stays up and the
            // Activity simply renders on top of it, which is what we want.
            km?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun stopAdhan() {
        startService(
            Intent(this, AdhanPlaybackService::class.java).apply {
                action = AdhanPlaybackService.ACTION_STOP
            },
        )
        finishAndRemoveTask()
    }

    /** Stops the audio, then deep-links into the app's prayer screen. */
    private fun openApp() {
        val prayerKey = intent?.getStringExtra(AdhanAlarmScheduler.EXTRA_PRAYER).orEmpty()
        startService(
            Intent(this, AdhanPlaybackService::class.java).apply {
                action = AdhanPlaybackService.ACTION_STOP
            },
        )
        packageManager.getLaunchIntentForPackage(packageName)?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            it.putExtra(AdhanAlarmScheduler.EXTRA_PRAYER, prayerKey)
            startActivity(it)
        }
        finishAndRemoveTask()
    }

    /**
     * Back must not silently dismiss the adhan while it keeps playing behind a
     * screen the user can no longer reach — treat it as Stop.
     */
    @Deprecated("Framework Activity has no onBackPressedDispatcher; behaviour is intentional")
    override fun onBackPressed() {
        stopAdhan()
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(finishReceiver)
        } catch (e: IllegalArgumentException) {
            // Already unregistered — nothing to undo.
        }
        super.onDestroy()
    }
}
