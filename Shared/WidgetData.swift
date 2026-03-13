import Foundation

/// Data written by the main app and read by the widget extension.
/// Stored in App Group UserDefaults under key "widgetData".
struct WidgetData: Codable {
    let anysolveStreak: Int
    let dccStreak: Int
    let easySolved: Int
    let mediumSolved: Int
    let hardSolved: Int
    /// Unix timestamp strings → solve count, covering the last 10 weeks.
    let recentCalendar: [String: Int]

    static let placeholder = WidgetData(
        anysolveStreak: 0,
        dccStreak: 0,
        easySolved: 0,
        mediumSolved: 0,
        hardSolved: 0,
        recentCalendar: [:]
    )
}
