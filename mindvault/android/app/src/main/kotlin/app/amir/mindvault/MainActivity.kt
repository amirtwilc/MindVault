package app.amir.mindvault

import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReminderPlugin.register(this, flutterEngine)
    }

    override fun getInitialRoute(): String? {
        val data = intent?.data
        if (data != null && data.scheme == "mindvault" && data.host == "reminder" && data.path == "/note") {
            val noteId = data.getQueryParameter("id") ?: return super.getInitialRoute()
            return "/reminder-note?id=${Uri.encode(noteId)}"
        }
        if (data != null && data.scheme == "mindvault" && data.host == "jot" && data.path == "/reminder") {
            val jotId = data.getQueryParameter("id") ?: return super.getInitialRoute()
            return "/jot-reminder?id=${Uri.encode(jotId)}"
        }
        return super.getInitialRoute()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (!ReminderPlugin.onRequestPermissionsResult(requestCode, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }
}
