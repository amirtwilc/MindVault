package app.amir.mindvault

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

// Request codes for PendingIntents (must be unique per widget action and disjoint
// from HomeWidgetProvider's set 0/1/2/4 — Android keys PendingIntents by
// (requestCode, intent), so a shared code across providers can hijack each other.
// 10 = open app, 11 = new note, 12 = row template, 14 = search, 15 = new jot.
class CategoriesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.categories_widget)

        // ── Categories list (RemoteViewsService binding) ──────────────────────
        // Per-instance data URI prevents Android from caching the factory across
        // widget instances — same trick HomeWidgetProvider uses.
        val serviceIntent = Intent(context, CategoryWidgetService::class.java).apply {
            data = Uri.withAppendedPath(
                Uri.parse("content://app.amir.mindvault/categories-widget/"),
                appWidgetId.toString()
            )
        }
        views.setRemoteAdapter(R.id.widget_categories_list, serviceIntent)

        // Template intent for category row taps — the data URI is filled in
        // per-row in CategoryWidgetFactory.getViewAt via setOnClickFillInIntent.
        val rowTemplate = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        // FLAG_MUTABLE so fill-in intents can patch the data URI; otherwise
        // tapping a row would open the main app instead of the floating window.
        val templatePi = PendingIntent.getActivity(
            context, 12, rowTemplate,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_categories_list, templatePi)

        // ── widget_title click → open app (MainActivity) ─────────────────────
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPi = PendingIntent.getActivity(
            context, 10, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, openPi)

        // ── "+" button click → TransparentActivity with deep link ─────────────
        // No category override: top-level "+" always opens with General as the
        // default. The category-aware "+" lives inside the per-category
        // floating window opened by tapping a row.
        val newNoteIntent = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://widget/new-note")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val newNotePi = PendingIntent.getActivity(
            context, 11, newNoteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_new_note_btn, newNotePi)

        val newJotIntent = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://widget/new-jot")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val newJotPi = PendingIntent.getActivity(
            context, 15, newJotIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_new_jot_btn, newJotPi)

        // ── Search button → TransparentActivity with widget-search deep link ──
        val searchIntent = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://widget/widget-search")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val searchPi = PendingIntent.getActivity(
            context, 14, searchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_search_btn, searchPi)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(
            appWidgetId, R.id.widget_categories_list
        )
    }
}
