package app.amir.mindvault

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            ReminderPlugin.rescheduleRemembered(context)
            ReminderPlugin.rescheduleRememberedJots(context)
            ReminderPlugin.rescheduleSparkDigest(context)
            ReminderPlugin.ensureHourlyReconcile(context)
        }
    }
}
