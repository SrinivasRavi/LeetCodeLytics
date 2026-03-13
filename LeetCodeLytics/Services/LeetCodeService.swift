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

final class LeetCodeService: LeetCodeServiceProtocol {
    static let shared = LeetCodeService()

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private let endpoint = URL(string: "https://leetcode.com/graphql")!

    /// Call once at app launch. GETs leetcode.com so URLSession's shared cookie jar
    /// receives a fresh csrftoken — required for all GraphQL POST requests.
    func bootstrapCSRF() async {
        let leetcodeURL = URL(string: "https://leetcode.com/")!
        let alreadyHasCsrf = HTTPCookieStorage.shared
            .cookies(for: leetcodeURL)?
            .contains(where: { $0.name == "csrftoken" }) ?? false
        guard !alreadyHasCsrf else { return }

        var req = URLRequest(url: leetcodeURL)
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        req.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        _ = try? await session.data(for: req)
    }

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
        let userCsrf = UserDefaults.standard.string(forKey: "csrfToken") ?? ""

        // Read csrftoken from shared cookie jar (set by bootstrapCSRF) if user hasn't provided one
        let jarCsrf = HTTPCookieStorage.shared
            .cookies(for: endpoint)?
            .first(where: { $0.name == "csrftoken" })?.value ?? ""
        let effectiveCsrf = userCsrf.isEmpty ? jarCsrf : userCsrf

        // Cookie header: always include LEETCODE_SESSION if provided;
        // csrftoken in Cookie header only when user-provided (jar sends it automatically otherwise)
        if !session.isEmpty {
            request.setValue("LEETCODE_SESSION=\(session); csrftoken=\(effectiveCsrf)", forHTTPHeaderField: "Cookie")
        }

        // x-csrftoken must always be set explicitly — not sent automatically by URLSession
        if !effectiveCsrf.isEmpty {
            request.setValue(effectiveCsrf, forHTTPHeaderField: "x-csrftoken")
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
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 403 { throw LeetCodeError.unauthorized }
            if http.statusCode == 429 { throw LeetCodeError.rateLimited }
        }

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = root["data"] as? [String: Any] else {
            let preview = String(data: data.prefix(300), encoding: .utf8) ?? "non-UTF8"
            throw LeetCodeError.decodingError(
                NSError(domain: "LeetCodeService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(preview)"])
            )
        }
        let valueAny = dataDict[responseKey]
        guard let valueAny, !(valueAny is NSNull) else {
            throw LeetCodeError.invalidUsername
        }
        do {
            let valueData = try JSONSerialization.data(withJSONObject: valueAny)
            return try JSONDecoder().decode(T.self, from: valueData)
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
            badges { id name icon creationDate }
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
