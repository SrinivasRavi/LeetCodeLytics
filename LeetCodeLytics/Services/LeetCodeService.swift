import Foundation

enum LeetCodeError: LocalizedError {
    case invalidUsername
    case networkError(Error)
    case decodingError(Error)
    case unauthorized
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Username not found on LeetCode."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .decodingError(let e):
            return "Failed to decode response: \(e.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please check your session cookies."
        case .rateLimited:
            return "Rate limited by LeetCode. Please wait and try again."
        }
    }
}

final class LeetCodeService {
    static let shared = LeetCodeService()
    private init() {}

    private let endpoint = URL(string: "https://leetcode.com/graphql")!

    private func buildRequest(query: String, variables: [String: Any] = [:]) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )

        let session = UserDefaults.standard.string(forKey: "leetcodeSession") ?? ""
        let csrf = UserDefaults.standard.string(forKey: "csrfToken") ?? ""
        if !session.isEmpty || !csrf.isEmpty {
            request.setValue("LEETCODE_SESSION=\(session); csrftoken=\(csrf)", forHTTPHeaderField: "Cookie")
            request.setValue(csrf, forHTTPHeaderField: "x-csrftoken")
        }

        let body: [String: Any] = ["query": query, "variables": variables]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func execute<T: Decodable>(
        query: String,
        variables: [String: Any] = [:],
        responseKey: String
    ) async throws -> T {
        let request = buildRequest(query: query, variables: variables)
        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 403 { throw LeetCodeError.unauthorized }
            if http.statusCode == 429 { throw LeetCodeError.rateLimited }
        }

        do {
            let json = try JSONDecoder().decode([String: [String: T]].self, from: data)
            if let value = json["data"]?[responseKey] {
                return value
            }
            // Check for null matchedUser (invalid username)
            if let dataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataInner = dataDict["data"] as? [String: Any],
               dataInner[responseKey] is NSNull {
                throw LeetCodeError.invalidUsername
            }
            throw LeetCodeError.decodingError(
                NSError(domain: "LeetCodeService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Key '\(responseKey)' not found in response"])
            )
        } catch let error as LeetCodeError {
            throw error
        } catch {
            throw LeetCodeError.decodingError(error)
        }
    }

    // MARK: - Public API

    func fetchUserProfile(username: String) async throws -> MatchedUser {
        let query = """
        query getUserProfile($username: String!) {
          matchedUser(username: $username) {
            username
            profile { ranking userAvatar realName reputation }
            submitStats: submitStatsGlobal {
              acSubmissionNum { difficulty count submissions }
              totalSubmissionNum { difficulty count submissions }
            }
            badges { name icon }
          }
        }
        """
        return try await execute(query: query, variables: ["username": username], responseKey: "matchedUser")
    }

    func fetchAllQuestionsCount() async throws -> [ProblemCount] {
        let query = """
        query allQuestionsCount {
          allQuestionsCount { difficulty count }
        }
        """
        return try await execute(query: query, responseKey: "allQuestionsCount")
    }

    func fetchCalendar(username: String, year: Int? = nil) async throws -> StreakData {
        let query = """
        query userProfileCalendar($username: String!, $year: Int) {
          matchedUser(username: $username) {
            userCalendar(year: $year) {
              activeYears streak totalActiveDays submissionCalendar
            }
          }
        }
        """
        var vars: [String: Any] = ["username": username]
        if let y = year { vars["year"] = y }
        let wrapper: UserCalendarWrapper = try await execute(
            query: query, variables: vars, responseKey: "matchedUser"
        )
        return wrapper.userCalendar
    }

    func fetchStreakCounter() async throws -> StreakCounterResponse {
        let query = """
        query getStreakCounter {
          streakCounter { streakCount currentDayCompleted }
        }
        """
        return try await execute(query: query, responseKey: "streakCounter")
    }

    func fetchRecentSubmissions(username: String, limit: Int = 20) async throws -> [RecentSubmission] {
        let query = """
        query recentSubmissions($username: String!, $limit: Int) {
          recentSubmissionList(username: $username, limit: $limit) {
            title titleSlug timestamp statusDisplay lang
          }
        }
        """
        return try await execute(
            query: query,
            variables: ["username": username, "limit": limit],
            responseKey: "recentSubmissionList"
        )
    }

    func fetchContestRanking(username: String) async throws -> ContestRanking? {
        let query = """
        query userContestRanking($username: String!) {
          userContestRankingInfo(username: $username) {
            rating globalRanking localRanking topPercentage
            badge { name icon }
          }
        }
        """
        return try await execute(
            query: query,
            variables: ["username": username],
            responseKey: "userContestRankingInfo"
        )
    }

    func fetchContestHistory(username: String) async throws -> [ContestHistory] {
        let query = """
        query userContestHistory($username: String!) {
          userContestRankingInfo(username: $username) {
            contestHistory {
              attended trendDirection problemsSolved totalProblems
              finishTimeInSeconds rating ranking
              contest { title startTime }
            }
          }
        }
        """
        struct HistoryWrapper: Decodable {
            let contestHistory: [ContestHistory]?
        }
        let wrapper: HistoryWrapper = try await execute(
            query: query,
            variables: ["username": username],
            responseKey: "userContestRankingInfo"
        )
        return wrapper.contestHistory ?? []
    }

    func fetchLanguageStats(username: String) async throws -> [LanguageStat] {
        let query = """
        query languageStats($username: String!) {
          matchedUser(username: $username) {
            languageProblemCount { languageName problemsSolved }
          }
        }
        """
        let wrapper: LanguageStatsMatchedUser = try await execute(
            query: query,
            variables: ["username": username],
            responseKey: "matchedUser"
        )
        return wrapper.languageProblemCount
    }

    func fetchSkillStats(username: String) async throws -> TagProblemCounts {
        let query = """
        query skillStats($username: String!) {
          matchedUser(username: $username) {
            tagProblemCounts {
              advanced { tagName tagSlug problemsSolved }
              intermediate { tagName tagSlug problemsSolved }
              fundamental { tagName tagSlug problemsSolved }
            }
          }
        }
        """
        let wrapper: SkillStatsMatchedUser = try await execute(
            query: query,
            variables: ["username": username],
            responseKey: "matchedUser"
        )
        return wrapper.tagProblemCounts
    }
}
