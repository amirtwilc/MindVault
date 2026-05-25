package app.amir.mindvault

import android.app.Activity
import android.os.Bundle
import android.util.Log

private const val TAG = "MindVaultReminders"

class ReminderAlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleAlarm()
    }

    override fun onNewIntent(intent: android.content.Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleAlarm()
    }

    private fun handleAlarm() {
        if (intent.action == JOT_REMINDER_ACTION || intent.hasExtra("jotId")) {
            handleJotAlarm()
            return
        }

        val noteId = intent.getStringExtra("noteId")
        val title = intent.getStringExtra("title")
        if (noteId == null || title == null) {
            finish()
            return
        }

        val remindAtMillis = intent.getLongExtra("remindAtMillis", 0L)
        val version = intent.getStringExtra("version")
        Log.i(TAG, "Received reminder alarm activity noteId=$noteId remindAtMillis=$remindAtMillis")
        if (ReminderPlugin.shouldFire(this, noteId, remindAtMillis, version)) {
            val body = intent.getStringExtra("body")
                ?: getString(R.string.reminder_notification_body)
            ReminderPlugin.showNotification(this, noteId, title, body)
            ReminderPlugin.forgetFired(this, noteId)
        }
        finish()
        overridePendingTransition(0, 0)
    }

    private fun handleJotAlarm() {
        val jotId = intent.getStringExtra("jotId")
        val title = intent.getStringExtra("title")
        if (jotId == null || title == null) {
            finish()
            return
        }

        val remindAtMillis = intent.getLongExtra("remindAtMillis", 0L)
        val version = intent.getStringExtra("version")
        Log.i(TAG, "Received jot reminder alarm activity jotId=$jotId remindAtMillis=$remindAtMillis")
        if (ReminderPlugin.shouldFireJot(this, jotId, remindAtMillis, version)) {
            val body = intent.getStringExtra("body")
                ?: getString(R.string.jot_notification_body)
            ReminderPlugin.showJotNotification(this, jotId, title, body)
            ReminderPlugin.forgetFiredJot(this, jotId)
        }
        finish()
        overridePendingTransition(0, 0)
    }

    private companion object {
        const val JOT_REMINDER_ACTION = "app.amir.mindvault.JOT_REMINDER_ALARM"
    }
}
