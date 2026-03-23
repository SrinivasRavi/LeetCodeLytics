import XCTest
@testable import LeetAnalytics

final class StreakCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// Returns the UTC start-of-day timestamp for N days before today.
    private func ts(daysAgo: Int) -> Int {
        let today = utcCalendar.startOfDay(for: Date())
        let date = utcCalendar.date(byAdding: .day, value: -daysAgo, to: today)!
        return Int(date.timeIntervalSince1970)
    }

    private func makeCalendar(_ entries: [Int: Int]) -> SubmissionCalendar {
        var pairs: [String] = []
        for (key, val) in entries {
            pairs.append("\"\(key)\": \(val)")
        }
        return SubmissionCalendar(jsonString: "{" + pairs.joined(separator: ",") + "}")
    }

    // MARK: - Edge cases

    func testEmptyCalendar_returnsZero() {
        let cal = SubmissionCalendar(jsonString: "{}")
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 0)
    }

    func testOnlyOldSolves_returnsZero() {
        // Solves 5+ days ago with no recent activity → streak is 0
        let cal = makeCalendar([ts(daysAgo: 5): 3, ts(daysAgo: 6): 2])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 0)
    }

    func testZeroCountEntry_notCounted() {
        // count=0 means nothing was solved that day
        let cal = makeCalendar([ts(daysAgo: 0): 0])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 0)
    }

    // MARK: - Live streak (today / yesterday)

    func testSolvedToday_streakIsOne() {
        let cal = makeCalendar([ts(daysAgo: 0): 2])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 1)
    }

    func testSolvedYesterdayOnly_streakIsOne() {
        // Streak is still live if yesterday was solved
        let cal = makeCalendar([ts(daysAgo: 1): 1])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 1)
    }

    func testSolvedTodayAndYesterday_streakIsTwo() {
        let cal = makeCalendar([ts(daysAgo: 0): 1, ts(daysAgo: 1): 1])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 2)
    }

    // MARK: - Consecutive streaks

    func testThreeConsecutiveDaysEndingToday() {
        let cal = makeCalendar([
            ts(daysAgo: 0): 3,
            ts(daysAgo: 1): 2,
            ts(daysAgo: 2): 1
        ])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 3)
    }

    func testFiveConsecutiveDaysEndingYesterday() {
        let cal = makeCalendar([
            ts(daysAgo: 1): 1,
            ts(daysAgo: 2): 1,
            ts(daysAgo: 3): 1,
            ts(daysAgo: 4): 1,
            ts(daysAgo: 5): 1
        ])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 5)
    }

    // MARK: - Broken streaks

    func testGapBreaksStreak_onlyYesterdayAndThreeDaysAgo() {
        // Yesterday: solved. Two days ago: not solved. Three days ago: solved.
        // Streak starting from yesterday is 1 (broken by gap)
        let cal = makeCalendar([
            ts(daysAgo: 1): 2,
            ts(daysAgo: 3): 4
        ])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 1)
    }

    func testGapBreaksStreak_solvedTodayAfterGap() {
        let cal = makeCalendar([
            ts(daysAgo: 0): 1,
            ts(daysAgo: 5): 1  // old solve, no bridge
        ])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 1)
    }

    // MARK: - Multiple solves same day

    func testMultipleSolvesSameDay_countedOnce() {
        let cal = makeCalendar([ts(daysAgo: 0): 10])
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 1)
    }

    // MARK: - Long streak

    func testTenDayStreak() {
        var entries: [Int: Int] = [:]
        for i in 0..<10 {
            entries[ts(daysAgo: i)] = 1
        }
        let cal = makeCalendar(entries)
        XCTAssertEqual(StreakCalculator.computeStreak(from: cal), 10)
    }
}
