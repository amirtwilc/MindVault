package app.amir.mindvault

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
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
        val categoryColor: String?,
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
            val color = if (entry.has("category_color") && !entry.isNull("category_color"))
                entry.optString("category_color").takeIf { it.isNotEmpty() }
            else null
            NoteItem(
                id = entry.optString("id"),
                title = entry.optString("title"),
                isPrivate = entry.optBoolean("is_private", false),
                categoryColor = color,
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
            it.setTextViewText(R.id.widget_note_label, item.text)
            it.setInt(R.id.widget_note_dot, "setColorFilter", parseColorOrDefault(item.categoryColor))

            // Mirror the categories widget: lay out the row by the dominant
            // direction of the note title so the dot sits on the leading edge
            // regardless of device locale.
            val rtl = firstStrongIsRtl(item.text)
            it.setInt(
                R.id.widget_note_item_root,
                "setLayoutDirection",
                if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            )

            val uriBuilder = Uri.Builder()
                .scheme("mindvault")
                .authority("widget")
                .path("/view-memory")
                .appendQueryParameter("id", item.id)
            uriBuilder.appendQueryParameter("title", item.title)
            it.setOnClickFillInIntent(
                R.id.widget_note_item_root,
                Intent().apply { data = uriBuilder.build() },
            )
        }
    }

    // Lock emoji is appended as a *suffix* (after any "(Category)") rather than
    // a prefix, so the colored dot — drawn separately at the leading edge of
    // the row — remains the first visual element. This matches the convention
    // we want for both LTR and RTL: <dot> <title> (<category>) <lock>.
    private fun formatEntry(entry: JSONObject): String {
        val isPrivate = entry.optBoolean("is_private", false)
        val catName = entry.optString("category_name", "")
        val title = entry.optString("title", "")
        val suffix = if (isPrivate) " 🔒" else ""
        return if (catName.isNotEmpty()) "$title ($catName)$suffix" else "$title$suffix"
    }
}
