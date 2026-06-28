package com.zikr.mapp.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Fired by [AdhanAlarmScheduler]'s exact alarm at a prayer time. Starts the
 * foreground [AdhanPlaybackService] to play the full adhan, then forgets the
 * just-fired alarm so a later reboot re-arm doesn't replay a past prayer.
 */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(AdhanAlarmScheduler.EXTRA_ID, 0)
        val service = Intent(context, AdhanPlaybackService::class.java).apply {
            putExtra(AdhanAlarmScheduler.EXTRA_ID, id)
            putExtra(AdhanAlarmScheduler.EXTRA_RAW, intent.getStringExtra(AdhanAlarmScheduler.EXTRA_RAW))
            putExtra(AdhanAlarmScheduler.EXTRA_TITLE, intent.getStringExtra(AdhanAlarmScheduler.EXTRA_TITLE))
            putExtra(AdhanAlarmScheduler.EXTRA_BODY, intent.getStringExtra(AdhanAlarmScheduler.EXTRA_BODY))
            putExtra(AdhanAlarmScheduler.EXTRA_STOP, intent.getStringExtra(AdhanAlarmScheduler.EXTRA_STOP))
        }
        // Starting an FGS from an exact-alarm broadcast is an allowed background
        // start (the "alarms & timers" exemption) on Android 12+.
        ContextCompat.startForegroundService(context, service)
        AdhanAlarmScheduler.cancel(context, id)
    }
}
