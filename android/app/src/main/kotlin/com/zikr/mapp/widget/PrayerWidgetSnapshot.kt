package com.zikr.mapp.widget

import android.content.Context
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * The `prayer_widget_v1` snapshot Dart publishes through `home_widget`, and the
 * clock arithmetic the widget does over it.
 *
 * The widget runs with no Flutter engine, so everything it prints has to be in
 * here already: every timing is an epoch instant paired with the string the
 * app would show for it, every label is pre-localised, and the Hijri and
 * Gregorian dates are pre-formatted per day. What is left for this class is
 * to pick rows against the clock — which salah is next, which window we are
 * inside, whether the chip row should have rolled into tomorrow — using the
 * same rules as the app's `UCGetNextPrayer` and `SPrayerTimes`, so the widget
 * and the home card can never disagree.
 *
 * The shape is documented in `docs/plans/Prayer_Home_Widget_Plan.md` §3 and
 * built by `MPrayerWidgetSnapshot` on the Dart side.
 */
class PrayerWidgetSnapshot private constructor(
    val lang: String,
    val rtl: Boolean,
    val zone: ZoneId,
    val city: String,
    val labels: Labels,
    val days: List<Day>,
) {
    class Slot(val key: String, val at: Long, val label: String) {
        /** Sunrise is listed but is not a salah: never "next", never a window start. */
        val isSalah: Boolean get() = key != "sunrise"
    }

    class Day(val date: LocalDate, val gregorian: String, val hijri: String, val slots: List<Slot>)

    class Labels(
        val caption: String,
        val nextName: String,
        val remainingHm: String,
        val remaining1Hm: String,
        val remainingM: String,
        val tomorrow: String,
        val empty: String,
        private val prayers: Map<String, String>,
    ) {
        fun prayer(key: String): String = prayers[key] ?: key
    }

    /** What the widget shows for one instant. */
    class Resolution(
        /** Today in the location's zone. */
        val today: Day,
        /** Today until its last salah has gone, then tomorrow. */
        val displayDay: Day,
        val next: Slot,
        /** The salah whose window we are inside; null only before the earliest one known. */
        val windowStart: Long?,
        /** [displayDay]'s six slots, [next] included — the row under the bar. */
        val chips: List<Slot>,
    ) {
        val isShowingTomorrow: Boolean get() = displayDay !== today

        /** Fraction of the current window elapsed at [now], 0..1. */
        fun progress(now: Long): Float {
            val start = windowStart ?: return 0f
            val total = next.at - start
            if (total <= 0) return 0f
            return ((now - start).toFloat() / total).coerceIn(0f, 1f)
        }

        /** `بعد ساعة و 15 دقيقة` — minutes rounded up, so the last minute reads "1", not "0". */
        fun remaining(now: Long, labels: Labels): String {
            val minutes = ((next.at - now + 59_999L) / 60_000L).coerceAtLeast(0L).toInt()
            val h = minutes / 60
            val m = minutes % 60
            return when {
                h <= 0 -> labels.remainingM.replace("{{m}}", m.toString())
                h == 1 -> labels.remaining1Hm.replace("{{m}}", m.toString())
                else -> labels.remainingHm.replace("{{h}}", h.toString()).replace("{{m}}", m.toString())
            }
        }
    }

    /**
     * Resolves the widget's content for [nowMillis], or null when the snapshot
     * has nothing usable — no row for today, or every known salah has passed —
     * in which case the widget shows its empty state rather than a stale one.
     */
    fun resolve(nowMillis: Long): Resolution? {
        val today = todayOn(nowMillis) ?: return null
        val todayIndex = days.indexOf(today)

        var next: Slot? = null
        var windowStart: Long? = null
        for (day in days) {
            for (slot in day.slots) {
                if (!slot.isSalah) continue
                if (slot.at > nowMillis) {
                    if (next == null) next = slot
                } else {
                    windowStart = slot.at
                }
            }
            if (next != null) break
        }
        val resolvedNext = next ?: return null

        val hasSalahLeft = today.slots.any { it.isSalah && it.at > nowMillis }
        val displayDay = if (hasSalahLeft) today else days.getOrNull(todayIndex + 1) ?: today

        return Resolution(
            today = today,
            displayDay = displayDay,
            next = resolvedNext,
            windowStart = windowStart,
            chips = displayDay.slots,
        )
    }

    /** The calendar day of [nowMillis] **in the location's zone**, if the snapshot has it. */
    fun todayOn(nowMillis: Long): Day? {
        val date = Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()
        return days.firstOrNull { it.date == date }
    }

    /** The next local midnight after [nowMillis] — when the date row changes. */
    fun nextMidnight(nowMillis: Long): Long {
        val local: ZonedDateTime = Instant.ofEpochMilli(nowMillis).atZone(zone)
        return local.toLocalDate().plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
    }

    companion object {
        /** `home_widget`'s SharedPreferences file and the key Dart writes. */
        private const val PREFS = "HomeWidgetPreferences"
        const val KEY = "prayer_widget_v1"
        private const val VERSION = 1

        fun load(context: Context): PrayerWidgetSnapshot? {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            return parse(raw)
        }

        /** Null for a missing, malformed or newer-versioned snapshot — never throws. */
        fun parse(raw: String?): PrayerWidgetSnapshot? {
            if (raw.isNullOrEmpty()) return null
            return try {
                val json = JSONObject(raw)
                if (json.optInt("v", 0) != VERSION) return null
                val labelsJson = json.getJSONObject("labels")
                val prayersJson = labelsJson.optJSONObject("prayers")
                val prayers = HashMap<String, String>()
                prayersJson?.keys()?.forEach { key -> prayers[key] = prayersJson.getString(key) }
                val labels = Labels(
                    caption = labelsJson.optString("caption"),
                    nextName = labelsJson.optString("nextName", "{{name}}"),
                    remainingHm = labelsJson.optString("remainingHm"),
                    remaining1Hm = labelsJson.optString("remaining1Hm", labelsJson.optString("remainingHm")),
                    remainingM = labelsJson.optString("remainingM"),
                    tomorrow = labelsJson.optString("tomorrow"),
                    empty = labelsJson.optString("empty"),
                    prayers = prayers,
                )
                val daysJson = json.getJSONArray("days")
                val days = ArrayList<Day>(daysJson.length())
                for (i in 0 until daysJson.length()) {
                    val dayJson = daysJson.getJSONObject(i)
                    val slotsJson = dayJson.getJSONArray("slots")
                    val slots = ArrayList<Slot>(slotsJson.length())
                    for (j in 0 until slotsJson.length()) {
                        val slotJson = slotsJson.getJSONObject(j)
                        slots.add(
                            Slot(
                                key = slotJson.getString("k"),
                                at = slotJson.getLong("at"),
                                label = slotJson.optString("t"),
                            ),
                        )
                    }
                    days.add(
                        Day(
                            date = LocalDate.parse(dayJson.getString("date")),
                            gregorian = dayJson.optString("gregorian"),
                            hijri = dayJson.optString("hijri"),
                            slots = slots,
                        ),
                    )
                }
                val zone = try {
                    ZoneId.of(json.optString("tz").ifEmpty { "UTC" })
                } catch (_: Exception) {
                    ZoneId.systemDefault()
                }
                PrayerWidgetSnapshot(
                    lang = json.optString("lang", "ar"),
                    rtl = json.optBoolean("rtl", true),
                    zone = zone,
                    city = json.optString("city"),
                    labels = labels,
                    days = days,
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
