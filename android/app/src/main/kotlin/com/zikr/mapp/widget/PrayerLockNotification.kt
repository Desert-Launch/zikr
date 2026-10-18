package com.zikr.mapp.widget

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Typeface
import android.os.Build
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.zikr.mapp.R

/**
 * The opt-in "prayer times on the lock screen": an ongoing notification that
 * mirrors the home widget.
 *
 * Android gives apps no way to place a widget on the lock screen, so this is
 * what pins the next prayer there. It is ongoing, so it can't be swiped away
 * while the device is locked (Android 14+ lets the user dismiss it once
 * unlocked — see [onDismissed]); and public, so a lock screen set to hide
 * sensitive content still shows it in full.
 *
 * It is driven entirely by [PrayerWidgetProvider]: the same snapshot, the same
 * boundary alarm (the next salah or midnight), the same boot/clock/zone
 * broadcasts, and the same `APPWIDGET_UPDATE` the app sends after publishing a
 * snapshot. It needs none of the widget's minute ticks — the countdown is a
 * system chronometer that keeps running between posts.
 *
 * Whether it is on lives here, in native preferences, rather than in Hive: the
 * provider has to know it at boot and from its alarms, with no Flutter engine
 * around. The app reads and writes it through [PrayerLockScreenPlugin].
 */
object PrayerLockNotification {
    const val ACTION_DISMISSED = "com.zikr.mapp.widget.PRAYER_LOCK_DISMISSED"

    private const val CHANNEL_ID = "prayer_lock_screen"
    private const val NOTIFICATION_ID = 930_100
    private const val REQUEST_DISMISSED = 930_003

    private const val PREFS = "prayer_lock_screen"
    private const val KEY_ENABLED = "enabled"

