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

class CategoryWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        CategoryWidgetFactory(applicationContext)
}

private class CategoryWidgetFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class CategoryItem(
        val id: String,
        val name: String,
        val color: String?,
        val noteCount: Int,
    )

    private var items: List<CategoryItem> = emptyList()

    override fun onCreate() { reload() }
    override fun onDataSetChanged() { reload() }
    override fun onDestroy() {}

    private fun reload() {
        val data = HomeWidgetPlugin.getData(context)
        val raw = data.getString("widget_data", "{}") ?: "{}"
        val json = try { JSONObject(raw) } catch (_: Exception) { JSONObject() }

        val arr = json.optJSONArray("categories") ?: JSONArray()

        items = (0 until arr.length()).mapNotNull { i ->
            val entry = arr.optJSONObject(i) ?: return@mapNotNull null
            val color = if (entry.has("color") && !entry.isNull("color"))
                entry.optString("color").takeIf { it.isNotEmpty() }
            else null
            CategoryItem(
                id = entry.optString("id"),
                name = entry.optString("name"),
                color = color,
                noteCount = entry.optInt("note_count", 0),
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
        return RemoteViews(context.packageName, R.layout.widget_category_item).also {
            it.setTextViewText(
                R.id.widget_category_label,
                "${item.name} (${item.noteCount})"
            )
            it.setInt(R.id.widget_category_dot, "setColorFilter", parseColorOrDefault(item.color))

            // Lay out the row by the dominant direction of the category name —
            // dot before text in either direction. RTL device locale alone
            // isn't enough: an English category in a Hebrew device should
            // still render the dot to the LEFT of the text.
            val rtl = firstStrongIsRtl(item.name)
            it.setInt(
                R.id.widget_category_item_root,
                "setLayoutDirection",
                if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            )

            // appendQueryParameter handles URL-encoding so the category name
            // round-trips correctly even with reserved characters (e.g. &, ?, %).
            val uri = Uri.Builder()
                .scheme("mindvault")
                .authority("widget")
                .path("/category-notes")
                .appendQueryParameter("categoryId", item.id)
                .appendQueryParameter("name", item.name)
                .build()

            it.setOnClickFillInIntent(
                R.id.widget_category_item_root,
                Intent().apply { data = uri },
            )
        }
    }
}
