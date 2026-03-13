import Foundation
@testable import LeetCodeLytics

/// Configurable mock for unit-testing ViewModels without hitting the network.
final class MockLeetCodeService: LeetCodeServiceProtocol {

    // MARK: - Configurable results

    var profileResult: Result<MatchedUser, Error> = .failure(URLError(.unknown))
    var questionsResult: Result<[ProblemCount], Error> = .failure(URLError(.unknown))
    var calendarResult: Result<StreakData, Error> = .failure(URLError(.unknown))
    var streakCounterResult: Result<StreakCounterResponse, Error> = .failure(URLError(.unknown))
    var submissionsResult: Result<[RecentSubmission], Error> = .failure(URLError(.unknown))
    var languageStatsResult: Result<[LanguageStat], Error> = .failure(URLError(.unknown))
    var skillStatsResult: Result<TagProblemCounts, Error> = .failure(URLError(.unknown))

    // MARK: - Call tracking

    private(set) var profileCallCount = 0
    private(set) var questionsCallCount = 0
    private(set) var calendarCallCount = 0
    private(set) var streakCounterCallCount = 0
    private(set) var submissionsCallCount = 0

    // MARK: - Protocol

    func fetchUserProfile(username: String) async throws -> MatchedUser {
        profileCallCount += 1
        return try profileResult.get()
    }

    func fetchAllQuestionsCount() async throws -> [ProblemCount] {
        questionsCallCount += 1
        return try questionsResult.get()
    }

    func fetchCalendar(username: String, year: Int?) async throws -> StreakData {
        calendarCallCount += 1
        return try calendarResult.get()
    }

    func fetchStreakCounter() async throws -> StreakCounterResponse {
        streakCounterCallCount += 1
        return try streakCounterResult.get()
    }

    func fetchRecentSubmissions(username: String, limit: Int) async throws -> [RecentSubmission] {
        submissionsCallCount += 1
        return try submissionsResult.get()
    }

    func fetchLanguageStats(username: String) async throws -> [LanguageStat] {
        return try languageStatsResult.get()
    }

    func fetchSkillStats(username: String) async throws -> TagProblemCounts {
        return try skillStatsResult.get()
    }
}

// MARK: - Fixture builders

extension MockLeetCodeService {
    static func makeMatchedUser() -> MatchedUser {
        MatchedUser(
            username: "spacewanderer",
            profile: UserProfileInfo(
                ranking: 327632,
                userAvatar: "https://assets.leetcode.com/users/spacewanderer/avatar.png",
                realName: "spaceTimeWanderer",
                reputation: 9
            ),
            submitStats: SubmitStats(
                acSubmissionNum: [
                    SubmissionCount(difficulty: "All",    count: 362, submissions: 1572),
                    SubmissionCount(difficulty: "Easy",   count: 134, submissions: 552),
                    SubmissionCount(difficulty: "Medium", count: 199, submissions: 914),
                    SubmissionCount(difficulty: "Hard",   count: 29,  submissions: 106)
                ],
                totalSubmissionNum: [
                    SubmissionCount(difficulty: "All",    count: 395, submissions: 2394),
                    SubmissionCount(difficulty: "Easy",   count: 138, submissions: 729),
                    SubmissionCount(difficulty: "Medium", count: 221, submissions: 1481),
                    SubmissionCount(difficulty: "Hard",   count: 36,  submissions: 184)
                ]
            ),
            badges: [
                UserBadge(id: "7588899", name: "Annual Badge",
                          icon: "https://assets.leetcode.com/badge.png",
                          creationDate: "2025-07-09")
            ]
        )
    }

    static func makeStreakData(submissionCalendar: String = "{}") -> StreakData {
        StreakData(streak: 10, totalActiveDays: 107,
                  activeYears: [2024, 2025], submissionCalendar: submissionCalendar)
    }

    static func makeProblemCounts() -> [ProblemCount] {
        [
            ProblemCount(difficulty: "All",    count: 3865),
            ProblemCount(difficulty: "Easy",   count: 930),
            ProblemCount(difficulty: "Medium", count: 2022),
            ProblemCount(difficulty: "Hard",   count: 913)
        ]
    }
}
