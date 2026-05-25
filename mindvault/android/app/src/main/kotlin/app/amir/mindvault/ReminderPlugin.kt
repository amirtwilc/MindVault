package app.amir.mindvault

import android.Manifest
import android.app.Activity
import android.app.ActivityOptions
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

private const val REMINDER_CHANNEL = "mindvault/reminders"
private const val NOTIFICATION_CHANNEL_ID = "note_reminders_v2"
private const val PREFS = "mindvault_reminders"
private const val JOT_PREFS = "mindvault_jot_reminders"
private const val KEY_IDS = "note_ids"
private const val KEY_JOT_IDS = "jot_ids"
private const val NOTIFICATION_PERMISSION_REQUEST = 7301
private const val TAG = "MindVaultReminders"

object ReminderPlugin {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissionActivity: Activity? = null

    fun register(activity: Activity, flutterEngine: FlutterEngine) {
        ensureNotificationChannel(activity)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REMINDER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> result.success(permissionMap(activity))
                "requestPermissions" -> {
                    val requestExact = call.argument<Boolean>("requestExactAlarm") == true
                    val requestedNotification =
                        requestNotificationPermission(activity, result)
                    if (requestExact) requestExactAlarmAccess(activity)
                    if (!requestedNotification) {
                        result.success(permissionMap(activity))
                    }
                }
                "openBackgroundPermissionSettings" -> {
                    result.success(openBackgroundPermissionSettings(activity))
                }
                "schedule" -> {
                    val noteId = call.argument<String>("noteId")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val at = call.argument<Long>("remindAtMillis")
                    val version = call.argument<String>("version")
                    if (noteId == null || title == null || body == null || at == null || version == null) {
                        result.error("bad_args", "Missing reminder schedule argument.", null)
                        return@setMethodCallHandler
                    }
                    schedule(activity, noteId, title, body, at, version)
                    result.success(null)
                }
                "cancel" -> {
                    call.argument<String>("noteId")?.let { cancel(activity, it) }
                    result.success(null)
                }
                "scheduleJot" -> {
                    val jotId = call.argument<String>("jotId")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val at = call.argument<Long>("remindAtMillis")
                    val version = call.argument<String>("version")
                    if (jotId == null || title == null || body == null || at == null || version == null) {
                        result.error("bad_args", "Missing jot reminder schedule argument.", null)
                        return@setMethodCallHandler
                    }
                    scheduleJot(activity, jotId, title, body, at, version)
                    result.success(null)
                }
                "cancelJot" -> {
                    call.argument<String>("jotId")?.let { cancelJot(activity, it) }
                    result.success(null)
                }
                "cancelExcept" -> {
                    val keep = call.argument<List<String>>("noteIds")?.toSet() ?: emptySet()
                    cancelExcept(activity, keep)
                    result.success(null)
                }
                "cancelJotsExcept" -> {
                    val keep = call.argument<List<String>>("jotIds")?.toSet() ?: emptySet()
                    cancelJotsExcept(activity, keep)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return false
        val activity = pendingPermissionActivity
        val result = pendingPermissionResult
        pendingPermissionActivity = null
        pendingPermissionResult = null
        if (activity != null && result != null) {
            result.success(permissionMap(activity))
        }
        return true
    }

    fun schedule(
        context: Context,
        noteId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ) {
        ensureNotificationChannel(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val fireAt = remindAtMillis.coerceAtLeast(System.currentTimeMillis() + 1000)
        val pi = legacyBroadcastAlarmPendingIntent(context, noteId, title, body, remindAtMillis, version)
        val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarmManager.canScheduleExactAlarms()
        val delayMs = fireAt - System.currentTimeMillis()
        remember(context, noteId, title, body, remindAtMillis, version)
        alarmManager.cancel(alarmActivityPendingIntent(context, noteId, "", "", 0L, ""))
        alarmManager.cancel(alarmServicePendingIntent(context, noteId, "", "", 0L, ""))
        alarmManager.cancel(pi)
        val strategy = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && exactAllowed) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "exact_allow_while_idle"
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "allow_while_idle"
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "exact"
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "set"
        }
        ensureHourlyReconcile(context)
        Log.i(
            TAG,
            "Scheduled reminder noteId=$noteId fireAt=$fireAt delayMs=$delayMs strategy=$strategy exactAllowed=$exactAllowed"
        )
    }

