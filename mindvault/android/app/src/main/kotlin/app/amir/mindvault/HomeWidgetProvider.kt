package app.amir.mindvault

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

// Request codes for PendingIntents (must be unique per widget action):
// 0 = open app, 1 = new note, 2 = note row template, 4 = search, 5 = new jot

class HomeWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.mindvault_widget)

        // ── Notes list (scrollable via ListView + RemoteViewsService) ──────────
        // The data URI must be unique per appWidgetId. Without it, Android caches
        // the RemoteViewsService binding by intent equality across all instances,
        // so notifyAppWidgetViewDataChanged may call onDataSetChanged on a stale
        // factory that no longer reflects the current shared-prefs data.
        val serviceIntent = Intent(context, NoteWidgetService::class.java).apply {
            data = Uri.withAppendedPath(
                Uri.parse("content://app.amir.mindvault/widget/"),
                appWidgetId.toString()
            )
        }
        views.setRemoteAdapter(R.id.widget_notes_list, serviceIntent)

        // Template intent for note row taps — data URI is filled in per-row by
        // NoteWidgetFactory.getView() via setOnClickFillInIntent.
        val noteTemplate = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        // FLAG_MUTABLE is required here: fill-in intents from setOnClickFillInIntent
        // cannot patch an immutable PendingIntent, so the data URI would never be
        // delivered and TransparentActivity would receive a bare ACTION_VIEW with
        // no deep link, opening the main app instead of the floating note view.
        val templatePi = PendingIntent.getActivity(
            context, 2, noteTemplate,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_notes_list, templatePi)

        // ── widget_title click → open app (MainActivity) ─────────────────────
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPi = PendingIntent.getActivity(
            context, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, openPi)

        // ── "+" button click → TransparentActivity with deep link ─────────────
        // No category override: the top-level widget button always opens
        // compose with the General default. Per-category preselection is
        // reserved for the "+" button inside the categories widget's
        // floating window.
        val newNoteIntent = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://widget/new-note")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val newNotePi = PendingIntent.getActivity(
            context, 1, newNoteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_new_note_btn, newNotePi)

        val newJotIntent = Intent(context, TransparentActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("mindvault://widget/new-jot")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val newJotPi = PendingIntent.getActivity(
            context, 5, newJotIntent,
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
            context, 4, searchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_search_btn, searchPi)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        // Tell the ListView to reload its rows from NoteWidgetFactory.
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_notes_list)
    }
}
