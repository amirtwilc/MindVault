package app.amir.mindvault

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationManagerCompat

private const val TAG = "MindVaultReminders"

class ReminderAlarmService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Reminder alarm service created process=${android.os.Process.myPid()}")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val foregroundId = intent?.getStringExtra("noteId")
            ?.let { ReminderPlugin.notificationIdFor(it) }
            ?: FALLBACK_NOTIFICATION_ID
        startReminderForeground(foregroundId)
        var keepNotification = false
        try {
            keepNotification = handleAlarm(intent, foregroundId)
        } catch (t: Throwable) {
            Log.e(TAG, "Reminder alarm service failed before notification", t)
        } finally {
            stopReminderForeground(keepNotification)
            stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    private fun handleAlarm(intent: Intent?, notificationId: Int): Boolean {
        val noteId = intent?.getStringExtra("noteId")
        val title = intent?.getStringExtra("title")
        if (noteId == null || title == null) {
            Log.w(TAG, "Reminder alarm service missing noteId or title")
            return false
        }

        val remindAtMillis = intent.getLongExtra("remindAtMillis", 0L)
        val version = intent.getStringExtra("version")
        Log.i(TAG, "Received reminder alarm service noteId=$noteId remindAtMillis=$remindAtMillis")
        if (!ReminderPlugin.shouldFire(this, noteId, remindAtMillis, version)) return false

        val body = intent.getStringExtra("body")
            ?: getString(R.string.reminder_notification_body)
        val notification = ReminderPlugin.buildNotification(this, noteId, title, body)
        if (notification == null) {
            ReminderPlugin.forgetFired(this, noteId)
            return false
        }
        NotificationManagerCompat.from(this).notify(notificationId, notification)
        ReminderPlugin.forgetFired(this, noteId)
        Log.i(TAG, "Posted reminder notification from service noteId=$noteId")
        return true
    }

    private fun startReminderForeground(notificationId: Int) {
        val notification = ReminderPlugin.buildForegroundServiceNotification(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE
            )
        } else {
            startForeground(notificationId, notification)
        }
    }

    private fun stopReminderForeground(detachNotification: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(
                if (detachNotification) {
                    STOP_FOREGROUND_DETACH
                } else {
                    STOP_FOREGROUND_REMOVE
                }
            )
        } else {
            @Suppress("DEPRECATION")
            stopForeground(!detachNotification)
        }
    }

    private companion object {
        const val FALLBACK_NOTIFICATION_ID = 7304
    }
}
