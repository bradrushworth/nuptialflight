package au.com.bitbot.nuptialflight

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AppWidgetProvider : HomeWidgetProvider() {

    val greenThreshold = 60
    val amberThreshold = 50

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                val percentage = widgetData.getInt("_percentage", 0)
                var percentageText = getEmojiText(percentage)
                if (percentage == 0) {
                    percentageText = context.getString(R.string.widget_calculating)
                    setTextViewTextSize(R.id.tv_percentage, TypedValue.COMPLEX_UNIT_PT, 5.0f)
                } else {
                    setTextViewTextSize(R.id.tv_percentage, TypedValue.COMPLEX_UNIT_PT, 11.0f)
                }
                setTextViewTextSize(R.id.tv_heading, TypedValue.COMPLEX_UNIT_PT, 7.0f)

                // Colours come from day/night resources (values/ and values-night/),
                // so the widget follows the system theme instead of hardcoding pure
                // RED/YELLOW/GREEN with black text. Severity picks a rounded
                // background drawable; the corner radius matches the system widget
                // radius on Android 12+ (values-v31).
                setTextColor(R.id.tv_heading, context.getColor(R.color.widget_text_secondary))
                setTextColor(R.id.tv_percentage, context.getColor(R.color.widget_text))
                setTextViewText(R.id.tv_heading, context.getString(R.string.widget_heading))
                setTextViewText(R.id.tv_percentage, percentageText)
                val background = when {
                    percentage == 0 -> R.drawable.widget_bg_neutral
                    percentage < amberThreshold -> R.drawable.widget_bg_low
                    percentage < greenThreshold -> R.drawable.widget_bg_mid
                    else -> R.drawable.widget_bg_high
                }
                setInt(R.id.linear_layout, "setBackgroundResource", background)

                // Announce the state, not just the emoji, to TalkBack users.
                setContentDescription(
                    R.id.widget_root,
                    context.getString(R.string.widget_content_description, percentage)
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    fun getEmojiText(percentage: Int): String {
        if (percentage < 45) return "👎"
        if (percentage < 50) return "🤏"
        if (percentage < 55) return "🤞"
        if (percentage < 60) return "🐜👌"
        if (percentage < 65) return "🐜👍"
        if (percentage < 70) return "🐜💪"
        return "🐜🫶"
    }

}
