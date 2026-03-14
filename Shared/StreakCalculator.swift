import Foundation

/// Computes a consecutive-day solve streak from submission calendar timestamps.
/// Works in UTC to match LeetCode's calendar timestamps.
/// Counts any day with ≥1 solve. Allows streak to be live if today not yet solved.
enum StreakCalculator {
    // File-level static — Calendar init is expensive; create once per process.
    private static let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func computeStreak(from calendar: SubmissionCalendar) -> Int {
        let counts = calendar.dailyCounts
        guard !counts.isEmpty else { return 0 }

        let cal = utcCalendar

        // Normalize all timestamps to start-of-day UTC
        let activeDays: Set<Date> = Set(
            counts.compactMap { (ts, count) -> Date? in
                guard count > 0 else { return nil }
                let date = Date(timeIntervalSince1970: Double(ts))
                return cal.startOfDay(for: date)
            }
        )

        guard !activeDays.isEmpty else { return 0 }

        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        // Streak is live if today or yesterday was solved
        var currentDay: Date
        if activeDays.contains(today) {
            currentDay = today
        } else if activeDays.contains(yesterday) {
            currentDay = yesterday
        } else {
            return 0
        }

        var streak = 0
        while activeDays.contains(currentDay) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: currentDay) else { break }
            currentDay = prev
        }

        return streak
    }
}
