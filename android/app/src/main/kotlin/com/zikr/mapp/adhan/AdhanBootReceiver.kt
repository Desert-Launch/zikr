package com.zikr.mapp.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the persisted adhan audio alarms after a reboot or app update — the
 * OS clears all pending alarms on boot, so without this the full-adhan auto-play
 * would silently stop working until the user next opened the app.
 */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> AdhanAlarmScheduler.reArmAll(context)
        }
    }
}
