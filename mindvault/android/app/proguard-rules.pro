# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter deferred components reference Play Core — suppress since we don't use it
-dontwarn com.google.android.play.core.**

# Supabase / Kotlin serialization
-keep class kotlinx.serialization.** { *; }

# PointyCastle
-keep class org.bouncycastle.** { *; }
-keep class com.sun.crypto.** { *; }

# Home widget — AppWidgetProvider subclass is instantiated by Android by name;
# the home_widget plugin is called from Kotlin before Flutter initialises.
-keep class com.mindvault.app.HomeWidgetProvider { *; }
-keep class com.mindvault.app.TransparentActivity { *; }
-keep class es.antonborri.home_widget.** { *; }

# Reminder receivers are launched by Android alarms while Flutter is not running.
-keep class app.amir.mindvault.ReminderAlarmReceiver { *; }
-keep class app.amir.mindvault.ReminderAlarmActivity { *; }
-keep class app.amir.mindvault.ReminderAlarmService { *; }
-keep class app.amir.mindvault.ReminderBootReceiver { *; }
-keep class app.amir.mindvault.ReminderReconcileReceiver { *; }
-keep class app.amir.mindvault.ReminderPlugin { *; }
