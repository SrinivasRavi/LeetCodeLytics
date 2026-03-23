import WidgetKit
import Foundation

// File-level UTC calendar — created once per process, shared across all provider calls.
private let providerUTCCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}()

struct LeetCodeEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct LeetCodeProvider: TimelineProvider {

    // Called synchronously for the widget gallery placeholder.
    // Must return immediately — never access network or slow I/O here.
    func placeholder(in context: Context) -> LeetCodeEntry {
        LeetCodeEntry(date: Date(), data: .placeholder)
    }

    // Called for the widget gallery preview and when the widget is first added.
    // Read from App Group — synchronous, instant.
    func getSnapshot(in context: Context, completion: @escaping (LeetCodeEntry) -> Void) {
        completion(LeetCodeEntry(date: Date(), data: loadCached() ?? .placeholder))
    }

    // Called when WidgetKit needs a new timeline.
    //
    // Design: the widget NEVER makes its own network calls.
    // The main app (DashboardViewModel.load) writes fresh WidgetData to the App Group
    // and calls WidgetCenter.shared.reloadAllTimelines() on every Dashboard refresh.
    // That reload triggers getTimeline immediately with up-to-date data.
    //
    // Why no network here: widget extensions have a hard ~30 MB memory budget.
    // Three sequential GraphQL calls (profile + calendar + DCC) reliably exceed it
    // for users with significant submission history — crashing the extension and
    // causing iOS to show the "Please adopt containerBackground API" fallback.
    func getTimeline(in context: Context, completion: @escaping (Timeline<LeetCodeEntry>) -> Void) {
        let data = loadCached() ?? .placeholder
        let now = Date()
        let todayStart = providerUTCCalendar.startOfDay(for: now)

        // Entry for the current moment (picks up the right rocket slot or success/broken).
        var entries = [LeetCodeEntry(date: now, data: data)]

        // Pre-compute entries at remaining UTC 6-hour boundaries so the rocket image
        // advances automatically without any network call or app interaction.
        for hour in [6, 12, 18] {
            if let boundary = providerUTCCalendar.date(byAdding: .hour, value: hour, to: todayStart),
               boundary > now {
                entries.append(LeetCodeEntry(date: boundary, data: data))
            }
        }

        // Explicit entry at UTC midnight. widgetBackgroundName recomputes the streak live
        // from recentCalendar timestamps at render time, so this entry will show Broken
        // immediately if the user did not solve during the previous UTC day — no background
        // refresh or app open required. The same data payload is reused; only entry.date
        // changes, which is what StreakCalculator and didSolveToday evaluate against Date().
        let nextMidnight = providerUTCCalendar.date(byAdding: .day, value: 1, to: todayStart)!
        entries.append(LeetCodeEntry(date: nextMidnight, data: data))

        // Refresh policy: UTC midnight + 5 min. Triggers a fresh getTimeline so the next
        // day's entries (06:00, 12:00, 18:00, midnight) are computed with up-to-date data.
        // Background App Refresh (or a Dashboard open) may call reloadAllTimelines()
        // earlier and discard these entries; that's fine.
        let refreshAt = providerUTCCalendar.date(byAdding: .minute, value: 5, to: nextMidnight)!
        completion(Timeline(entries: entries, policy: .after(refreshAt)))
    }

    private func loadCached() -> WidgetData? {
        guard let defaults = widgetGroupDefaults,
              let data = defaults.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
