import WidgetKit
import Foundation

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
        let entry = LeetCodeEntry(date: Date(), data: loadCached() ?? .placeholder)
        // Check again in 15 min as a background fallback.
        // The real refresh path is: app opens → DashboardViewModel writes App Group
        // → WidgetCenter.shared.reloadAllTimelines() → getTimeline called immediately.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadCached() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: "group.com.leetcodelytics.shared"),
              let data = defaults.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
