package com.zikr.mapp.maps

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge the nearby-mosques screen asks before it builds a map.
 *
 * The Maps SDK reads its key only from the manifest, and a map created without
 * one crashes the app, so `ensureReady` answers whether the build put a key
 * there. The key Dart passes is ignored — Android can't take it at runtime.
 */
class MapsSdkPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ensureReady" -> result.success(!manifestKey().isNullOrBlank())
            else -> result.notImplemented()
        }
    }

    private fun manifestKey(): String? {
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(
                context.packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
        }
        return info.metaData?.getString(KEY_NAME)
    }

    companion object {
        const val CHANNEL = "com.zikr.mapp/maps_sdk"
        private const val KEY_NAME = "com.google.android.geo.API_KEY"
    }
}