    /** Set by a swipe-away: the notification stays down until this instant, the next salah. */
    private const val KEY_HIDDEN_UNTIL = "hidden_until"

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    /** Stores the switch. A fresh choice also clears any swipe-away still holding it back. */
    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).remove(KEY_HIDDEN_UNTIL).apply()
    }

    /**
     * Whether a post would be seen at all: notifications allowed for the app,
     * and this channel not switched off in system settings. A channel not
     * created yet counts as showable — creating it is part of the first post.
     */
    fun canShow(context: Context): Boolean {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        val channel = context.getSystemService(NotificationManager::class.java)
            ?.getNotificationChannel(CHANNEL_ID)
            ?: return true
        return channel.importance != NotificationManager.IMPORTANCE_NONE
    }

    /**
     * Posts the notification for [nowMillis], or updates the one showing.
     * Holds off while a swipe-away is in force. With no usable snapshot it
     * shows the widget's "open the app" line rather than vanishing, so the
     * user can see why it went quiet.
     */
    fun post(
        context: Context,
        snapshot: PrayerWidgetSnapshot?,
        resolution: PrayerWidgetSnapshot.Resolution?,
        nowMillis: Long,
    ) {
        val prefs = prefs(context)
        val hiddenUntil = prefs.getLong(KEY_HIDDEN_UNTIL, 0L)
        if (nowMillis < hiddenUntil) return
        if (hiddenUntil != 0L) prefs.edit().remove(KEY_HIDDEN_UNTIL).apply()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            // Revoked since it was switched on. Nothing can show until it is
            // granted back; the next refresh tries again.
            return
        }
        ensureChannel(context)
        val notification = if (snapshot == null || resolution == null) {
            empty(context, snapshot)
        } else {
            build(context, snapshot, resolution, nowMillis)
        }
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /**
     * The user swiped it away (Android 14+, unlocked). Respect that until the
     * next salah: the boundary alarm lands then and [post] brings it back.
     */
    fun onDismissed(context: Context) {
        if (!isEnabled(context)) return
        val next = PrayerWidgetSnapshot.load(context)
            ?.resolve(System.currentTimeMillis())
            ?.next
            ?: return
        prefs(context).edit().putLong(KEY_HIDDEN_UNTIL, next.at).apply()
    }

    private fun build(
        context: Context,
        snapshot: PrayerWidgetSnapshot,
        resolution: PrayerWidgetSnapshot.Resolution,
        nowMillis: Long,
    ): Notification {
        val labels = snapshot.labels
        val next = resolution.next
        val title = "${labels.nextName.replace("{{name}}", labels.prayer(next.key))} · ${next.label}"
        val caption = if (resolution.isShowingTomorrow) {
            "${labels.caption} · ${labels.tomorrow}"
        } else {
            labels.caption
        }
        // The line under the salah; a snapshot without a Hijri date keeps the
        // caption there rather than leaving the line blank.
        val subtitle = resolution.today.hijri.ifEmpty { caption }
        val direction = if (snapshot.rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR

        val big = RemoteViews(context.packageName, R.layout.notification_prayer_lock_big)
        big.setInt(R.id.lock_big_root, "setLayoutDirection", direction)
        big.removeAllViews(R.id.lock_head)
        big.addView(R.id.lock_head, head(context, direction, title, subtitle, next.at, nowMillis))
        big.setTextViewText(R.id.lock_date, "${resolution.today.gregorian} · $caption")
        big.removeAllViews(R.id.lock_chips)
        for (slot in resolution.chips) {
            val isNext = slot.key == next.key && slot.at == next.at
            val chip = RemoteViews(context.packageName, R.layout.notification_prayer_lock_chip)
            chip.setTextViewText(R.id.lock_chip_emoji, PrayerWidgetRenderer.chipEmoji[slot.key] ?: "")
            chip.setTextViewText(R.id.lock_chip_name, emphasised(labels.prayer(slot.key), isNext))
            chip.setTextViewText(R.id.lock_chip_time, emphasised(slot.label, isNext))
            big.addView(R.id.lock_chips, chip)
        }

        return builder(context)
            // What a surface that skips custom views shows (a paired watch,
            // an OEM's compact lock-screen style).
            .setContentTitle(title)
            .setContentText(subtitle)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(head(context, direction, title, subtitle, next.at, nowMillis))
            .setCustomBigContentView(big)
            .build()
    }

    /**
     * The collapsed view, which is also the head of the expanded one: the next
     * salah and its time over [subtitle] (today's Hijri date), the countdown
     * beside them.
     */
    private fun head(
        context: Context,
        direction: Int,
        title: String,
        subtitle: String,
        nextAt: Long,
        nowMillis: Long,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.notification_prayer_lock)
        views.setInt(R.id.lock_root, "setLayoutDirection", direction)
        views.setTextViewText(R.id.lock_next, title)
        views.setTextViewText(R.id.lock_hijri, subtitle)
        // A chronometer counts on elapsed-realtime, not the wall clock; a clock
        // or zone change re-posts through the provider's broadcasts.
        val base = SystemClock.elapsedRealtime() + (nextAt - nowMillis)
        views.setChronometer(R.id.lock_countdown, base, null, true)
        views.setChronometerCountDown(R.id.lock_countdown, true)
        return views
    }

    private fun empty(context: Context, snapshot: PrayerWidgetSnapshot?): Notification {
        val text = snapshot?.labels?.empty?.takeIf { it.isNotEmpty() }
            ?: context.getString(R.string.prayer_widget_empty)
        return builder(context)
            .setContentTitle(context.getString(R.string.prayer_widget_label))
            .setContentText(text)
            .build()
    }

    private fun builder(context: Context): NotificationCompat.Builder =
        NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setLocalOnly(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(PrayerWidgetRenderer.launchIntent(context))
            .setDeleteIntent(dismissedIntent(context))

    /**
     * Default importance, made silent by stripping its sound and vibration.
     * Not LOW: lock screens can be set to hide "silent" notifications — and on
     * some devices that is the default — which by the OS's definition means
     * importance LOW and below. Importance is frozen once the channel exists,
     * so this is decided here, once.
     */
    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.prayer_lock_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.prayer_lock_channel_description)
            setSound(null, null)
            enableVibration(false)
            enableLights(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(channel)
    }

    private fun dismissedIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerWidgetProvider::class.java).setAction(ACTION_DISMISSED)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_DISMISSED,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun emphasised(text: String, bold: Boolean): CharSequence {
        if (!bold) return text
        return SpannableString(text).apply {
            setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
