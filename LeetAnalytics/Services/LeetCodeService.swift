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
    static let shared: LeetCodeService = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return LeetCodeService(session: URLSession(configuration: config))
    }()

    private let session: URLSession

    init(session: URLSession) {
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
        // Disable automatic cookie jar — we build the Cookie header manually so stale
        // LEETCODE_SESSION cookies in the jar can never leak when the user is signed out.
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )

        let keychainSession  = KeychainService.retrieve(key: KeychainService.sessionKey) ?? ""
        let keychainCsrf     = KeychainService.retrieve(key: KeychainService.csrfKey) ?? ""

        // csrftoken from the jar is acceptable for unauthenticated requests (it is not a session
        // credential — it is just CSRF protection required by LeetCode's GraphQL endpoint).
        // We only fall back to the jar when Keychain has no user-provided csrftoken.
        let jarCsrf = HTTPCookieStorage.shared
            .cookies(for: endpoint)?
            .first(where: { $0.name == "csrftoken" })?.value ?? ""
        let effectiveCsrf = keychainCsrf.isEmpty ? jarCsrf : keychainCsrf

        // Build Cookie header manually. LEETCODE_SESSION comes from Keychain only — never the jar.
        if !keychainSession.isEmpty {
            request.setValue(
                "LEETCODE_SESSION=\(keychainSession); csrftoken=\(effectiveCsrf)",
                forHTTPHeaderField: "Cookie"
            )
        } else if !effectiveCsrf.isEmpty {
            // No session — send only csrftoken so public queries still work.
            request.setValue("csrftoken=\(effectiveCsrf)", forHTTPHeaderField: "Cookie")
        }

        // x-csrftoken must always be set explicitly — not sent automatically by URLSession.
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
            profile { ranking userAvatar realName }
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
              streak totalActiveDays submissionCalendar
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

    func fetchProblemsForTag(tagSlug: String, limit: Int = 5) async throws -> QuestionListResponse {
        let query = """
        query questionList($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
          questionList(categorySlug: $categorySlug, limit: $limit, skip: $skip, filters: $filters) {
            totalNum
            data {
              questionFrontendId
              title
              titleSlug
              difficulty
            }
          }
        }
        """
        return try await execute(
            query: query,
            variables: [
                "categorySlug": "",
                "limit": limit,
                "skip": 0,
                "filters": ["tags": [tagSlug]]
            ],
            responseKey: "questionList"
        )
    }
}