    fun scheduleJot(
        context: Context,
        jotId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ) {
        ensureNotificationChannel(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val fireAt = remindAtMillis.coerceAtLeast(System.currentTimeMillis() + 1000)
        val pi = jotBroadcastAlarmPendingIntent(context, jotId, title, body, remindAtMillis, version)
        val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarmManager.canScheduleExactAlarms()
        val delayMs = fireAt - System.currentTimeMillis()
        rememberJot(context, jotId, title, body, remindAtMillis, version)
        alarmManager.cancel(jotAlarmActivityPendingIntent(context, jotId, "", "", 0L, ""))
        alarmManager.cancel(jotAlarmServicePendingIntent(context, jotId, "", "", 0L, ""))
        alarmManager.cancel(pi)
        val strategy = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && exactAllowed) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "exact_allow_while_idle"
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "allow_while_idle"
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "exact"
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, fireAt, pi)
            "set"
        }
        ensureHourlyReconcile(context)
        Log.i(
            TAG,
            "Scheduled jot reminder jotId=$jotId fireAt=$fireAt delayMs=$delayMs strategy=$strategy exactAllowed=$exactAllowed"
        )
    }

    fun cancel(context: Context, noteId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(alarmServicePendingIntent(context, noteId, "", "", 0L, ""))
        alarmManager.cancel(alarmActivityPendingIntent(context, noteId, "", "", 0L, ""))
        alarmManager.cancel(legacyBroadcastAlarmPendingIntent(context, noteId, "", "", 0L, ""))
        forget(context, noteId)
        NotificationManagerCompat.from(context).cancel(notificationId(noteId))
        Log.i(TAG, "Canceled reminder noteId=$noteId")
    }

    fun cancelJot(context: Context, jotId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(jotAlarmActivityPendingIntent(context, jotId, "", "", 0L, ""))
        alarmManager.cancel(jotAlarmServicePendingIntent(context, jotId, "", "", 0L, ""))
        alarmManager.cancel(jotBroadcastAlarmPendingIntent(context, jotId, "", "", 0L, ""))
        forgetJot(context, jotId)
        NotificationManagerCompat.from(context).cancel(jotNotificationId(jotId))
        Log.i(TAG, "Canceled jot reminder jotId=$jotId")
    }

    fun rescheduleRemembered(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        ids(context).forEach { noteId ->
            val remindAt = prefs.getLong("${noteId}_at", 0L)
            val title = prefs.getString("${noteId}_title", null)
            val body = prefs.getString("${noteId}_body", null)
            val version = prefs.getString("${noteId}_version", null)
            if (remindAt <= 0L || title == null || body == null || version == null) {
                forget(context, noteId)
            } else if (remindAt <= now) {
                cancel(context, noteId)
            } else {
                schedule(context, noteId, title, body, remindAt, version)
            }
        }
    }

    fun rescheduleRememberedJots(context: Context) {
        val prefs = context.getSharedPreferences(JOT_PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        jotIds(context).forEach { jotId ->
            val remindAt = prefs.getLong("${jotId}_at", 0L)
            val title = prefs.getString("${jotId}_title", null)
            val body = prefs.getString("${jotId}_body", null)
            val version = prefs.getString("${jotId}_version", null)
            if (remindAt <= 0L || title == null || body == null || version == null) {
                forgetJot(context, jotId)
            } else if (remindAt <= now) {
                cancelJot(context, jotId)
            } else {
                scheduleJot(context, jotId, title, body, remindAt, version)
            }
        }
    }

    fun forgetFired(context: Context, noteId: String) {
        forget(context, noteId)
    }

    fun forgetFiredJot(context: Context, jotId: String) {
        forgetJot(context, jotId)
    }

    fun shouldFire(
        context: Context,
        noteId: String,
        remindAtMillis: Long,
        version: String?
    ): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val rememberedAt = prefs.getLong("${noteId}_at", 0L)
        val rememberedVersion = prefs.getString("${noteId}_version", null)
        val current = ids(context).contains(noteId) &&
                rememberedAt == remindAtMillis &&
                rememberedVersion == version
        if (!current) {
            Log.i(
                TAG,
                "Ignoring stale reminder alarm noteId=$noteId alarmAt=$remindAtMillis rememberedAt=$rememberedAt"
            )
        }
        return current
    }

    fun shouldFireJot(
        context: Context,
        jotId: String,
        remindAtMillis: Long,
        version: String?
    ): Boolean {
        val prefs = context.getSharedPreferences(JOT_PREFS, Context.MODE_PRIVATE)
        val rememberedAt = prefs.getLong("${jotId}_at", 0L)
        val rememberedVersion = prefs.getString("${jotId}_version", null)
        val current = jotIds(context).contains(jotId) &&
                rememberedAt == remindAtMillis &&
                rememberedVersion == version
        if (!current) {
            Log.i(
                TAG,
                "Ignoring stale jot reminder alarm jotId=$jotId alarmAt=$remindAtMillis rememberedAt=$rememberedAt"
            )
        }
        return current
    }

    fun ensureHourlyReconcile(context: Context) {
        if (ids(context).isEmpty() && jotIds(context).isEmpty()) return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReconcileReceiver::class.java).apply {
            action = "app.amir.mindvault.REMINDER_RECONCILE"
        }
        val pi = PendingIntent.getBroadcast(
            context,
            7302,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val next = System.currentTimeMillis() + 60L * 60L * 1000L
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, next, pi)
        }
    }

    fun showNotification(context: Context, noteId: String, title: String, body: String) {
        val notification = buildNotification(context, noteId, title, body) ?: return
        NotificationManagerCompat.from(context).notify(notificationId(noteId), notification)
        Log.i(TAG, "Posted reminder notification noteId=$noteId")
    }

    fun showJotNotification(context: Context, jotId: String, title: String, body: String) {
        val notification = buildJotNotification(context, jotId, title, body) ?: return
        NotificationManagerCompat.from(context).notify(jotNotificationId(jotId), notification)
        Log.i(TAG, "Posted jot reminder notification jotId=$jotId")
    }

    fun buildNotification(
        context: Context,
        noteId: String,
        title: String,
        body: String
    ): Notification? {
        return buildNotificationWithTap(
            context,
            title,
            body,
            notificationTapPendingIntent(context, noteId)
        )
    }

    fun buildJotNotification(
        context: Context,
        jotId: String,
        title: String,
        body: String
    ): Notification? {
        return buildNotificationWithTap(
            context,
            title,
            body,
            jotNotificationTapPendingIntent(context, jotId)
        )
    }

    private fun buildNotificationWithTap(
        context: Context,
        title: String,
        body: String,
        tapPi: PendingIntent
    ): Notification? {
        ensureNotificationChannel(context)
        if (!notificationsAllowed(context)) {
            Log.w(TAG, "Skipping reminder notification because permission is missing")
            return null
        }
        return NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(tapPi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_LIGHTS or NotificationCompat.DEFAULT_VIBRATE)
            .setLights(Color.CYAN, 1000, 1000)
            .setVibrate(longArrayOf(0L, 250L, 150L, 250L))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    fun buildForegroundServiceNotification(context: Context): Notification {
        ensureNotificationChannel(context)
        val tapPi = notificationTapPendingIntent(context, "foreground-service")
        return NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(context.getString(R.string.app_name))
            .setContentText(context.getString(R.string.reminder_notification_channel))
            .setContentIntent(tapPi)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setSilent(true)
            .setOngoing(true)
            .build()
    }

    fun notificationIdFor(noteId: String): Int {
        return notificationId(noteId)
    }

    fun jotNotificationIdFor(jotId: String): Int {
        return jotNotificationId(jotId)
    }

    private fun notificationTapPendingIntent(context: Context, noteId: String): PendingIntent {
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://reminder/note?id=${Uri.encode(noteId)}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            notificationId(noteId),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun jotNotificationTapPendingIntent(context: Context, jotId: String): PendingIntent {
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://jot/reminder?id=${Uri.encode(jotId)}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            jotNotificationId(jotId),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun alarmActivityPendingIntent(
        context: Context,
        noteId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmActivity::class.java).apply {
            action = "app.amir.mindvault.REMINDER_ALARM"
            data = Uri.parse("mindvault://alarm/$noteId")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
            putExtra("noteId", noteId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("remindAtMillis", remindAtMillis)
            putExtra("version", version)
        }
        return PendingIntent.getActivity(
            context,
            notificationId(noteId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            alarmActivityOptionsBundle()
        )
    }

    private fun jotAlarmActivityPendingIntent(
        context: Context,
        jotId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmActivity::class.java).apply {
            action = "app.amir.mindvault.JOT_REMINDER_ALARM"
            data = Uri.parse("mindvault://jot-alarm/$jotId")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
            putExtra("jotId", jotId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("remindAtMillis", remindAtMillis)
            putExtra("version", version)
        }
        return PendingIntent.getActivity(
            context,
            jotNotificationId(jotId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            alarmActivityOptionsBundle()
        )
    }

    @Suppress("DEPRECATION")
    private fun alarmActivityOptionsBundle(): Bundle? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return null
        val mode = if (Build.VERSION.SDK_INT >= 36) {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOW_ALWAYS
        } else {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
        return ActivityOptions.makeBasic()
            .setPendingIntentCreatorBackgroundActivityStartMode(mode)
            .toBundle()
    }

    private fun alarmServicePendingIntent(
        context: Context,
        noteId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmService::class.java).apply {
            action = "app.amir.mindvault.REMINDER_ALARM"
            data = Uri.parse("mindvault://alarm/$noteId")
            putExtra("noteId", noteId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("remindAtMillis", remindAtMillis)
            putExtra("version", version)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(context, notificationId(noteId), intent, flags)
        } else {
            PendingIntent.getService(context, notificationId(noteId), intent, flags)
        }
    }

    private fun jotAlarmServicePendingIntent(
        context: Context,
        jotId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmService::class.java).apply {
            action = "app.amir.mindvault.JOT_REMINDER_ALARM"
            data = Uri.parse("mindvault://jot-alarm/$jotId")
            putExtra("jotId", jotId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("remindAtMillis", remindAtMillis)
            putExtra("version", version)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(context, jotNotificationId(jotId), intent, flags)
        } else {
            PendingIntent.getService(context, jotNotificationId(jotId), intent, flags)
        }
    }

    private fun legacyBroadcastAlarmPendingIntent(
        context: Context,
        noteId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = "app.amir.mindvault.REMINDER_ALARM"
            data = Uri.parse("mindvault://alarm/$noteId")
            putExtra("noteId", noteId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("remindAtMillis", remindAtMillis)
            putExtra("version", version)
        }
        return PendingIntent.getBroadcast(
            context,
            notificationId(noteId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun jotBroadcastAlarmPendingIntent(
        context: Context,
        jotId: String,
        title: String,
        body: String,
        remindAtMillis: Long,
        version: String
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = "app.amir.mindvault.JOT_REMINDER_ALARM"
            data = Uri.parse("mindvault://jot-alarm/$jotId")
            putExtra("jotId", jotId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("remindAtMillis", remindAtMillis)
            putExtra("version", version)
        }
        return PendingIntent.getBroadcast(
            context,
            jotNotificationId(jotId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun permissionMap(context: Context): Map<String, Boolean> {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarmManager.canScheduleExactAlarms()
        return mapOf(
            "notificationsAllowed" to notificationsAllowed(context),
            "exactAlarmsAllowed" to exactAllowed,
            "batteryOptimized" to isBatteryOptimized(context)
        )
    }

    private fun openBackgroundPermissionSettings(activity: Activity): Boolean {
        return openAutoStartSettings(activity) ||
                openBatteryOptimizationSettings(activity) ||
                openAppSettings(activity)
    }

    private fun openAutoStartSettings(activity: Activity): Boolean {
        val intent = Intent()
        when (Build.MANUFACTURER.lowercase()) {
            "xiaomi", "redmi" -> intent.component = ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            )

            "oppo" -> intent.component = ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity"
            )

            "vivo" -> intent.component = ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            )

            "huawei", "honor" -> intent.component = ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            )

            "oneplus" -> intent.component = ComponentName(
                "com.oneplus.security",
                "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
            )

            "asus" -> intent.component = ComponentName(
                "com.asus.mobilemanager",
                "com.asus.mobilemanager.autostart.AutoStartActivity"
            )

            "letv" -> intent.component = ComponentName(
                "com.letv.android.letvsafe",
                "com.letv.android.letvsafe.AutobootManageActivity"
            )

            "samsung" -> return openBatteryOptimizationSettings(activity)
            else -> return false
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return startSettingsActivity(activity, intent)
    }

    private fun openBatteryOptimizationSettings(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        return startSettingsActivity(
            activity,
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
    }

    private fun openAppSettings(activity: Activity): Boolean {
        return startSettingsActivity(
            activity,
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${activity.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
    }

    private fun startSettingsActivity(activity: Activity, intent: Intent): Boolean {
        return try {
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.w(TAG, "Unable to open reminder background settings", e)
            false
        }
    }

    private fun isBatteryOptimized(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return powerManager?.isIgnoringBatteryOptimizations(context.packageName) == false
    }

    private fun notificationsAllowed(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission(
        activity: Activity,
        result: MethodChannel.Result
    ): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !notificationsAllowed(activity)
        ) {
            pendingPermissionResult?.success(permissionMap(activity))
            pendingPermissionResult = result
            pendingPermissionActivity = activity
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST
            )
            return true
        }
        return false
    }

    private fun requestExactAlarmAccess(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                activity.startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:${activity.packageName}")
                })
            }
        }
    }

    private fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            context.getString(R.string.reminder_notification_channel),
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            enableLights(true)
            lightColor = Color.CYAN
            enableVibration(true)
            vibrationPattern = longArrayOf(0L, 250L, 150L, 250L)
            setSound(soundUri, audioAttributes)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun remember(
        context: Context,
        noteId: String,
        title: String,
        body: String,
        at: Long,
        version: String
    ) {
        val nextIds = ids(context).plus(noteId)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putStringSet(KEY_IDS, nextIds)
            .putString("${noteId}_title", title)
            .putString("${noteId}_body", body)
            .putLong("${noteId}_at", at)
            .putString("${noteId}_version", version)
            .commit()
        Log.i(TAG, "Remembered reminder noteId=$noteId at=$at")
    }

    private fun rememberJot(
        context: Context,
        jotId: String,
        title: String,
        body: String,
        at: Long,
        version: String
    ) {
        val nextIds = jotIds(context).plus(jotId)
        context.getSharedPreferences(JOT_PREFS, Context.MODE_PRIVATE).edit()
            .putStringSet(KEY_JOT_IDS, nextIds)
            .putString("${jotId}_title", title)
            .putString("${jotId}_body", body)
            .putLong("${jotId}_at", at)
            .putString("${jotId}_version", version)
            .commit()
        Log.i(TAG, "Remembered jot reminder jotId=$jotId at=$at")
    }

    private fun forget(context: Context, noteId: String) {
        val nextIds = ids(context).minus(noteId)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putStringSet(KEY_IDS, nextIds)
            .remove("${noteId}_title")
            .remove("${noteId}_body")
            .remove("${noteId}_at")
            .remove("${noteId}_version")
            .commit()
        Log.i(TAG, "Forgot reminder noteId=$noteId")
    }

    private fun forgetJot(context: Context, jotId: String) {
        val nextIds = jotIds(context).minus(jotId)
        context.getSharedPreferences(JOT_PREFS, Context.MODE_PRIVATE).edit()
            .putStringSet(KEY_JOT_IDS, nextIds)
            .remove("${jotId}_title")
            .remove("${jotId}_body")
            .remove("${jotId}_at")
            .remove("${jotId}_version")
            .commit()
        Log.i(TAG, "Forgot jot reminder jotId=$jotId")
    }

    private fun cancelExcept(context: Context, keep: Set<String>) {
        ids(context).filterNot { keep.contains(it) }.forEach { cancel(context, it) }
    }

    private fun cancelJotsExcept(context: Context, keep: Set<String>) {
        jotIds(context).filterNot { keep.contains(it) }.forEach { cancelJot(context, it) }
    }

    private fun ids(context: Context): Set<String> {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY_IDS, emptySet()) ?: emptySet()
    }

    private fun jotIds(context: Context): Set<String> {
        return context.getSharedPreferences(JOT_PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY_JOT_IDS, emptySet()) ?: emptySet()
    }

    private fun notificationId(noteId: String): Int = abs(noteId.hashCode())
    private fun jotNotificationId(jotId: String): Int = abs("jot_$jotId".hashCode())
}
