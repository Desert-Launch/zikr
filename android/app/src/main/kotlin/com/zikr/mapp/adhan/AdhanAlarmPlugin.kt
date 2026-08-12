package com.zikr.mapp.adhan

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge that lets Dart arm/cancel the native full-adhan alarms
 * and inspect the permissions that silently break them.
 *
 * Registered against the app's FlutterEngine in MainActivity, so it is only
 * reachable from the UI isolate (background isolates fall back to the
 * notification-sound path, which is why Dart treats MissingPluginException as a
 * no-op).
 */
class AdhanAlarmPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedule" -> {
                val id = call.argument<Int>("id")
                val trigger = call.argument<Number>("triggerAtMillis")?.toLong()
                if (id == null || trigger == null) {
                    result.error("bad_args", "id and triggerAtMillis are required", null)
                    return
                }
                AdhanAlarmScheduler.schedule(
                    context,
                    id,
                    trigger,
                    call.argument<String>("rawRes").orEmpty(),
                    call.argument<String>("title") ?: "الأذان",
                    call.argument<String>("body").orEmpty(),
                    call.argument<String>("stopLabel") ?: "إيقاف",
                    call.argument<String>("openLabel") ?: "فتح التطبيق",
                    call.argument<String>("prayerKey").orEmpty(),
                    call.argument<Boolean>("fullScreen") ?: true,
                )
                result.success(true)
            }
            "cancel" -> {
                val id = call.argument<Int>("id")
                if (id == null) {
                    result.error("bad_args", "id is required", null)
                    return
                }
                AdhanAlarmScheduler.cancel(context, id)
                result.success(true)
            }
            "cancelAll" -> {
                AdhanAlarmScheduler.cancelAll(context, intSet(call, "exceptIds"))
                result.success(true)
            }
            "canScheduleExact" -> result.success(AdhanAlarmScheduler.canScheduleExact(context))
            "permissions" -> result.success(permissions())
            // Android grants exact alarms via a settings page, not a runtime
            // prompt — Dart routes users through openOsSettings instead.
            "requestAuthorization" -> result.success(AdhanAlarmScheduler.canScheduleExact(context))
            "openOsSettings" -> result.success(openOsSettings(call.argument<String>("which")))
            "manufacturer" -> result.success(Build.MANUFACTURER.orEmpty())
            else -> result.notImplemented()
        }
    }

    /**
     * Reads an int list argument. The method channel hands lists over as
     * `List<Any?>` of boxed numbers, so `argument<List<Int>>` would compile but
     * blow up on the first element — hence the explicit narrowing. A missing or
     * malformed argument reads as "no exceptions", which is the old behaviour.
     */
    private fun intSet(call: MethodCall, name: String): Set<Int> =
        call.argument<List<*>>(name)
            ?.mapNotNull { (it as? Number)?.toInt() }
            ?.toSet()
            .orEmpty()

    private fun permissions(): Map<String, Any> = mapOf(
        "canScheduleExact" to AdhanAlarmScheduler.canScheduleExact(context),
        "canUseFullScreenIntent" to canUseFullScreenIntent(),
        "canDrawOverlays" to canDrawOverlays(),
        "isBatteryOptimized" to isBatteryOptimized(),
        "hasOemAutostartManager" to (oemAutostartIntent() != null),
    )

    /**
     * "Display over other apps". Without it the adhan screen can only appear
     * when the device is locked or the screen is off (the full-screen-intent
     * path); with it, [AdhanPlaybackService] can launch the alarm Activity
     * directly over whatever app is in front.
     */
    private fun canDrawOverlays(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return Settings.canDrawOverlays(context)
    }

    /**
     * Android 14 (API 34) made USE_FULL_SCREEN_INTENT a user-revocable grant for
     * apps that aren't calling/alarm apps. Without it the alarm degrades to a
     * heads-up notification instead of the lockscreen Activity.
     */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.canUseFullScreenIntent()
    }

    /** True while the OS may still defer our alarms to save battery. */
    private fun isBatteryOptimized(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return !pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    /**
     * Opens the settings page for [which], trying each candidate in order until
     * one resolves. The lists are ordered most-specific-first: the per-app page
     * that acts on THIS app, then the system-wide list it lives in, so a device
     * that doesn't ship the direct page still lands somewhere useful.
     */
    private fun openOsSettings(which: String?): Boolean {
        val candidates = when (which) {
            "exactAlarm" -> listOfNotNull(exactAlarmIntent())
            "batteryOptimization" -> batteryOptimizationIntents()
            "fullScreenIntent" -> fullScreenIntentIntents()
            "overlay" -> overlayIntents()
            "notifications" -> listOf(notificationSettingsIntent())
            "oemAutostart" -> listOfNotNull(oemAutostartIntent())
            else -> emptyList()
        }

        for (intent in candidates) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (e: ActivityNotFoundException) {
                continue
            } catch (e: SecurityException) {
                continue
            }
        }
        return false
    }

    /**
     * ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS only opens the system-wide
     * list, which defaults to the "Not optimised" filter — an app that IS
     * optimised is absent from it, so the user is told to whitelist an app they
     * can't find. ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS instead raises the
     * direct "Allow app to run in the background?" dialog for this package
     * (allowed: REQUEST_IGNORE_BATTERY_OPTIMIZATIONS is declared, and an
     * alarm-clock app is one of Play's permitted use cases). The list and the
     * app-details page remain as fallbacks for OEMs that block the dialog.
     */
    private fun batteryOptimizationIntents(): List<Intent> {
        val out = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            out += Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.fromParts("package", context.packageName, null))
            out += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        }
        out += appDetailsIntent()
        return out
    }

    /**
     * Android 14+ keeps USE_FULL_SCREEN_INTENT under "Special app access →
     * Full screen notifications", NOT the app's notification settings — apps
     * installed on 14+ that aren't calling/alarm apps start DENIED, which is
     * exactly why the adhan degrades to a heads-up notification. This is the
     * only page with that toggle; older versions fall through to the app's
     * notification settings, where the grant doesn't exist to begin with.
     */
    private fun fullScreenIntentIntents(): List<Intent> {
        val out = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            out += Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                .setData(Uri.fromParts("package", context.packageName, null))
        }
        out += notificationSettingsIntent()
        out += appDetailsIntent()
        return out
    }

    /**
     * "Display over other apps" for THIS app. The per-package page is the one
     * with the actual toggle; the system-wide list is the fallback for builds
     * that don't honour the package URI.
     */
    private fun overlayIntents(): List<Intent> {
        val out = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            out += Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                .setData(Uri.fromParts("package", context.packageName, null))
            out += Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
        }
        out += appDetailsIntent()
        return out
    }

    private fun appDetailsIntent(): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", context.packageName, null))

    private fun exactAlarmIntent(): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        return Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
            .setData(Uri.fromParts("package", context.packageName, null))
    }

    private fun notificationSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", context.packageName, null))
        }

    /**
     * The real-world failure point: several OEMs kill background alarms unless
     * the app is whitelisted in a proprietary "autostart" / "protected apps"
     * manager that no public API exposes. Probes the known component names and
     * returns the first one this device actually has, or null when it has none
     * (stock Android, Pixel, most Samsung builds).
     */
    private fun oemAutostartIntent(): Intent? {
        val candidates = listOf(
            // Xiaomi / Redmi / POCO
            "com.miui.securitycenter" to
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            // Oppo / Realme (ColorOS)
            "com.coloros.safecenter" to
                "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.coloros.safecenter" to
                "com.coloros.safecenter.startupapp.StartupAppListActivity",
            "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
            // Vivo (FuntouchOS)
            "com.vivo.permissionmanager" to
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
            // Huawei / Honor
            "com.huawei.systemmanager" to
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            "com.huawei.systemmanager" to
                "com.huawei.systemmanager.optimize.process.ProtectActivity",
            // Letv / Asus
            "com.letv.android.letvsafe" to
                "com.letv.android.letvsafe.AutobootManageActivity",
            "com.asus.mobilemanager" to "com.asus.mobilemanager.MainActivity",
        )
        val pm = context.packageManager
        for ((pkg, cls) in candidates) {
            val intent = Intent().setComponent(ComponentName(pkg, cls))
            if (intent.resolveActivity(pm) != null) return intent
        }
        return null
    }

    companion object {
        const val CHANNEL = "com.zikr.mapp/adhan_alarm"
    }
}
