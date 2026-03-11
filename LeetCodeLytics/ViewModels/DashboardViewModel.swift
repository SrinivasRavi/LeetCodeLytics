import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var profile: MatchedUser?
    @Published var allQuestionsCount: [ProblemCount] = []
    @Published var streakData: StreakData?
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
        isLoading = true
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
            anysolveStreak = StreakCalculator.computeStreak(from: cal)
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }

        // DCC streak — requires auth; fail silently if not available
        do {
            let streak = try await service.fetchStreakCounter()
            dccStreak = streak.streakCount
        } catch {
            dccStreak = 0
        }

        isLoading = false
        CacheService.save(username, key: "lastUsername")
    }
}
