package au.com.bitbot.nuptialflight

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AppWidgetProvider : HomeWidgetProvider() {

    val greenThreshold = 70
    val amberThreshold = 50

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context,
                        MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                var percentage = widgetData.getInt("_percentage", 0)
                var percentageText = " $percentage%" // Deliberate space padding
                if (percentage == 0) {
                    percentageText = "Calculating"
                }

                setTextColor(R.id.tv_heading, Color.BLACK)
                setTextViewText(R.id.tv_heading, "Ant\nNuptial\nFlight")
                setTextViewText(R.id.tv_percentage, percentageText)
                if (percentage < amberThreshold) {
                    setTextColor(R.id.tv_percentage, Color.BLACK)
                    setInt(R.id.linear_layout, "setBackgroundColor", Color.RED)
                } else if (percentage < greenThreshold) {
                    setTextColor(R.id.tv_percentage, Color.BLACK)
                    setInt(R.id.linear_layout, "setBackgroundColor", Color.YELLOW)
                } else {
                    setTextColor(R.id.tv_percentage, Color.BLACK)
                    setInt(R.id.linear_layout, "setBackgroundColor", Color.GREEN)
                }

                // Pending intent to update counter on button click
//                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context,
//                        Uri.parse("myAppWidget://updateweather"))
//                setOnClickPendingIntent(R.id.bt_update, backgroundIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}