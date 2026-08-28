package com.zikr.mapp.adhan

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import com.zikr.mapp.R
import java.util.Calendar
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
 * Between those two points sits the du'a phase: when the adhan itself finishes
 * the service broadcasts [AdhanPlaybackService.ACTION_DUA] instead of
 * finishing, and this screen stays up with the du'a promoted from a footnote to
 * the focus of the layout until the clip has played.
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

    /** Switches this screen to the du'a once the adhan itself has finished. */
    private val duaReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            showDua()
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
        findViewById<TextView>(R.id.adhan_alarm_clock).text = clockLabel()

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
        register(finishReceiver, AdhanPlaybackService.ACTION_FINISHED)
        register(duaReceiver, AdhanPlaybackService.ACTION_DUA)

        // Opened after the du'a already began — a late notification tap, or the
        // status-bar alarm icon — so the ACTION_DUA broadcast is long gone and
        // only the service's own phase can say what is playing.
        if (AdhanPlaybackService.phase == AdhanPlaybackService.PHASE_DUA) showDua()
    }

    private fun register(receiver: BroadcastReceiver, action: String) {
        val filter = IntentFilter(action)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
    }

    /**
     * Moves the screen from "the adhan is calling" to "say the du'a": the
     * prayer heading becomes the du'a heading, the per-prayer body drops away,
     * and the du'a text appears for the first time.
     *
     * The du'a is deliberately absent until this point — while the adhan is
     * still being called, text for a supplication said *after* it is the wrong
     * instruction to be showing. Its size and spacing live in the layout rather
     * than here, since the du'a phase is the only state that view is ever seen
     * in.
     *
     * Nothing else changes. Both controls keep working exactly as before, so
     * Stop still cuts the audio and closes the screen mid-du'a.
     */
    private fun showDua() {
        findViewById<TextView>(R.id.adhan_alarm_title).text =
            getString(R.string.adhan_alarm_dua_title)
        findViewById<TextView>(R.id.adhan_alarm_body).visibility = View.GONE
        findViewById<TextView>(R.id.adhan_alarm_dua).visibility = View.VISIBLE
    }

    /**
     * The fire time as a 12-hour clock with an Arabic meridiem — "05:14 ص" —
     * mirroring `TimeFormat.hm12` (lib/core/utils/helper/time_format.dart), the
     * shared Dart formatter every prayer time in the app already goes through.
     * A 24-hour "17:14" here would contradict the time the user saw on the
     * prayer screen minutes earlier.
     *
     * Built by hand rather than with SimpleDateFormat("hh:mm a"): that follows
     * the DEVICE locale, which is not the app locale — an Arabic app on an
     * English phone would read "PM", and an Arabic phone would render
     * Arabic-Indic digits nothing else in this app uses. Latin digits with a
     * fixed ص/م is what the Dart helper does, so it is what this does.
     */
    private fun clockLabel(): String {
        val now = Calendar.getInstance()
        val hour24 = now.get(Calendar.HOUR_OF_DAY)
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val meridiem = if (hour24 >= 12) "م" else "ص"
        return String.format(Locale.US, "%02d:%02d %s", hour12, now.get(Calendar.MINUTE), meridiem)
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
        for (receiver in arrayOf(finishReceiver, duaReceiver)) {
            try {
                unregisterReceiver(receiver)
            } catch (e: IllegalArgumentException) {
                // Already unregistered — nothing to undo.
            }
        }
        super.onDestroy()
    }
}
