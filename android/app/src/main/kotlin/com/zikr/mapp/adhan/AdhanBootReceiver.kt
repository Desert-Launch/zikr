package com.zikr.mapp.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.zikr.mapp.reminder.ReminderSoundScheduler

/**
 * Re-arms the persisted adhan audio alarms after a reboot or app update — the
 * OS clears all pending alarms on boot, so without this the full-adhan auto-play
 * would silently stop working until the user next opened the app.
 *
 * The reminder-sound alarms (salawat "remind while silenced") ride along for the
 * same reason, from their own separate mirror.
 */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> {
                // A device powered off mid-adhan never ran the service's
                // restore, and stream volumes survive a reboot — so the user
                // would come back to a permanently raised alarm slider. This is
                // the earliest point at which that can be undone.
                AdhanAlarmVolume.restoreIfPending(context)
                AdhanAlarmScheduler.reArmAll(context)
                ReminderSoundScheduler.reArmAll(context)
            }
        }
    }
}
