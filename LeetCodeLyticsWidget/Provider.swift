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
            let data = await WidgetFetcher.fetch() ?? loadCached() ?? .placeholder
            let entry = LeetCodeEntry(date: Date(), data: data)
            // Save fresh data back to App Group for next snapshot
            if let encoded = try? JSONEncoder().encode(data) {
                UserDefaults(suiteName: "group.com.leetcodelytics.shared")?.set(encoded, forKey: "widgetData")
            }
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func loadCached() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: "group.com.leetcodelytics.shared"),
              let data = defaults.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
