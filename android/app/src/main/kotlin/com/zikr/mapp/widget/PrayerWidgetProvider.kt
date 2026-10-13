package com.zikr.mapp.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home-screen prayer widget — and the driver of its lock-screen twin,
 * [PrayerLockNotification], which mirrors the same snapshot.
 *
 * Everything they draw comes from the snapshot Dart publishes through
 * `home_widget` ([PrayerWidgetSnapshot]); everything about *when* they redraw
 * is decided here:
 *
 *  - the launcher's own `APPWIDGET_UPDATE` (add, resize, the 30-minute
 *    backstop, and the app's `HomeWidget.updateWidget` after a new snapshot);
 *  - [PrayerWidgetAlarms]' minute tick and prayer/midnight boundary;
 *  - boot, package replacement, and a timezone or clock change.
 *
 * Every path ends in [refresh], which renders all instances, posts the
 * notification when it is on, and re-arms the alarms from what it just drew.
 * No Flutter engine is involved at any point.
 */
class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        refresh(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        refresh(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onEnabled(context: Context) {
        // First instance placed: the launcher's onUpdate follows and arms the
        // alarms from a real render; nothing to do ahead of it.
    }

    override fun onDisabled(context: Context) {
        // Last instance removed — a phone without the widget must not tick.
        // The boundary stays only while the lock-screen notification needs it.
        PrayerWidgetAlarms.cancelTick(context)
        if (!PrayerLockNotification.isEnabled(context)) PrayerWidgetAlarms.cancelBoundary(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            // The notification's countdown runs on its own; re-posting it
            // every minute would buy nothing.
            PrayerWidgetAlarms.ACTION_TICK -> refreshAll(context, repostLockScreen = false)
            PrayerWidgetAlarms.ACTION_BOUNDARY,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            -> refreshAll(context)
            PrayerLockNotification.ACTION_DISMISSED -> PrayerLockNotification.onDismissed(context)
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                super.onReceive(context, intent)
                // With no instance placed the framework skips onUpdate, but a
                // new snapshot still has to reach the lock-screen notification.
                val ids = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                if (ids == null || ids.isEmpty()) refreshAll(context)
            }
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        /**
         * Redraws every placed instance and, unless [repostLockScreen] is
         * false, brings the lock-screen notification in line. A no-op apart
         * from cancelling alarms when neither is in use.
         */
        fun refreshAll(context: Context, repostLockScreen: Boolean = true) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
            refresh(context, manager, ids, repostLockScreen)
        }

        private fun refresh(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray,
            repostLockScreen: Boolean = true,
        ) {
            val lockScreen = PrayerLockNotification.isEnabled(context)
            if (repostLockScreen && !lockScreen) PrayerLockNotification.cancel(context)
            if (ids.isEmpty() && !lockScreen) {
                PrayerWidgetAlarms.cancelAll(context)
                return
            }
            val now = System.currentTimeMillis()
            val snapshot = PrayerWidgetSnapshot.load(context)
            val resolution = snapshot?.resolve(now)

            for (id in ids) {
                val views = PrayerWidgetRenderer.render(
                    context,
                    snapshot,
                    resolution,
                    now,
                    manager.getAppWidgetOptions(id),
                )
                manager.updateAppWidget(id, views)
            }
            if (repostLockScreen && lockScreen) {
                PrayerLockNotification.post(context, snapshot, resolution, now)
            }

            if (snapshot == null || resolution == null) {
                // Nothing to count down to. The app's next publish redraws us.
                PrayerWidgetAlarms.cancelAll(context)
                return
            }
            PrayerWidgetAlarms.armBoundary(
                context,
                minOf(resolution.next.at, snapshot.nextMidnight(now)),
            )
            if (ids.isNotEmpty()) {
                PrayerWidgetAlarms.armTick(context, now)
            } else {
                PrayerWidgetAlarms.cancelTick(context)
            }
        }
    }
}
