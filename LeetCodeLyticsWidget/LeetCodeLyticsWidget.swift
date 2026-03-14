import WidgetKit
import SwiftUI

// MARK: - Shared background builder

private func astroBackground() -> some View {
    Image("AstroWidget1")
        .resizable()
        .aspectRatio(contentMode: .fill)
}

// MARK: - Small: Solved Streak

struct SolvedStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SolvedStreak", provider: LeetCodeProvider()) { entry in
            SmallSolvedWidgetView(entry: entry)
                .containerBackground(for: .widget) { astroBackground() }
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
                .containerBackground(for: .widget) { astroBackground() }
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
                .containerBackground(for: .widget) { astroBackground() }
        }
        .configurationDisplayName("LeetCodeLytics")
        .description("Both streaks and solved counts at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Large

struct LeetCodeLargeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LeetCodeLarge", provider: LeetCodeProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(for: .widget) { astroBackground() }
        }
        .configurationDisplayName("LeetCodeLytics")
        .description("Streaks, solved counts, and activity heatmap.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Bundle

@main
struct LeetCodeLyticsWidgetBundle: WidgetBundle {
    var body: some Widget {
        SolvedStreakWidget()
        DCCStreakWidget()
        LeetCodeMediumWidget()
        LeetCodeLargeWidget()
    }
}
