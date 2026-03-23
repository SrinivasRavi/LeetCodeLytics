import Foundation
import WidgetKit

/// Centralised widget data persistence. Eliminates the manual copy-construction pattern
/// that appeared in DashboardViewModel, LeetAnalyticsApp, and SettingsView — each of which
/// was creating a new WidgetData with a memberwise init and manually copying all 8 fields.
/// One missed field = silent data loss.
///
/// Lives in Shared/ so both the app and widget targets can use it. Uses the App Group
/// suite name directly (not UserDefaults.appGroup which is app-target only).
enum WidgetDataWriter {
    private static let key = "widgetData"
    private static let suiteName = "group.com.leetanalytics.shared"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Reads the current WidgetData from App Group, or nil if not yet written.
    static func read() -> WidgetData? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    /// Full write — replaces all fields. Called by DashboardViewModel after a complete load.
    static func writeAll(_ widgetData: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(widgetData) else { return }
        defaults?.set(encoded, forKey: key)
    }

    /// Partial update — only replaces `anysolveStreak` and `recentCalendar`, preserving
    /// all other fields from the last full write. Used by Background App Refresh which
    /// only fetches the calendar (not profile or DCC streak).
    /// Returns the updated recentCalendar for `didSolveToday` scheduling.
    @discardableResult
    static func updateCalendar(anysolveStreak: Int, recentCalendar: [String: Int]) -> [String: Int] {
        guard let current = read() else { return recentCalendar }
        let updated = WidgetData(
            anysolveStreak: anysolveStreak,
            dccStreak: current.dccStreak,
            isDCCAvailable: current.isDCCAvailable,
            easySolved: current.easySolved,
            mediumSolved: current.mediumSolved,
            hardSolved: current.hardSolved,
            recentCalendar: recentCalendar,
            fetchedAt: Date()
        )
        writeAll(updated)
        return recentCalendar
    }

    /// Marks DCC as unavailable (e.g. after sign-out) without touching any other field.
    static func markDCCUnavailable() {
        guard let current = read() else { return }
        let updated = WidgetData(
            anysolveStreak: current.anysolveStreak,
            dccStreak: current.dccStreak,
            isDCCAvailable: false,
            easySolved: current.easySolved,
            mediumSolved: current.mediumSolved,
            hardSolved: current.hardSolved,
            recentCalendar: current.recentCalendar,
            fetchedAt: current.fetchedAt
        )
        writeAll(updated)
    }

    /// Convenience: write + reload all widget timelines.
    static func writeAllAndReload(_ widgetData: WidgetData) {
        writeAll(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
