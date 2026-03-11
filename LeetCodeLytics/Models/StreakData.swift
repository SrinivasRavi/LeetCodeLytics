import Foundation

struct StreakData: Codable {
    let streak: Int
    let totalActiveDays: Int
    let activeYears: [Int]
    let submissionCalendar: String
}

struct UserCalendarWrapper: Codable {
    let userCalendar: StreakData
}

struct CalendarMatchedUser: Codable {
    let matchedUser: UserCalendarWrapper
}

struct StreakCounterResponse: Codable {
    let streakCount: Int
    let currentDayCompleted: Bool
}
