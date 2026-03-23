import XCTest
@testable import LeetAnalytics

/// Verifies that every Swift model correctly decodes the actual JSON shapes
/// returned by LeetCode's GraphQL API.
///
/// Fixtures are taken verbatim from real Postman responses (Success_Mar13).
/// If any of these tests fail after an API change, update the model AND the fixture.
final class ModelDecodeTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    // MARK: - UserBadge

    /// THE critical regression test — id is a STRING in the API, not an Int.
    /// This exact mismatch caused the Dashboard decode crash that persisted v1.0–v1.5.1.
    func testUserBadge_idIsString() throws {
        let json = """
        {"id":"7588899","name":"Annual Badge","icon":"https://assets.leetcode.com/badge.png","creationDate":"2025-07-09"}
        """
        let badge = try decode(UserBadge.self, from: json)
        XCTAssertEqual(badge.id, "7588899")
        XCTAssertEqual(badge.name, "Annual Badge")
        XCTAssertEqual(badge.creationDate, "2025-07-09")
    }

    func testUserBadge_missingOptionalFields() throws {
        let json = """
        {"id":null,"name":"Some Badge","icon":"https://assets.leetcode.com/badge.png","creationDate":null}
        """
        let badge = try decode(UserBadge.self, from: json)
        // `badgeID` is the raw API "id" field — null in this fixture.
        XCTAssertNil(badge.badgeID)
        // `id` (Identifiable) falls back to `name` when badgeID is absent.
        XCTAssertEqual(badge.id, "Some Badge")
        XCTAssertNil(badge.creationDate)
        XCTAssertEqual(badge.name, "Some Badge")
    }

    // MARK: - MatchedUser (full API fixture)

    func testMatchedUser_fullDecode() throws {
        let json = """
        {
          "username": "spacewanderer",
          "profile": {
            "ranking": 327632,
            "userAvatar": "https://assets.leetcode.com/users/spacewanderer/avatar_1553476653.png",
            "realName": "spaceTimeWanderer"
          },
          "submitStats": {
            "acSubmissionNum": [
              {"difficulty":"All","count":362,"submissions":1572},
              {"difficulty":"Easy","count":134,"submissions":552},
              {"difficulty":"Medium","count":199,"submissions":914},
              {"difficulty":"Hard","count":29,"submissions":106}
            ],
            "totalSubmissionNum": [
              {"difficulty":"All","count":395,"submissions":2394},
              {"difficulty":"Easy","count":138,"submissions":729},
              {"difficulty":"Medium","count":221,"submissions":1481},
              {"difficulty":"Hard","count":36,"submissions":184}
            ]
          },
          "badges": [
            {"id":"7588899","name":"Submission Badge","icon":"https://assets.leetcode.com/lg365.png","creationDate":"2025-07-19"},
            {"id":"7500932","name":"Annual Badge","icon":"https://assets.leetcode.com/lg25100.png","creationDate":"2025-07-09"}
          ]
        }
        """
        let user = try decode(MatchedUser.self, from: json)
        XCTAssertEqual(user.username, "spacewanderer")
        XCTAssertEqual(user.profile.ranking, 327632)
        XCTAssertEqual(user.profile.realName, "spaceTimeWanderer")
        XCTAssertEqual(user.submitStats.acSubmissionNum.count, 4)
        XCTAssertEqual(user.submitStats.acSubmissionNum.first { $0.difficulty == "All" }?.count, 362)
        XCTAssertEqual(user.submitStats.acSubmissionNum.first { $0.difficulty == "Easy" }?.count, 134)
        XCTAssertEqual(user.badges.count, 2)
        XCTAssertEqual(user.badges[0].id, "7588899")
        XCTAssertEqual(user.badges[1].id, "7500932")
    }

    func testMatchedUser_emptyBadges() throws {
        let json = """
        {
          "username": "test","profile":{"ranking":1,"userAvatar":"","realName":""},
          "submitStats":{"acSubmissionNum":[],"totalSubmissionNum":[]},"badges":[]
        }
        """
        let user = try decode(MatchedUser.self, from: json)
        XCTAssertTrue(user.badges.isEmpty)
    }

    /// Regression: realName and userAvatar must be optional so the decode does not crash
    /// when LeetCode returns null for users who have not set those fields.
    func testMatchedUser_nullRealNameAndAvatar_doesNotCrash() throws {
        let json = """
        {
          "username": "newuser",
          "profile": {
            "ranking": 0,
            "userAvatar": null,
            "realName": null
          },
          "submitStats": {"acSubmissionNum": [], "totalSubmissionNum": []},
          "badges": []
        }
        """
        let user = try decode(MatchedUser.self, from: json)
        XCTAssertEqual(user.username, "newuser")
        XCTAssertNil(user.profile.realName, "realName must decode as nil when API returns null")
        XCTAssertNil(user.profile.userAvatar, "userAvatar must decode as nil when API returns null")
        XCTAssertEqual(user.profile.ranking, 0)
    }

    // MARK: - ProblemCount

    func testProblemCount_allDifficulties() throws {
        let json = """
        [
          {"difficulty":"All","count":3865},
          {"difficulty":"Easy","count":930},
          {"difficulty":"Medium","count":2022},
          {"difficulty":"Hard","count":913}
        ]
        """
        let counts = try decode([ProblemCount].self, from: json)
        XCTAssertEqual(counts.count, 4)
        XCTAssertEqual(counts.first { $0.difficulty == "Easy" }?.count, 930)
        XCTAssertEqual(counts.first { $0.difficulty == "Hard" }?.count, 913)
    }

    // MARK: - StreakData / UserCalendarWrapper

    func testStreakData_fullDecode() throws {
        let json = """
        {
          "streak": 10,
          "totalActiveDays": 107,
          "submissionCalendar": "{\\"1767225600\\": 1, \\"1767312000\\": 5}"
        }
        """
        let data = try decode(StreakData.self, from: json)
        XCTAssertEqual(data.streak, 10)
        XCTAssertEqual(data.totalActiveDays, 107)
        XCTAssertFalse(data.submissionCalendar.isEmpty)
    }

    func testUserCalendarWrapper_nested() throws {
        let json = """
        {
          "userCalendar": {
            "streak": 5,
            "totalActiveDays": 50,
            "submissionCalendar": "{}"
          }
        }
        """
        let wrapper = try decode(UserCalendarWrapper.self, from: json)
        XCTAssertEqual(wrapper.userCalendar.streak, 5)
        XCTAssertEqual(wrapper.userCalendar.totalActiveDays, 50)
    }

    // MARK: - StreakCounterResponse

    func testStreakCounterResponse_currentDayCompleted() throws {
        let json = "{\"streakCount\":1,\"currentDayCompleted\":true}"
        let r = try decode(StreakCounterResponse.self, from: json)
        XCTAssertEqual(r.streakCount, 1)
        XCTAssertTrue(r.currentDayCompleted)
    }

    func testStreakCounterResponse_notCompleted() throws {
        let json = "{\"streakCount\":0,\"currentDayCompleted\":false}"
        let r = try decode(StreakCounterResponse.self, from: json)
        XCTAssertEqual(r.streakCount, 0)
        XCTAssertFalse(r.currentDayCompleted)
    }

    // MARK: - RecentSubmission

    func testRecentSubmission_fullDecode() throws {
        let json = """
        {
          "title":"LRU Cache",
          "titleSlug":"lru-cache",
          "timestamp":"1773250833",
          "statusDisplay":"Accepted",
          "lang":"python3"
        }
        """
        let sub = try decode(RecentSubmission.self, from: json)
        XCTAssertEqual(sub.title, "LRU Cache")
        XCTAssertEqual(sub.titleSlug, "lru-cache")
        XCTAssertEqual(sub.timestamp, "1773250833")
        XCTAssertEqual(sub.statusDisplay, "Accepted")
        XCTAssertEqual(sub.lang, "python3")
    }

    func testRecentSubmission_timestampIsString() throws {
        // timestamp must decode as String — if this changes to Int the app breaks
        let json = """
        {"title":"Two Sum","titleSlug":"two-sum","timestamp":"1700000000","statusDisplay":"Wrong Answer","lang":"swift"}
        """
        let sub = try decode(RecentSubmission.self, from: json)
        XCTAssertEqual(sub.timestamp, "1700000000")
        // Verify date conversion works correctly
        XCTAssertEqual(sub.date, Date(timeIntervalSince1970: 1_700_000_000))
    }

    func testRecentSubmission_listDecode() throws {
        let json = """
        [
          {"title":"LRU Cache","titleSlug":"lru-cache","timestamp":"1773250833","statusDisplay":"Accepted","lang":"python3"},
          {"title":"Merge Intervals","titleSlug":"merge-intervals","timestamp":"1773249858","statusDisplay":"Accepted","lang":"python3"}
        ]
        """
        let list = try decode([RecentSubmission].self, from: json)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].titleSlug, "lru-cache")
    }

    // MARK: - LanguageStat

    func testLanguageStat_fullDecode() throws {
        let json = """
        [
          {"languageName":"Python3","problemsSolved":169},
          {"languageName":"Java","problemsSolved":250},
          {"languageName":"C++","problemsSolved":73}
        ]
        """
        let stats = try decode([LanguageStat].self, from: json)
        XCTAssertEqual(stats.count, 3)
        XCTAssertEqual(stats.first { $0.languageName == "Java" }?.problemsSolved, 250)
    }

    // MARK: - TagStat / TagProblemCounts

    func testTagProblemCounts_fullDecode() throws {
        let json = """
        {
          "advanced": [
            {"tagName":"Dynamic Programming","tagSlug":"dynamic-programming","problemsSolved":49},
            {"tagName":"Backtracking","tagSlug":"backtracking","problemsSolved":14}
          ],
          "intermediate": [
            {"tagName":"Tree","tagSlug":"tree","problemsSolved":49},
            {"tagName":"Hash Table","tagSlug":"hash-table","problemsSolved":74}
          ],
          "fundamental": [
            {"tagName":"Array","tagSlug":"array","problemsSolved":192},
            {"tagName":"String","tagSlug":"string","problemsSolved":86}
          ]
        }
        """
        let counts = try decode(TagProblemCounts.self, from: json)
        XCTAssertEqual(counts.advanced.count, 2)
        XCTAssertEqual(counts.intermediate.count, 2)
        XCTAssertEqual(counts.fundamental.count, 2)
        XCTAssertEqual(counts.advanced.first { $0.tagSlug == "dynamic-programming" }?.problemsSolved, 49)
        XCTAssertEqual(counts.fundamental.first { $0.tagSlug == "array" }?.problemsSolved, 192)
    }

    // MARK: - Robustness: extra fields must not break decode

    func testMatchedUser_extraFieldsIgnored() throws {
        // LeetCode may add new fields; our models must not break
        let json = """
        {
          "username":"test","newUnknownField":"someValue",
          "profile":{"ranking":1,"userAvatar":"","realName":"","newField":true},
          "submitStats":{"acSubmissionNum":[],"totalSubmissionNum":[]},
          "badges":[]
        }
        """
        XCTAssertNoThrow(try decode(MatchedUser.self, from: json))
    }
}
