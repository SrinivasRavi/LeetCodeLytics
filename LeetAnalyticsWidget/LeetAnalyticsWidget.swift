import WidgetKit
import SwiftUI

/// Reads the dim opacity from the shared App Group UserDefaults.
/// Falls back to 0.25 if not yet written.
private func widgetDimOpacity() -> Double {
    guard let defaults = widgetGroupDefaults,
          defaults.object(forKey: "widgetDimOpacity") != nil else { return 0.25 }
    return defaults.double(forKey: "widgetDimOpacity")
}

// MARK: - Small: Solved Streak

struct SolvedStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SolvedStreak", provider: LeetCodeProvider()) { entry in
            SmallSolvedWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        Image(widgetBackgroundName(data: entry.data, date: entry.date))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        Color.black.opacity(widgetDimOpacity())
                    }
                }
        }
        .configurationDisplayName("Solved Streak")
        .description("Your consecutive days with any solve.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Small: Daily Question Streak

struct DCCStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DCCStreak", provider: LeetCodeProvider()) { entry in
            SmallDCCWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        // DCC streak is independent of the solve streak that drives
                        // the rocket/broken background — always use the static background.
                        Image("AstroWidget_Success")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        Color.black.opacity(widgetDimOpacity())
                    }
                }
        }
        .configurationDisplayName("Daily Question Streak")
        .description("Your consecutive Daily Coding Challenge streak.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium

struct LeetCodeMediumWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LeetCodeMedium", provider: LeetCodeProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        Image(widgetBackgroundName(data: entry.data, date: entry.date))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        Color.black.opacity(widgetDimOpacity())
                    }
                }
        }
        .configurationDisplayName("LeetAnalytics")
        .description("Both streaks and solved counts at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Large

struct LeetCodeLargeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LeetCodeLarge", provider: LeetCodeProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        Image(widgetBackgroundName(data: entry.data, date: entry.date))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        Color.black.opacity(widgetDimOpacity())
                    }
                }
        }
        .configurationDisplayName("LeetAnalytics")
        .description("Streaks, solved counts, and activity heatmap.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Bundle

@main
struct LeetAnalyticsWidgetBundle: WidgetBundle {
    var body: some Widget {
        SolvedStreakWidget()
        DCCStreakWidget()
        LeetCodeMediumWidget()
        LeetCodeLargeWidget()
    }
}
