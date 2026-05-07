package app.amir.mindvault

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

class TransparentActivity : FlutterFragmentActivity() {
    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode =
        FlutterActivityLaunchConfigs.BackgroundMode.transparent

    // Return the widget deep link path (e.g. "/view-note?id=xxx") as Flutter's
    // initial route. With this set, defaultRouteName != "/" and GoRouter's
    // `initialLocation: '/splash'` is ignored — the widget screen builds on
    // the first frame instead of after the splash's 800 ms delay.
    override fun finish() {
        finishAndRemoveTask()
    }

    override fun getInitialRoute(): String? {
        val data = intent?.data
        if (data != null && data.scheme == "mindvault" && data.host == "widget") {
            val path = data.path ?: return super.getInitialRoute()
            val query = data.query
            return if (query.isNullOrEmpty()) path else "$path?$query"
        }
        return super.getInitialRoute()
    }
}
