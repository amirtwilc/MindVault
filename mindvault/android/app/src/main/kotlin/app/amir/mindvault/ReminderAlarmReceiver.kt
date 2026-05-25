package app.amir.mindvault

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

private const val TAG = "MindVaultReminders"

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == JOT_REMINDER_ACTION || intent.hasExtra("jotId")) {
            handleJotAlarm(context, intent)
            return
        }

        val noteId = intent.getStringExtra("noteId") ?: return
        val title = intent.getStringExtra("title") ?: return
        val remindAtMillis = intent.getLongExtra("remindAtMillis", 0L)
        val version = intent.getStringExtra("version")
        Log.i(TAG, "Received reminder alarm noteId=$noteId remindAtMillis=$remindAtMillis")
        if (!ReminderPlugin.shouldFire(context, noteId, remindAtMillis, version)) return
        val body = intent.getStringExtra("body")
            ?: context.getString(R.string.reminder_notification_body)
        ReminderPlugin.showNotification(context, noteId, title, body)
        ReminderPlugin.forgetFired(context, noteId)
    }

    private fun handleJotAlarm(context: Context, intent: Intent) {
        val jotId = intent.getStringExtra("jotId") ?: return
        val title = intent.getStringExtra("title") ?: return
        val remindAtMillis = intent.getLongExtra("remindAtMillis", 0L)
        val version = intent.getStringExtra("version")
        Log.i(TAG, "Received jot reminder alarm jotId=$jotId remindAtMillis=$remindAtMillis")
        if (!ReminderPlugin.shouldFireJot(context, jotId, remindAtMillis, version)) return
        val body = intent.getStringExtra("body")
            ?: context.getString(R.string.jot_notification_body)
        ReminderPlugin.showJotNotification(context, jotId, title, body)
        ReminderPlugin.forgetFiredJot(context, jotId)
    }

    private companion object {
        const val JOT_REMINDER_ACTION = "app.amir.mindvault.JOT_REMINDER_ALARM"
    }
}
