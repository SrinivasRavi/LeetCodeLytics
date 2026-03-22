import Foundation

// Single App Group UserDefaults instance shared across all widget files.
// Created once per process — never inside a render or function call.
let widgetGroupDefaults = UserDefaults(suiteName: "group.com.leetcodelytics.shared")

// File-level UTC calendar — created once per process.
private let backgroundUTCCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}()

/// Returns the asset name for the widget background based on solve state and current time.
///
/// State machine:
///   • Solved today (UTC)          → AstroWidget_Success (astronaut alone, safe)
///   • Streak intact, not solved   → AstroWidget_Rocket1–4 cycling every 6 UTC hours
///   • Streak broken (streak == 0) → AstroWidget_Broken
///
/// NOTE: streak is recomputed live from recentCalendar timestamps, NOT from the cached
/// anysolveStreak. anysolveStreak was computed at fetch time and goes stale at UTC midnight
/// (a 1-day streak becomes 0 at midnight if the user hasn't opened the app). recentCalendar
/// timestamps are time-invariant facts — StreakCalculator evaluates them against Date() so
/// the streak is always correct at the moment the widget renders.
func widgetBackgroundName(data: WidgetData, date: Date) -> String {
    if didSolveToday(in: data.recentCalendar) {
        return "AstroWidget_Success"
    }
    // Reconstruct SubmissionCalendar from recentCalendar string-keyed timestamps.
    let intCounts = Dictionary(uniqueKeysWithValues:
        data.recentCalendar.compactMap { k, v in Int(k).map { ($0, v) } }
    )
    let liveStreak = StreakCalculator.computeStreak(from: SubmissionCalendar(dailyCounts: intCounts))
    if liveStreak > 0 {
        let hour = backgroundUTCCalendar.component(.hour, from: date)
        return "AstroWidget_Rocket\(hour / 6 + 1)" // slot 0→1, 1→2, 2→3, 3→4
    }
    return "AstroWidget_Broken"
}
