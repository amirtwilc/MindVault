package app.amir.mindvault

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class NoteWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        NoteWidgetFactory(applicationContext)
}

private class NoteWidgetFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class NoteItem(
        val id: String,
        val title: String,
        val isPrivate: Boolean,
        val text: String,
    )

    private var items: List<NoteItem> = emptyList()

    override fun onCreate() { reload() }
    override fun onDataSetChanged() { reload() }
    override fun onDestroy() {}

    private fun reload() {
        val data = HomeWidgetPlugin.getData(context)
        val raw = data.getString("widget_data", "{}") ?: "{}"
        val json = try { JSONObject(raw) } catch (_: Exception) { JSONObject() }

        val notesArray = json.optJSONArray("notes") ?: JSONArray()

        items = (0 until notesArray.length()).mapNotNull { i ->
            val entry = notesArray.optJSONObject(i) ?: return@mapNotNull null
            NoteItem(
                id = entry.optString("id"),
                title = entry.optString("title"),
                isPrivate = entry.optBoolean("is_private", false),
                text = formatEntry(entry),
            )
        }
    }

    override fun getCount(): Int = items.size
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
    override fun getLoadingView(): RemoteViews? = null

    override fun getViewAt(position: Int): RemoteViews {
        val item = items[position]
        return RemoteViews(context.packageName, R.layout.widget_note_item).also {
            it.setTextViewText(R.id.widget_note_item_root, item.text)
            val uriBuilder = Uri.Builder()
                .scheme("mindvault")
                .authority("widget")
                .path("/view-note")
                .appendQueryParameter("id", item.id)
            uriBuilder.appendQueryParameter("title", item.title)
            it.setOnClickFillInIntent(
                R.id.widget_note_item_root,
                Intent().apply { data = uriBuilder.build() },
            )
        }
    }

    private fun formatEntry(entry: JSONObject): String {
        val isPrivate = entry.optBoolean("is_private", false)
        val catName = entry.optString("category_name", "")
        val title = entry.optString("title", "")
        val prefix = if (isPrivate) "🔒 " else "• "
        return if (catName.isNotEmpty()) "$prefix$title ($catName)" else "$prefix$title"
    }
}
