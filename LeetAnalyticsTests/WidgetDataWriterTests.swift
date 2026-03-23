import XCTest
@testable import LeetAnalytics

final class WidgetDataWriterTests: XCTestCase {
    private let defaults = UserDefaults(suiteName: "group.com.leetanalytics.shared")!

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: "widgetData")
    }

    override func tearDown() {
        defaults.removeObject(forKey: "widgetData")
        super.tearDown()
    }

    // MARK: - read/writeAll round-trip

    func testWriteAll_andRead_roundTripsAllFields() {
        let data = WidgetData(
            anysolveStreak: 5, dccStreak: 3, isDCCAvailable: true,
            easySolved: 100, mediumSolved: 200, hardSolved: 50,
            recentCalendar: ["1700000000": 2], fetchedAt: Date(timeIntervalSince1970: 1700000000)
        )
        WidgetDataWriter.writeAll(data)
        let loaded = WidgetDataWriter.read()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.anysolveStreak, 5)
        XCTAssertEqual(loaded?.dccStreak, 3)
        XCTAssertEqual(loaded?.isDCCAvailable, true)
        XCTAssertEqual(loaded?.easySolved, 100)
        XCTAssertEqual(loaded?.mediumSolved, 200)
        XCTAssertEqual(loaded?.hardSolved, 50)
        XCTAssertEqual(loaded?.recentCalendar, ["1700000000": 2])
    }

    func testRead_returnsNil_whenNothingWritten() {
        XCTAssertNil(WidgetDataWriter.read())
    }

    // MARK: - updateCalendar

    func testUpdateCalendar_preservesNonCalendarFields() {
        let initial = WidgetData(
            anysolveStreak: 5, dccStreak: 3, isDCCAvailable: true,
            easySolved: 100, mediumSolved: 200, hardSolved: 50,
            recentCalendar: ["1700000000": 2], fetchedAt: Date()
        )
        WidgetDataWriter.writeAll(initial)

        WidgetDataWriter.updateCalendar(anysolveStreak: 7, recentCalendar: ["1700086400": 1])

        let loaded = WidgetDataWriter.read()!
        XCTAssertEqual(loaded.anysolveStreak, 7, "anysolveStreak should be updated")
        XCTAssertEqual(loaded.recentCalendar, ["1700086400": 1], "recentCalendar should be updated")
        XCTAssertEqual(loaded.dccStreak, 3, "dccStreak should be preserved")
        XCTAssertEqual(loaded.isDCCAvailable, true, "isDCCAvailable should be preserved")
        XCTAssertEqual(loaded.easySolved, 100, "easySolved should be preserved")
        XCTAssertEqual(loaded.mediumSolved, 200, "mediumSolved should be preserved")
        XCTAssertEqual(loaded.hardSolved, 50, "hardSolved should be preserved")
    }

    func testUpdateCalendar_returnsRecentCalendar() {
        let initial = WidgetData(
            anysolveStreak: 0, dccStreak: 0, isDCCAvailable: false,
            easySolved: 0, mediumSolved: 0, hardSolved: 0,
            recentCalendar: [:], fetchedAt: nil
        )
        WidgetDataWriter.writeAll(initial)

        let result = WidgetDataWriter.updateCalendar(anysolveStreak: 1, recentCalendar: ["123": 4])
        XCTAssertEqual(result, ["123": 4])
    }

    func testUpdateCalendar_noopWhenNoExistingData() {
        let result = WidgetDataWriter.updateCalendar(anysolveStreak: 1, recentCalendar: ["123": 4])
        XCTAssertEqual(result, ["123": 4])
        XCTAssertNil(WidgetDataWriter.read(), "Should not create data from scratch")
    }

    // MARK: - markDCCUnavailable

    func testMarkDCCUnavailable_setsIsDCCAvailableFalse() {
        let initial = WidgetData(
            anysolveStreak: 5, dccStreak: 3, isDCCAvailable: true,
            easySolved: 100, mediumSolved: 200, hardSolved: 50,
            recentCalendar: [:], fetchedAt: Date()
        )
        WidgetDataWriter.writeAll(initial)

        WidgetDataWriter.markDCCUnavailable()

        let loaded = WidgetDataWriter.read()!
        XCTAssertFalse(loaded.isDCCAvailable)
        XCTAssertEqual(loaded.anysolveStreak, 5, "Other fields must be preserved")
        XCTAssertEqual(loaded.dccStreak, 3, "DCC streak value must be preserved")
    }

    func testMarkDCCUnavailable_noopWhenNoExistingData() {
        WidgetDataWriter.markDCCUnavailable() // should not crash
        XCTAssertNil(WidgetDataWriter.read())
    }
}
