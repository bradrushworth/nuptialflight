package au.com.bitbot.nuptialflight

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Quick Settings tile for the Ant Flight Index.
 *
 * Android has no third-party lock-screen widgets - they went away in 5.0 and
 * the Android 15 QPR / 16 revival is dock and tablet only - so this is the
 * closest thing to a glance without unlocking: pull the shade down on the
 * lock screen and the tile is right there.
 *
 * It reads the same App-Group-equivalent store as [AppWidgetProvider] (the
 * home_widget plugin's SharedPreferences, via its public accessor rather than
 * the plugin's internal preferences name), and follows the same convention as
 * the widgets: a wingless worker on quiet days, a winged queen once a flight
 * is likely, with the tile lit up in that case.
 */
class FlightTileService : TileService() {

    private data class TileBand(val fallbackLabel: String, val winged: Boolean)

    override fun onStartListening() {
        super.onStartListening()
        render()
    }

    override fun onClick() {
        super.onClick()
        openApp()
    }

    private fun render() {
        val tile = qsTile ?: return
        val data = HomeWidgetPlugin.getData(this)

        val percentage = data.getInt("_percentage", 0)
        // Band key written by 2.20+; fall back to the old percentage
        // thresholds right after an upgrade so the tile is never blank.
        // Mirrors AppWidgetProvider.kt and NuptialWidget.swift.
        var key = data.getString("_band", null).orEmpty()
        if (key.isEmpty()) {
            key = when {
                percentage <= 0 -> ""
                percentage < 50 -> "quiet"
                percentage < 60 -> "watchful"
                else -> "prime"
            }
        }

        val band = BANDS[key]
        val label = data.getString("_band_label", null)?.takeIf { it.isNotEmpty() }
            ?: band?.fallbackLabel
            ?: getString(R.string.widget_calculating)

        tile.label = label
        tile.icon = Icon.createWithResource(
            this,
            if (band?.winged == true) R.drawable.ic_qs_ant_queen
            else R.drawable.ic_qs_ant_worker
        )
        // Lit when a flight is on the cards, so the tile reads at a glance
        // even before you take in the words.
        tile.state = if (band?.winged == true) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = data.getString("_odds", null).orEmpty()
        }
        tile.contentDescription = getString(
            if (band?.winged == true) R.string.widget_content_description_queen
            else R.string.widget_content_description,
            label
        )
        tile.updateTile()
    }

    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        // startActivityAndCollapse(Intent) throws on Android 14+; it wants a
        // PendingIntent there.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private companion object {
        val BANDS = mapOf(
            "noFly" to TileBand("No-fly", false),
            "quiet" to TileBand("Quiet", false),
            "watchful" to TileBand("Watchful", false),
            "promising" to TileBand("Promising", true),
            "prime" to TileBand("Prime", true),
        )
    }
}
