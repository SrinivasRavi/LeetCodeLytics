import Foundation

struct SubmissionCalendar {
    /// Parsed from the JSON string returned by LeetCode's submissionCalendar field.
    /// Keys are Unix timestamps (as strings), values are solve counts.
    let dailyCounts: [Int: Int]

    /// Direct init from an already-parsed [Int: Int] map (used by widget background logic
    /// to reconstruct a calendar from WidgetData.recentCalendar without re-parsing JSON).
    init(dailyCounts: [Int: Int]) {
        self.dailyCounts = dailyCounts
    }

    init(jsonString: String) {
        guard
            let data = jsonString.data(using: .utf8),
            let raw = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            dailyCounts = [:]
            return
        }
        var result: [Int: Int] = [:]
        for (key, value) in raw {
            if let ts = Int(key) {
                result[ts] = value
            }
        }
        dailyCounts = result
    }
}
