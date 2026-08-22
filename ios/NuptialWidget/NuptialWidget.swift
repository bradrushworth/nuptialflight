//
//  NuptialWidget.swift
//  NuptialWidget
//
//  iOS home-screen widget for the Ant Nuptial Flight Predictor — the
//  counterpart of the Android AppWidgetProvider. Reads the flight-likelihood
//  percentage the Flutter app publishes through the `home_widget` plugin into
//  the shared App Group, and renders the same emoji + severity colour language
//  as the Android widget (thresholds and palette kept in lockstep — change
//  one, change both).
//

import WidgetKit
import SwiftUI

private let appGroupId = "group.au.com.bitbot.nuptialflight"
private let percentageKey = "_percentage"

// Severity thresholds mirror AppWidgetProvider.kt.
private let amberThreshold = 50
private let greenThreshold = 60

struct FlightEntry: TimelineEntry {
    let date: Date
    let percentage: Int
}

struct FlightProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlightEntry {
        FlightEntry(date: Date(), percentage: 62)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlightEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlightEntry>) -> Void) {
        // The Flutter app reloads this widget's timeline whenever it saves a
        // new percentage (home_widget calls WidgetCenter for the kind below),
        // so the hourly refresh here is only a fallback for stale data.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [loadEntry()], policy: .after(next)))
    }

    private func loadEntry() -> FlightEntry {
        let pct = UserDefaults(suiteName: appGroupId)?.integer(forKey: percentageKey) ?? 0
        return FlightEntry(date: Date(), percentage: pct)
    }
}

// Palette mirrors android res/values/colors.xml (+ values-night variants),
// via dynamic colours so the widget follows light/dark mode.
private func backgroundColor(for percentage: Int) -> Color {
    func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { trait in
            let v = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((v >> 16) & 0xFF) / 255.0,
                green: CGFloat((v >> 8) & 0xFF) / 255.0,
                blue: CGFloat(v & 0xFF) / 255.0,
                alpha: 1.0
            )
        })
    }
    if percentage == 0 { return dynamic(0xE8EAED, 0x2A2C2F) }          // neutral
    if percentage < amberThreshold { return dynamic(0xE5A29A, 0x6E312B) } // low
    if percentage < greenThreshold { return dynamic(0xEFD98B, 0x6B5A1E) } // mid
    return dynamic(0xA5CF9F, 0x2E5231)                                  // high
}

// Emoji ladder mirrors AppWidgetProvider.getEmojiText().
private func emojiText(for percentage: Int) -> String {
    if percentage < 45 { return "\u{1F44E}" }
    if percentage < 50 { return "\u{1F90F}" }
    if percentage < 55 { return "\u{1F91E}" }
    if percentage < 60 { return "\u{1F41C}\u{1F44C}" }
    if percentage < 65 { return "\u{1F41C}\u{1F44D}" }
    if percentage < 70 { return "\u{1F41C}\u{1F4AA}" }
    return "\u{1F41C}\u{1FAF6}"
}

struct NuptialWidgetEntryView: View {
    var entry: FlightEntry

    var body: some View {
        VStack(spacing: 2) {
            Text("Ant\nNuptial\nFlight")
                .font(.system(size: 13, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.75))
            if entry.percentage == 0 {
                Text("Calculating")
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            } else {
                Text(emojiText(for: entry.percentage))
                    .font(.system(size: 26))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackgroundCompat(backgroundColor(for: entry.percentage))
        .accessibilityLabel(
            "Nuptial flight likelihood \(entry.percentage) percent. Opens the app."
        )
    }
}

private extension View {
    // iOS 17 requires containerBackground for widgets; earlier versions take a
    // plain background. This keeps one view working from iOS 14 through 17+.
    @ViewBuilder
    func widgetBackgroundCompat(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }
}

struct NuptialWidget: Widget {
    // The kind string must match the iOSName the Flutter side passes to
    // HomeWidget.updateWidget (lib/controller/widgets_mobile.dart).
    let kind: String = "NuptialWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightProvider()) { entry in
            NuptialWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Nuptial Flight")
        .description("Shows the likelihood of an ant nuptial flight today.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct NuptialWidgetBundle: WidgetBundle {
    var body: some Widget {
        NuptialWidget()
    }
}
