import XCTest
@testable import LeetCodeLytics

/// Tests LeetCodeService.execute<T> robustness via MockURLProtocol.
/// Each test configures a raw HTTP response and asserts the correct
/// Swift result (decoded value or specific LeetCodeError).
final class LeetCodeServiceExecuteTests: XCTestCase {

    private var service: LeetCodeService!

    override func setUp() {
        super.setUp()
        service = LeetCodeService(session: MockURLProtocol.makeSession())
        MockURLProtocol.responseProvider = nil
    }

    // MARK: - Helpers

    private func respond(status: Int = 200, json: String) {
        let data = Data(json.utf8)
        MockURLProtocol.responseProvider = { _ in (status, data) }
    }

    // MARK: - Happy path

    func testFetchUserProfile_validResponse_decodesCorrectly() async throws {
        respond(json: """
        {
          "data": {
            "matchedUser": {
              "username": "spacewanderer",
              "profile": {"ranking":327632,"userAvatar":"","realName":"spaceTimeWanderer","reputation":9},
              "submitStats": {
                "acSubmissionNum": [{"difficulty":"All","count":362,"submissions":1572}],
                "totalSubmissionNum": [{"difficulty":"All","count":395,"submissions":2394}]
              },
              "badges": [{"id":"7588899","name":"Annual Badge","icon":"","creationDate":"2025-07-09"}]
            }
          }
        }
        """)
        let user = try await service.fetchUserProfile(username: "spacewanderer")
        XCTAssertEqual(user.username, "spacewanderer")
        XCTAssertEqual(user.profile.ranking, 327632)
        XCTAssertEqual(user.badges[0].id, "7588899")
    }

    func testFetchAllQuestionsCount_validResponse_decodesCorrectly() async throws {
        respond(json: """
        {
          "data": {
            "allQuestionsCount": [
              {"difficulty":"All","count":3865},
              {"difficulty":"Easy","count":930}
            ]
          }
        }
        """)
        let counts = try await service.fetchAllQuestionsCount()
        XCTAssertEqual(counts.count, 2)
        XCTAssertEqual(counts.first { $0.difficulty == "Easy" }?.count, 930)
    }

    func testFetchRecentSubmissions_validResponse_decodesCorrectly() async throws {
        respond(json: """
        {
          "data": {
            "recentSubmissionList": [
              {"title":"LRU Cache","titleSlug":"lru-cache","timestamp":"1773250833","statusDisplay":"Accepted","lang":"python3"}
            ]
          }
        }
        """)
        let subs = try await service.fetchRecentSubmissions(username: "spacewanderer", limit: 20)
        XCTAssertEqual(subs.count, 1)
        XCTAssertEqual(subs[0].title, "LRU Cache")
    }

    // MARK: - Robustness: extra fields must not cause failure

    func testExtraFieldsInResponse_stillDecodes() async throws {
        respond(json: """
        {
          "data": {
            "matchedUser": {
              "username": "test",
              "profile": {"ranking":1,"userAvatar":"","realName":"","reputation":0},
              "submitStats": {"acSubmissionNum":[],"totalSubmissionNum":[]},
              "badges": [],
              "unknownNewField": "someValue"
            },
            "anotherUnknownTopLevelKey": 123
          },
          "extensions": {"cost": {"requestedQueryCost": 1}}
        }
        """)
        let user = try await service.fetchUserProfile(username: "test")
        XCTAssertEqual(user.username, "test")
    }

    func testErrorsArrayAlongsideData_stillDecodes() async throws {
        // GraphQL can return partial data + errors simultaneously
        respond(json: """
        {
          "data": {
            "matchedUser": {
              "username": "test",
              "profile": {"ranking":1,"userAvatar":"","realName":"","reputation":0},
              "submitStats": {"acSubmissionNum":[],"totalSubmissionNum":[]},
              "badges": []
            }
          },
          "errors": [{"message":"some non-fatal warning","locations":[]}]
        }
        """)
        let user = try await service.fetchUserProfile(username: "test")
        XCTAssertEqual(user.username, "test")
    }

    // MARK: - Error cases

    func testNullMatchedUser_throwsInvalidUsername() async throws {
        respond(json: "{\"data\": {\"matchedUser\": null}}")
        do {
            _ = try await service.fetchUserProfile(username: "nobody")
            XCTFail("Expected invalidUsername error")
        } catch LeetCodeError.invalidUsername {
            // expected
        }
    }

    func testHTTP403_throwsUnauthorized() async throws {
        respond(status: 403, json: "{}")
        do {
            _ = try await service.fetchUserProfile(username: "test")
            XCTFail("Expected unauthorized error")
        } catch LeetCodeError.unauthorized {
            // expected
        }
    }

    func testHTTP429_throwsRateLimited() async throws {
        respond(status: 429, json: "{}")
        do {
            _ = try await service.fetchAllQuestionsCount()
            XCTFail("Expected rateLimited error")
        } catch LeetCodeError.rateLimited {
            // expected
        }
    }

    func testMalformedJSON_throwsDecodingError() async throws {
        respond(json: "this is not json")
        do {
            _ = try await service.fetchUserProfile(username: "test")
            XCTFail("Expected decodingError")
        } catch LeetCodeError.decodingError {
            // expected
        }
    }

    func testMissingDataKey_throwsDecodingError() async throws {
        respond(json: "{\"errors\":[{\"message\":\"Not authenticated\"}]}")
        do {
            _ = try await service.fetchUserProfile(username: "test")
            XCTFail("Expected decodingError")
        } catch LeetCodeError.decodingError {
            // expected
        }
    }

    func testNullStreakCounter_throwsInvalidUsername() async throws {
        respond(json: "{\"data\": {\"streakCounter\": null}}")
        do {
            _ = try await service.fetchStreakCounter()
            XCTFail("Expected invalidUsername error")
        } catch LeetCodeError.invalidUsername {
            // expected — treated as "not available" by DashboardViewModel
        }
    }
}
