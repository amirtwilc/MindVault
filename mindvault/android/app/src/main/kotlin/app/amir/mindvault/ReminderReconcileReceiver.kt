package app.amir.mindvault

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReconcileReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReminderPlugin.rescheduleRemembered(context)
        ReminderPlugin.rescheduleRememberedJots(context)
        ReminderPlugin.rescheduleSparkDigest(context)
        ReminderPlugin.ensureHourlyReconcile(context)
    }
}
