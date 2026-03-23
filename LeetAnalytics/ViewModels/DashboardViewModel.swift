import Foundation
import SwiftUI

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
    @Published var sessionExpired = false

    // v4: Unique Problem Tracking
    @Published var uniqueSolvedCount: Int = UniqueProblemStore.count()

    /// True when credentials exist in Keychain (any user).
    var isAuthenticated: Bool { KeychainService.hasCredentials() }

    /// True when the currently displayed profile matches the authenticated user.
    /// Used by StreakCard to decide whether to show DCC streak or sign-in prompt.
    @Published var isViewingOwnProfile = false

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

        // Refresh unique solved count from persistent store
        uniqueSolvedCount = UniqueProblemStore.count()

        // Only show loading spinner when there's no data at all
        isLoading = profile == nil
        errorMessage = nil

        await withCancellationSafeTask {
            async let profileTask = self.service.fetchUserProfile(username: username)
            async let questionsTask = self.service.fetchAllQuestionsCount()
            async let calendarTask = self.service.fetchCalendar(username: username)
            async let submissionsTask = self.service.fetchRecentSubmissions(username: username)

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
                UserDefaults.appGroup.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
            } catch {
                self.errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
            }

            // Process recent submissions for unique problem tracking.
            // This is a separate try — submission fetch failure should not affect Dashboard.
            if let submissions = try? await submissionsTask {
                let accepted = submissions
                    .filter { $0.statusDisplay == "Accepted" }
                    .map { (slug: $0.titleSlug, title: $0.title) }
                UniqueProblemStore.add(problems: accepted)
                self.uniqueSolvedCount = UniqueProblemStore.count()
            }

            // DCC streak — only meaningful when viewing your own profile.
            let authenticatedUsername = KeychainService.retrieve(key: KeychainService.authenticatedUsernameKey) ?? ""
            let isOwnProfile = !authenticatedUsername.isEmpty && username == authenticatedUsername
            self.isViewingOwnProfile = isOwnProfile
            if isOwnProfile {
                do {
                    let streak = try await self.service.fetchStreakCounter()
                    self.dccStreak = streak.streakCount
                    self.sessionExpired = false
                } catch LeetCodeError.invalidUsername where self.isAuthenticated {
                    self.sessionExpired = true
                } catch {}
            } else {
                self.dccStreak = 0
                self.sessionExpired = false
            }

            // Write widget data after all fetches complete
            if let cal = self.submissionCalendar {
                let recentCal = Self.recentCalendarSlice(from: cal)
                let widgetData = WidgetData(
                    anysolveStreak: self.anysolveStreak,
                    dccStreak: self.dccStreak,
                    isDCCAvailable: KeychainService.hasCredentials(),
                    easySolved: self.easySolved,
                    mediumSolved: self.mediumSolved,
                    hardSolved: self.hardSolved,
                    recentCalendar: recentCal,
                    fetchedAt: Date()
                )
                WidgetDataWriter.writeAllAndReload(widgetData)
            }

            self.isLoading = false
        }
    }

    /// Call after the user successfully logs in or signs out so the ViewModel
    /// re-checks Keychain and clears any expired-session state.
    func credentialsUpdated() {
        sessionExpired = false
    }

    /// Slices a full SubmissionCalendar down to the last `widgetHeatmapWeeks` weeks,
    /// converting Int keys to String keys for WidgetData.
    static func recentCalendarSlice(from cal: SubmissionCalendar) -> [String: Int] {
        let cutoff = Date().timeIntervalSince1970 - Double(widgetHeatmapWeeks * 7 * 86400)
        return Dictionary(
            cal.dailyCounts
                .filter { Double($0.key) >= cutoff }
                .map { (String($0.key), $0.value) },
            uniquingKeysWith: { first, _ in first }
        )
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
