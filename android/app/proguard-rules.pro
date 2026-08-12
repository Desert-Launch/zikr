# ── flutter_local_notifications / Gson ────────────────────────────────────────
# The plugin persists every scheduled notification as JSON in SharedPreferences
# and rebuilds it with Gson inside ScheduledNotificationReceiver (when the alarm
# fires) and ScheduledNotificationBootReceiver (after a reboot).
#
# Gson resolves those types through `new TypeToken<NotificationDetails>(){}`,
# which reads the generic signature of the anonymous subclass. R8 drops that
# attribute by default, so the TypeToken constructor throws
#
#     java.lang.RuntimeException: Missing type parameter.
#
# The receiver then dies with "Unable to start receiver ..." — which kills the
# whole app process, posts NO notification, and (because the receiver never got
# to re-arm the next occurrence) breaks the daily/weekly repeat chain until the
# app is opened again and reconciles. Release builds looked like "notifications
# randomly stop working"; debug builds were fine because they aren't minified.
#
# Keeping Signature is the actual fix; the rest are the plugin's + Gson's
# documented keep rules.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-keep class com.dexterous.** { *; }

-dontwarn com.google.gson.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Fields Gson reads reflectively must keep their names.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ── App entry points reached only from the manifest / AlarmManager ────────────
# Referenced by name from AndroidManifest.xml and PendingIntents, never called
# from Kotlin/Java code R8 can see.
-keep class com.zikr.mapp.adhan.** { *; }

# ── Plugins with reflective / native entry points ────────────────────────────
-keep class com.ryanheise.audioservice.** { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# core library desugaring
-dontwarn java.lang.invoke.StringConcatFactory
