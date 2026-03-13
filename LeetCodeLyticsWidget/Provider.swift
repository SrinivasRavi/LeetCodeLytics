import WidgetKit
import Foundation

struct LeetCodeEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct LeetCodeProvider: TimelineProvider {
    func placeholder(in context: Context) -> LeetCodeEntry {
        LeetCodeEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LeetCodeEntry) -> Void) {
        let data = loadCached() ?? .placeholder
        completion(LeetCodeEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LeetCodeEntry>) -> Void) {
        Task {
            let now = Date()
            let maxAge: TimeInterval = 30 * 60 // 30 minutes

            // Use cached data if it was fetched recently — avoids network calls and
            // stays well within the widget extension's ~30 MB memory budget.
            let cached = loadCached()
            let cacheIsFresh = cached?.fetchedAt.map { now.timeIntervalSince($0) < maxAge } ?? false

            let data: WidgetData
            if cacheIsFresh, let fresh = cached {
                data = fresh
            } else {
                let fetched = await WidgetFetcher.fetch()
                data = fetched ?? cached ?? .placeholder
                if let encoded = try? JSONEncoder().encode(data) {
                    UserDefaults(suiteName: "group.com.leetcodelytics.shared")?.set(encoded, forKey: "widgetData")
                }
            }

            let entry = LeetCodeEntry(date: now, data: data)
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now)!
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func loadCached() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: "group.com.leetcodelytics.shared"),
              let data = defaults.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
