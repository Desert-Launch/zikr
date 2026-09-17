package com.zikr.mapp.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home-screen prayer widget.
 *
 * Everything it draws comes from the snapshot Dart publishes through
 * `home_widget` ([PrayerWidgetSnapshot]); everything about *when* it redraws
 * is decided here:
 *
 *  - the launcher's own `APPWIDGET_UPDATE` (add, resize, the 30-minute
 *    backstop, and the app's `HomeWidget.updateWidget` after a new snapshot);
 *  - [PrayerWidgetAlarms]' minute tick and prayer/midnight boundary;
 *  - boot, package replacement, and a timezone or clock change.
 *
 * Every path ends in [refresh], which renders all instances and re-arms the
 * alarms from what it just drew. No Flutter engine is involved at any point.
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
        PrayerWidgetAlarms.cancelAll(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            PrayerWidgetAlarms.ACTION_TICK,
            PrayerWidgetAlarms.ACTION_BOUNDARY,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            -> refreshAll(context)
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        /** Redraws every placed instance (a no-op when there are none). */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
            refresh(context, manager, ids)
        }

        private fun refresh(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) {
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

            if (snapshot == null || resolution == null) {
                // Nothing to count down to. The app's next publish redraws us.
                PrayerWidgetAlarms.cancelAll(context)
                return
            }
            PrayerWidgetAlarms.armBoundary(
                context,
                minOf(resolution.next.at, snapshot.nextMidnight(now)),
            )
            PrayerWidgetAlarms.armTick(context, now)
        }
    }
}
