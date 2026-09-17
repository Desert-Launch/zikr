package com.zikr.mapp.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * The alarms that keep [PrayerWidgetProvider] moving between app runs.
 *
 * Two of them, both **non-wakeup** (`RTC`, never `RTC_WAKEUP`): a widget is
 * only ever looked at with the screen on, so there is nothing to gain from
 * waking a sleeping device to redraw it. A non-wakeup alarm that comes due
 * while the device sleeps is delivered the moment it wakes — before the
 * launcher has finished drawing — which is exactly when the redraw matters.
 *
 *  - **Boundary** — the next moment the layout changes on its own: the next
 *    salah (the featured prayer flips) or local midnight (the date row
 *    changes), whichever is sooner.
 *  - **Tick** — once a minute, aligned to the minute, while any widget
 *    instance exists: the countdown text and the progress bar. Re-armed from
 *    every render; cancelled in `onDisabled`.
 *
 * Both are exact when the exact-alarm grant is present — this app already
 * holds it for the adhan (`USE_EXACT_ALARM` on 13+, `SCHEDULE_EXACT_ALARM`
 * on 12) — and fall back to inexact windows otherwise. On Android 12+ an
 * inexact window is stretched to ten minutes, so without the grant the
 * countdown can read up to ten minutes behind; the absolute time beside it
 * is always right, which is why it is the larger of the two.
 */
object PrayerWidgetAlarms {
    const val ACTION_TICK = "com.zikr.mapp.widget.PRAYER_TICK"
    const val ACTION_BOUNDARY = "com.zikr.mapp.widget.PRAYER_BOUNDARY"

    private const val REQUEST_TICK = 930_001
    private const val REQUEST_BOUNDARY = 930_002

    private const val MINUTE = 60_000L

    /** Arms the boundary alarm at [atMillis] (a second past, so the salah is strictly in the past when we redraw). */
    fun armBoundary(context: Context, atMillis: Long) {
        arm(context, pending(context, ACTION_BOUNDARY, REQUEST_BOUNDARY), atMillis + 1_000L)
    }

    /** Arms the next minute tick, a second past the minute so the countdown has already turned. */
    fun armTick(context: Context, nowMillis: Long) {
        val nextMinute = (nowMillis / MINUTE + 1) * MINUTE + 1_000L
        arm(context, pending(context, ACTION_TICK, REQUEST_TICK), nextMinute)
    }

    fun cancelAll(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pending(context, ACTION_TICK, REQUEST_TICK))
        am.cancel(pending(context, ACTION_BOUNDARY, REQUEST_BOUNDARY))
    }

    private fun arm(context: Context, operation: PendingIntent, atMillis: Long) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (canScheduleExact(am)) {
            try {
                am.setExact(AlarmManager.RTC, atMillis, operation)
                return
            } catch (_: SecurityException) {
                // The grant was revoked between the check and the call.
            }
        }
        am.setWindow(AlarmManager.RTC, atMillis, MINUTE, operation)
    }

    private fun canScheduleExact(am: AlarmManager): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()

    private fun pending(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, PrayerWidgetProvider::class.java).setAction(action)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
