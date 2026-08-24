package au.com.bitbot.nuptialflight

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget for the Ant Flight Index. The Flutter side saves the
 * band key plus pre-localized band/odds strings; this side only picks
 * colours (day/night resources) and layouts (compact vs full via size
 * mapping on Android 12+).
 */
class AppWidgetProvider : HomeWidgetProvider() {

    private data class Band(
        val bg: Int,
        val fg: Int,
        val fallbackLabel: String,
        /** Winged queen once a flight is plausible; wingless worker below. */
        val winged: Boolean,
    )

    private val bands = mapOf(
        "noFly" to Band(R.drawable.widget_bg_nofly, R.color.widget_fg_nofly, "No-fly", false),
        "quiet" to Band(R.drawable.widget_bg_quiet, R.color.widget_fg_quiet, "Quiet", false),
        "watchful" to Band(R.drawable.widget_bg_watchful, R.color.widget_fg_watchful, "Watchful", false),
        "promising" to Band(R.drawable.widget_bg_promising, R.color.widget_fg_promising, "Promising", true),
        "prime" to Band(R.drawable.widget_bg_prime, R.color.widget_fg_prime, "Prime", true),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                RemoteViews(
                    mapOf(
                        SizeF(48f, 48f) to buildViews(context, widgetData, R.layout.widget_layout_small),
                        SizeF(140f, 48f) to buildViews(context, widgetData, R.layout.widget_layout),
                    )
                )
            } else {
                buildViews(context, widgetData, R.layout.widget_layout)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildViews(
        context: Context,
        widgetData: SharedPreferences,
        layout: Int
    ): RemoteViews {
        val percentage = widgetData.getInt("_percentage", 0)
        // Band key written by 2.20+; fall back to the old percentage
        // thresholds right after an upgrade so the widget is never blank.
        val bandKey = widgetData.getString("_band", null).takeUnless { it.isNullOrEmpty() }
            ?: when {
                percentage <= 0 -> ""
                percentage < 50 -> "quiet"
                percentage < 60 -> "watchful"
                else -> "prime"
            }
        val band = bands[bandKey]
        val label = widgetData.getString("_band_label", null).takeUnless { it.isNullOrEmpty() }
            ?: band?.fallbackLabel
            ?: context.getString(R.string.widget_calculating)
        val odds = if (band == null) ""
            else widgetData.getString("_odds", null).orEmpty()

        return RemoteViews(context.packageName, layout).apply {
            // Open App on Widget Click
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            setInt(
                R.id.linear_layout,
                "setBackgroundResource",
                band?.bg ?: R.drawable.widget_bg_neutral
            )
            val fg = context.getColor(band?.fg ?: R.color.widget_text)

            // The ant grows wings once a flight is on the cards, so the glyph
            // itself carries the forecast rather than just decorating it.
            setImageViewResource(
                R.id.iv_ant,
                if (band?.winged == true) R.drawable.widget_ant_queen
                else R.drawable.widget_ant_worker
            )
            setInt(R.id.iv_ant, "setColorFilter", fg)

            setTextViewText(R.id.tv_band, label)
            setTextColor(R.id.tv_band, fg)
            if (layout == R.layout.widget_layout) {
                setTextViewText(R.id.tv_odds, odds)
                setTextColor(R.id.tv_odds, context.getColor(R.color.widget_text_secondary))
                setTextColor(R.id.tv_heading, context.getColor(R.color.widget_text_secondary))
                // Long localized labels (e.g. "Vielversprechend") get a
                // smaller size so they still fit on one line.
                setTextViewTextSize(
                    R.id.tv_band,
                    android.util.TypedValue.COMPLEX_UNIT_SP,
                    if (label.length > 10) 17.0f else 22.0f
                )
            }

            // Announce the state, not just the colour, to TalkBack users.
            setContentDescription(
                R.id.widget_root,
                context.getString(
                    if (band?.winged == true) R.string.widget_content_description_queen
                    else R.string.widget_content_description,
                    label
                )
            )
        }
    }
}
