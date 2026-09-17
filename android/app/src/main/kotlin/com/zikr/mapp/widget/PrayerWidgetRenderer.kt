package com.zikr.mapp.widget

import android.content.Context
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.appwidget.AppWidgetManager
import android.view.View
import android.widget.RemoteViews
import com.zikr.mapp.MainActivity
import com.zikr.mapp.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Builds the [RemoteViews] for one widget instance from a resolved snapshot.
 *
 * Pure presentation: no clock reads of its own (the caller passes `now`), no
 * storage, no alarms. Everything printed is either a string from the snapshot
 * or a number derived from it.
 */
object PrayerWidgetRenderer {

    /** Where a tap goes. The `homeWidget` flag is what the plugin keys on. */
    private const val LAUNCH_URI = "zikr://prayer?homeWidget"

    /**
     * Chip disc colours, keyed by slot — the same six as the in-app card. The
     * disc is the colour at 16% over the card, blended here to an opaque value
     * so it reads correctly on both the light and the dark card.
     */
    private val chipTints = mapOf(
        "fajr" to 0xFFE2705B.toInt(),
        "sunrise" to 0xFFF2A33C.toInt(),
        "dhuhr" to 0xFFF2C037.toInt(),
        "asr" to 0xFF3FA9C4.toInt(),
        "maghrib" to 0xFFE8743B.toInt(),
        "isha" to 0xFF6C63B5.toInt(),
    )

    private val chipEmoji = mapOf(
        "fajr" to "🌅",       // 🌅
        "sunrise" to "☀️",     // ☀️
        "dhuhr" to "🌤️", // 🌤️
        "asr" to "🌥️",   // 🌥️
        "maghrib" to "🌇",     // 🌇
        "isha" to "🌙",        // 🌙
    )

    private val chipIds = arrayOf(
        intArrayOf(R.id.widget_chip_1, R.id.widget_chip_bg_1, R.id.widget_chip_emoji_1, R.id.widget_chip_label_1, R.id.widget_chip_time_1),
        intArrayOf(R.id.widget_chip_2, R.id.widget_chip_bg_2, R.id.widget_chip_emoji_2, R.id.widget_chip_label_2, R.id.widget_chip_time_2),
        intArrayOf(R.id.widget_chip_3, R.id.widget_chip_bg_3, R.id.widget_chip_emoji_3, R.id.widget_chip_label_3, R.id.widget_chip_time_3),
        intArrayOf(R.id.widget_chip_4, R.id.widget_chip_bg_4, R.id.widget_chip_emoji_4, R.id.widget_chip_label_4, R.id.widget_chip_time_4),
        intArrayOf(R.id.widget_chip_5, R.id.widget_chip_bg_5, R.id.widget_chip_emoji_5, R.id.widget_chip_label_5, R.id.widget_chip_time_5),
        intArrayOf(R.id.widget_chip_6, R.id.widget_chip_bg_6, R.id.widget_chip_emoji_6, R.id.widget_chip_label_6, R.id.widget_chip_time_6),
    )

    /**
     * Below this many dp wide the chip row is dropped; below [COMPACT_HEIGHT_DP]
     * tall, the date row too. Six chips need ~35 dp each for the 34 dp disc,
     * plus the card's 28 dp of padding.
     */
    private const val COMPACT_WIDTH_DP = 240
    private const val COMPACT_HEIGHT_DP = 100

    fun render(
        context: Context,
        snapshot: PrayerWidgetSnapshot?,
        resolution: PrayerWidgetSnapshot.Resolution?,
        nowMillis: Long,
        options: Bundle?,
    ): RemoteViews {
        if (snapshot == null || resolution == null) return empty(context, snapshot)

        val views = RemoteViews(context.packageName, R.layout.widget_prayer)
        views.setInt(
            R.id.widget_root,
            "setLayoutDirection",
            if (snapshot.rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))

        // Date row — today's, even while the chip row shows tomorrow.
        views.setTextViewText(R.id.widget_gregorian, resolution.today.gregorian)
        views.setTextViewText(R.id.widget_hijri, resolution.today.hijri)

        // Head row.
        val labels = snapshot.labels
        val caption = if (resolution.isShowingTomorrow) {
            "${labels.caption} · ${labels.tomorrow}"
        } else {
            labels.caption
        }
        views.setTextViewText(R.id.widget_caption, caption)
        views.setTextViewText(
            R.id.widget_next_name,
            labels.nextName.replace("{{name}}", labels.prayer(resolution.next.key)),
        )
        views.setTextViewText(R.id.widget_next_time, resolution.next.label)
        views.setTextViewText(R.id.widget_remaining, resolution.remaining(nowMillis, labels))

        // Progress.
        views.setProgressBar(
            R.id.widget_progress,
            1000,
            (resolution.progress(nowMillis) * 1000).toInt(),
            false,
        )

        // Chips — the display day's slots, the featured prayer included;
        // normally six, fewer only for a malformed snapshot.
        val cardColor = context.getColor(R.color.widget_card)
        for ((index, ids) in chipIds.withIndex()) {
            val slot = resolution.chips.getOrNull(index)
            if (slot == null) {
                views.setViewVisibility(ids[0], View.INVISIBLE)
                continue
            }
            views.setViewVisibility(ids[0], View.VISIBLE)
            val tint = chipTints[slot.key] ?: 0xFF9E9E9E.toInt()
            views.setInt(ids[1], "setColorFilter", blend(cardColor, tint, 0.16f))
            views.setTextViewText(ids[2], chipEmoji[slot.key] ?: "")
            views.setTextViewText(ids[3], labels.prayer(slot.key))
            views.setTextViewText(ids[4], slot.label)
        }

        applySize(views, options)
        return views
    }

    /** The "open the app" card. */
    fun empty(context: Context, snapshot: PrayerWidgetSnapshot?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer_empty)
        val rtl = snapshot?.rtl ?: true
        views.setInt(
            R.id.widget_root,
            "setLayoutDirection",
            if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
        )
        // Prefer the snapshot's own copy (the app's language); the resource is
        // the fallback for a phone that has never had a snapshot at all.
        val text = snapshot?.labels?.empty?.takeIf { it.isNotEmpty() }
            ?: context.getString(R.string.prayer_widget_empty)
        views.setTextViewText(R.id.widget_empty_text, text)
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
        return views
    }

    /**
     * Hides rows that cannot fit the cell the launcher gave us. Sizes arrive
     * in dp through the widget options bundle; absent (older launchers) the
     * full layout is kept.
     */
    private fun applySize(views: RemoteViews, options: Bundle?) {
        if (options == null) return
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        if (minWidth in 1 until COMPACT_WIDTH_DP) {
            views.setViewVisibility(R.id.widget_chips, View.GONE)
        }
        if (minHeight in 1 until COMPACT_HEIGHT_DP) {
            views.setViewVisibility(R.id.widget_chips, View.GONE)
            views.setViewVisibility(R.id.widget_date_row, View.GONE)
        }
    }

    private fun launchIntent(context: Context) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(LAUNCH_URI))

    /** [tint] at [ratio] over [base], as an opaque colour. */
    private fun blend(base: Int, tint: Int, ratio: Float): Int {
        val inverse = 1f - ratio
        val r = Color.red(base) * inverse + Color.red(tint) * ratio
        val g = Color.green(base) * inverse + Color.green(tint) * ratio
        val b = Color.blue(base) * inverse + Color.blue(tint) * ratio
        return Color.rgb(r.toInt(), g.toInt(), b.toInt())
    }
}
