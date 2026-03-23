import XCTest
@testable import LeetAnalytics

final class SubmissionCalendarTests: XCTestCase {

    func testValidJSON_parsesCorrectly() {
        let json = """
        {"1767225600": 1, "1767312000": 5, "1767484800": 3}
        """
        let cal = SubmissionCalendar(jsonString: json)
        XCTAssertEqual(cal.dailyCounts.count, 3)
        XCTAssertEqual(cal.dailyCounts[1767225600], 1)
        XCTAssertEqual(cal.dailyCounts[1767312000], 5)
        XCTAssertEqual(cal.dailyCounts[1767484800], 3)
    }

    func testEmptyJSONObject_returnsEmptyCounts() {
        let cal = SubmissionCalendar(jsonString: "{}")
        XCTAssertTrue(cal.dailyCounts.isEmpty)
    }

    func testEmptyString_returnsEmptyCounts() {
        let cal = SubmissionCalendar(jsonString: "")
        XCTAssertTrue(cal.dailyCounts.isEmpty)
    }

    func testInvalidJSON_returnsEmptyCounts() {
        let cal = SubmissionCalendar(jsonString: "not json at all")
        XCTAssertTrue(cal.dailyCounts.isEmpty)
    }

    func testNonNumericKey_isSkipped() {
        // Keys that can't be parsed as Int should be dropped silently
        let json = """
        {"1767225600": 2, "not-a-number": 5}
        """
        let cal = SubmissionCalendar(jsonString: json)
        XCTAssertEqual(cal.dailyCounts.count, 1)
        XCTAssertEqual(cal.dailyCounts[1767225600], 2)
    }

    func testSingleEntry() {
        let json = "{\"1767225600\": 7}"
        let cal = SubmissionCalendar(jsonString: json)
        XCTAssertEqual(cal.dailyCounts[1767225600], 7)
    }

    func testLargeCalendar_parsesAll() {
        // Build a calendar with 365 entries
        var entries: [String] = []
        let base = 1700000000
        for i in 0..<365 {
            entries.append("\"\(base + i * 86400)\": \(i % 5 + 1)")
        }
        let json = "{" + entries.joined(separator: ",") + "}"
        let cal = SubmissionCalendar(jsonString: json)
        XCTAssertEqual(cal.dailyCounts.count, 365)
    }
}
