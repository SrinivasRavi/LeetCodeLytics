import Foundation

/// Self-contained network fetcher for the widget extension.
/// Cannot import from the main app target — all types are defined locally.
enum WidgetFetcher {
    private static let endpoint = URL(string: "https://leetcode.com/graphql")!
    private static let appGroupID = "group.com.leetcodelytics.shared"

    private static var username: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: "username") ?? ""
    }

    private static var credentials: (session: String, csrf: String) {
        let d = UserDefaults(suiteName: appGroupID)
        return (d?.string(forKey: "leetcodeSession") ?? "", d?.string(forKey: "csrfToken") ?? "")
    }

    static func fetch() async -> WidgetData? {
        let user = username
        guard !user.isEmpty else { return nil }

        // Sequential fetches keep peak memory low — widget extensions have ~30 MB budget.
        guard let counts = await fetchSolvedCounts(username: user) else { return nil }
        guard let calString = await fetchCalendarString(username: user) else { return nil }
        let dcc = (await fetchDCCStreak()) ?? 0
        let cal = SubmissionCalendar(jsonString: calString)
        let anysolve = StreakCalculator.computeStreak(from: cal)

        let cutoff = Date().timeIntervalSince1970 - Double(10 * 7 * 86400)
        let recentCal = Dictionary(
            cal.dailyCounts
                .filter { Double($0.key) >= cutoff }
                .map { (String($0.key), $0.value) },
            uniquingKeysWith: { first, _ in first }
        )

        return WidgetData(
            anysolveStreak: anysolve,
            dccStreak: dcc,
            easySolved: counts.easy,
            mediumSolved: counts.medium,
            hardSolved: counts.hard,
            recentCalendar: recentCal
        )
    }

    // MARK: - Private fetch helpers

    private struct SolvedCounts { let easy: Int; let medium: Int; let hard: Int }

    private static func fetchSolvedCounts(username: String) async -> SolvedCounts? {
        let query = """
        query getUserProfile($username: String!) {
          matchedUser(username: $username) {
            submitStats: submitStatsGlobal {
              acSubmissionNum { difficulty count }
            }
          }
        }
        """
        struct AcNum: Decodable { let difficulty: String; let count: Int }
        struct Stats: Decodable { let acSubmissionNum: [AcNum] }
        struct User: Decodable { let submitStats: Stats }

        guard let user: User = await graphQL(query: query, variables: ["username": username], key: "matchedUser") else { return nil }
        let nums = user.submitStats.acSubmissionNum
        return SolvedCounts(
            easy: nums.first { $0.difficulty == "Easy" }?.count ?? 0,
            medium: nums.first { $0.difficulty == "Medium" }?.count ?? 0,
            hard: nums.first { $0.difficulty == "Hard" }?.count ?? 0
        )
    }

    private static func fetchCalendarString(username: String) async -> String? {
        let query = """
        query userProfileCalendar($username: String!) {
          matchedUser(username: $username) {
            userCalendar {
              submissionCalendar
            }
          }
        }
        """
        struct Cal: Decodable { let submissionCalendar: String }
        struct Wrapper: Decodable { let userCalendar: Cal }

        guard let w: Wrapper = await graphQL(query: query, variables: ["username": username], key: "matchedUser") else { return nil }
        return w.userCalendar.submissionCalendar
    }

    private static func fetchDCCStreak() async -> Int? {
        let query = """
        query getStreakCounter {
          streakCounter { streakCount }
        }
        """
        struct Counter: Decodable { let streakCount: Int }
        guard let c: Counter = await graphQL(query: query, variables: [:], key: "streakCounter") else { return nil }
        return c.streakCount
    }

    private static func graphQL<T: Decodable>(query: String, variables: [String: Any], key: String) async -> T? {
        let creds = credentials
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        if !creds.session.isEmpty {
            request.setValue("LEETCODE_SESSION=\(creds.session); csrftoken=\(creds.csrf)", forHTTPHeaderField: "Cookie")
        }
        if !creds.csrf.isEmpty {
            request.setValue(creds.csrf, forHTTPHeaderField: "x-csrftoken")
        }
        let body: [String: Any] = ["query": query, "variables": variables]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = root["data"] as? [String: Any],
              let valueAny = dataDict[key], !(valueAny is NSNull),
              let valueData = try? JSONSerialization.data(withJSONObject: valueAny) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: valueData)
    }
}
