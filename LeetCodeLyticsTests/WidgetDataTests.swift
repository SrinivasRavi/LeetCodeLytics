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

    // MARK: - Codable round-trip

    func testEncodeDecode_roundTrip_preservesAllFields() throws {
        let original = WidgetData(
            anysolveStreak: 14,
            dccStreak: 7,
            easySolved: 134,
            mediumSolved: 199,
            hardSolved: 29,
            recentCalendar: ["1700000000": 3, "1700086400": 1]
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
    }

    func testEncodeDecode_emptyCalendar_roundTrips() throws {
        let original = WidgetData.placeholder
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: encoded)
        XCTAssertTrue(decoded.recentCalendar.isEmpty)
    }

    func testEncoded_recentCalendar_usesStringKeys() throws {
        let data = WidgetData(
            anysolveStreak: 0, dccStreak: 0,
            easySolved: 0, mediumSolved: 0, hardSolved: 0,
            recentCalendar: ["1609459200": 2]
        )
        let encoded = try JSONEncoder().encode(data)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let calendar = json?["recentCalendar"] as? [String: Any]
        XCTAssertNotNil(calendar?["1609459200"])
    }
}
