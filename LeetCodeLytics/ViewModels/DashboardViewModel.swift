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

    private let service: LeetCodeServiceProtocol
    private var activeFetch = false

    init(service: LeetCodeServiceProtocol = LeetCodeService.shared) {
        self.service = service
    }

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
        guard !activeFetch else { return }
        activeFetch = true
        defer { activeFetch = false }
        let cacheKey = "dashboard_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load(DashboardCache.self, key: cacheKey) {
            apply(cached)
        }

        // Only show loading spinner when there's no data at all
        isLoading = profile == nil
        errorMessage = nil

        // Run network work in an unstructured Task so it can't be cancelled by
        // the caller (e.g. SwiftUI's .refreshable task). withCheckedContinuation
        // keeps load() suspended — and the refresh spinner alive — until the
        // inner Task actually finishes.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                defer { continuation.resume() }

                async let profileTask = self.service.fetchUserProfile(username: username)
                async let questionsTask = self.service.fetchAllQuestionsCount()
                async let calendarTask = self.service.fetchCalendar(username: username)

                do {
                    let (p, q, c) = try await (profileTask, questionsTask, calendarTask)
                    self.profile = p
                    self.allQuestionsCount = q
                    self.streakData = c
                    let cal = SubmissionCalendar(jsonString: c.submissionCalendar)
                    self.submissionCalendar = cal
                    self.anysolveStreak = StreakCalculator.computeStreak(from: cal)

                    let cache = DashboardCache(
                        profile: p,
                        allQuestionsCount: q,
                        streakData: c,
                        dccStreak: self.dccStreak,
                        anysolveStreak: self.anysolveStreak
                    )
                    CacheService.save(cache, key: cacheKey)
                    CacheService.saveTimestamp(for: cacheKey)
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
                } catch {
                    self.errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
                }

                // DCC streak — requires auth; preserve existing value on failure
                do {
                    let streak = try await self.service.fetchStreakCounter()
                    self.dccStreak = streak.streakCount
                } catch {}

                self.isLoading = false
            }
        }
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
