import Foundation

struct StreakData: Codable {
    let streak: Int
    let totalActiveDays: Int
    let submissionCalendar: String
}

struct UserCalendarWrapper: Codable {
    let userCalendar: StreakData
}

struct StreakCounterResponse: Codable {
    let streakCount: Int
    let currentDayCompleted: Bool
}
