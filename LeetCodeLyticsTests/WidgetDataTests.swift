import XCTest
@testable import LeetCodeLytics

final class WidgetDataTests: XCTestCase {

    // MARK: - Placeholder

    func testPlaceholder_hasZeroStreaks() {
        XCTAssertEqual(WidgetData.placeholder.anysolveStreak, 0)
        XCTAssertEqual(WidgetData.placeholder.dccStreak, 0)
    }

    func testPlaceholder_hasZeroSolvedCounts() {
        XCTAssertEqual(WidgetData.placeholder.easySolved, 0)
        XCTAssertEqual(WidgetData.placeholder.mediumSolved, 0)
        XCTAssertEqual(WidgetData.placeholder.hardSolved, 0)
    }

    func testPlaceholder_hasEmptyCalendar() {
        XCTAssertTrue(WidgetData.placeholder.recentCalendar.isEmpty)
    }

    func testPlaceholder_fetchedAt_isNil() {
        XCTAssertNil(WidgetData.placeholder.fetchedAt)
    }

    // MARK: - Codable round-trip

    func testEncodeDecode_roundTrip_preservesAllFields() throws {
        let now = Date()
        let original = WidgetData(
            anysolveStreak: 14,
            dccStreak: 7,
            easySolved: 134,
            mediumSolved: 199,
            hardSolved: 29,
            recentCalendar: ["1700000000": 3, "1700086400": 1],
            fetchedAt: now
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: encoded)

        XCTAssertEqual(decoded.anysolveStreak, 14)
        XCTAssertEqual(decoded.dccStreak, 7)
        XCTAssertEqual(decoded.easySolved, 134)
        XCTAssertEqual(decoded.mediumSolved, 199)
        XCTAssertEqual(decoded.hardSolved, 29)
        XCTAssertEqual(decoded.recentCalendar["1700000000"], 3)
        XCTAssertEqual(decoded.recentCalendar["1700086400"], 1)
        XCTAssertEqual(decoded.fetchedAt?.timeIntervalSince1970 ?? 0,
                       now.timeIntervalSince1970, accuracy: 0.001)
    }

    func testEncodeDecode_emptyCalendar_roundTrips() throws {
        let original = WidgetData.placeholder
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: encoded)
        XCTAssertTrue(decoded.recentCalendar.isEmpty)
        XCTAssertNil(decoded.fetchedAt)
    }

    func testEncoded_recentCalendar_usesStringKeys() throws {
        let data = WidgetData(
            anysolveStreak: 0, dccStreak: 0,
            easySolved: 0, mediumSolved: 0, hardSolved: 0,
            recentCalendar: ["1609459200": 2],
            fetchedAt: nil
        )
        let encoded = try JSONEncoder().encode(data)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let calendar = json?["recentCalendar"] as? [String: Any]
        XCTAssertNotNil(calendar?["1609459200"])
    }

    func testDecode_legacyData_withoutFetchedAt_decodesNilFetchedAt() throws {
        // Simulate data encoded before fetchedAt was added
        let legacyJSON = """
        {"anysolveStreak":5,"dccStreak":3,"easySolved":10,"mediumSolved":5,"hardSolved":1,"recentCalendar":{}}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WidgetData.self, from: legacyJSON)
        XCTAssertNil(decoded.fetchedAt)
        XCTAssertEqual(decoded.anysolveStreak, 5)
    }
}
