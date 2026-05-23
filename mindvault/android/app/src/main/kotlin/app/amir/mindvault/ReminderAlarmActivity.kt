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
}
