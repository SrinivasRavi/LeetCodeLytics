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

        // Single entry — keeps peak memory minimal.
        // WidgetKit pre-renders ALL timeline entries into snapshot bitmaps.
        // The large widget snapshot alone is ~5 MB. With 5 entries × 4 widget kinds,
        // WidgetKit could retain ~100 MB of snapshots — far exceeding the 30 MB limit.
        // One entry = one snapshot per widget kind — safe.
        let entry = LeetCodeEntry(date: now, data: data)

        // Schedule the next refresh at the next UTC 6-hour boundary so the rocket
        // background still cycles (00:00, 06:00, 12:00, 18:00). The main app also
        // calls reloadAllTimelines() on every Dashboard load, which replaces this
        // timeline immediately with fresh data.
        let todayStart = providerUTCCalendar.startOfDay(for: now)
        let currentHour = providerUTCCalendar.component(.hour, from: now)
        let nextSlotHour = ((currentHour / 6) + 1) * 6  // next 6-hour boundary
        let refreshAt: Date
        if nextSlotHour >= 24 {
            // Next boundary is tomorrow 00:00 UTC + 1 min buffer
            refreshAt = providerUTCCalendar.date(byAdding: .minute, value: 1,
                to: providerUTCCalendar.date(byAdding: .day, value: 1, to: todayStart)!)!
        } else {
            refreshAt = providerUTCCalendar.date(byAdding: .hour, value: nextSlotHour, to: todayStart)!
        }

        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func loadCached() -> WidgetData? {
        guard let defaults = widgetGroupDefaults,
              let data = defaults.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
