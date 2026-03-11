import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var profile: MatchedUser?
    @Published var allQuestionsCount: [ProblemCount] = []
    @Published var streakData: StreakData?
    @Published var submissionCalendar: SubmissionCalendar?
    @Published var dccStreak: Int = 0
    @Published var anysolveStreak: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    var easySolved: Int { profile?.submitStats.acSubmissionNum.first { $0.difficulty == "Easy" }?.count ?? 0 }
    var mediumSolved: Int { profile?.submitStats.acSubmissionNum.first { $0.difficulty == "Medium" }?.count ?? 0 }
    var hardSolved: Int { profile?.submitStats.acSubmissionNum.first { $0.difficulty == "Hard" }?.count ?? 0 }
    var totalSolved: Int { profile?.submitStats.acSubmissionNum.first { $0.difficulty == "All" }?.count ?? 0 }
    var totalEasy: Int { allQuestionsCount.first { $0.difficulty == "Easy" }?.count ?? 0 }
    var totalMedium: Int { allQuestionsCount.first { $0.difficulty == "Medium" }?.count ?? 0 }
    var totalHard: Int { allQuestionsCount.first { $0.difficulty == "Hard" }?.count ?? 0 }

    var totalSubmissions: Int {
        profile?.submitStats.totalSubmissionNum.first { $0.difficulty == "All" }?.submissions ?? 0
    }
    var totalAccepted: Int {
        profile?.submitStats.acSubmissionNum.first { $0.difficulty == "All" }?.submissions ?? 0
    }
    var acceptanceRate: Double {
        guard totalSubmissions > 0 else { return 0 }
        return Double(totalAccepted) / Double(totalSubmissions) * 100
    }

    func load(username: String) async {
        let cacheKey = "dashboard_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load(DashboardCache.self, key: cacheKey) {
            apply(cached)
        }

        // Only show loading spinner when there's no data at all
        isLoading = profile == nil
        errorMessage = nil

        async let profileTask = service.fetchUserProfile(username: username)
        async let questionsTask = service.fetchAllQuestionsCount()
        async let calendarTask = service.fetchCalendar(username: username)

        do {
            let (fetchedProfile, fetchedQuestions, fetchedCalendar) =
                try await (profileTask, questionsTask, calendarTask)
            profile = fetchedProfile
            allQuestionsCount = fetchedQuestions
            streakData = fetchedCalendar
            let cal = SubmissionCalendar(jsonString: fetchedCalendar.submissionCalendar)
            submissionCalendar = cal
            anysolveStreak = StreakCalculator.computeStreak(from: cal)

            let cache = DashboardCache(
                profile: fetchedProfile,
                allQuestionsCount: fetchedQuestions,
                streakData: fetchedCalendar,
                dccStreak: dccStreak,
                anysolveStreak: anysolveStreak
            )
            CacheService.save(cache, key: cacheKey)
            CacheService.saveTimestamp(for: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
        } catch {
            // Only surface error if we have no cached data to show
            if profile == nil {
                errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
            }
        }

        // DCC streak — requires auth; fail silently if not available
        do {
            let streak = try await service.fetchStreakCounter()
            dccStreak = streak.streakCount
        } catch {
            dccStreak = 0
        }

        isLoading = false
    }

    private func apply(_ cache: DashboardCache) {
        profile = cache.profile
        allQuestionsCount = cache.allQuestionsCount
        streakData = cache.streakData
        submissionCalendar = SubmissionCalendar(jsonString: cache.streakData.submissionCalendar)
        dccStreak = cache.dccStreak
        anysolveStreak = cache.anysolveStreak
    }
}

private struct DashboardCache: Codable {
    let profile: MatchedUser
    let allQuestionsCount: [ProblemCount]
    let streakData: StreakData
    let dccStreak: Int
    let anysolveStreak: Int
}
