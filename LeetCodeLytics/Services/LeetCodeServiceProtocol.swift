import Foundation

protocol LeetCodeServiceProtocol {
    func fetchUserProfile(username: String) async throws -> MatchedUser
    func fetchAllQuestionsCount() async throws -> [ProblemCount]
    func fetchCalendar(username: String, year: Int?) async throws -> StreakData
    func fetchStreakCounter() async throws -> StreakCounterResponse
    func fetchRecentSubmissions(username: String, limit: Int) async throws -> [RecentSubmission]
    func fetchLanguageStats(username: String) async throws -> [LanguageStat]
    func fetchSkillStats(username: String) async throws -> TagProblemCounts
}

extension LeetCodeServiceProtocol {
    func fetchCalendar(username: String) async throws -> StreakData {
        try await fetchCalendar(username: username, year: nil)
    }

    func fetchRecentSubmissions(username: String) async throws -> [RecentSubmission] {
        try await fetchRecentSubmissions(username: username, limit: 20)
    }
}
