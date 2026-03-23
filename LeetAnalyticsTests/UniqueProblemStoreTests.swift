import XCTest
@testable import LeetAnalytics

final class UniqueProblemStoreTests: XCTestCase {

    private let defaults = UserDefaults(suiteName: "group.com.leetanalytics.shared")!
    private let entriesKey = "uniqueProblemEntries"

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: entriesKey)
    }

    override func tearDown() {
        defaults.removeObject(forKey: entriesKey)
        super.tearDown()
    }

    // MARK: - add / count

    func testAdd_incrementsCount() {
        XCTAssertEqual(UniqueProblemStore.count(), 0)
        UniqueProblemStore.add(problems: [
            (slug: "two-sum", title: "Two Sum"),
            (slug: "add-two-numbers", title: "Add Two Numbers")
        ])
        XCTAssertEqual(UniqueProblemStore.count(), 2)
    }

    func testAdd_deduplicates() {
        UniqueProblemStore.add(problems: [
            (slug: "two-sum", title: "Two Sum"),
            (slug: "two-sum", title: "Two Sum"),
            (slug: "two-sum", title: "Two Sum")
        ])
        XCTAssertEqual(UniqueProblemStore.count(), 1)
    }

    func testAdd_acrossCalls_deduplicates() {
        UniqueProblemStore.add(problems: [(slug: "two-sum", title: "Two Sum")])
        UniqueProblemStore.add(problems: [
            (slug: "two-sum", title: "Two Sum"),
            (slug: "add-two-numbers", title: "Add Two Numbers")
        ])
        XCTAssertEqual(UniqueProblemStore.count(), 2)
    }

    func testAdd_empty_doesNothing() {
        UniqueProblemStore.add(problems: [])
        XCTAssertEqual(UniqueProblemStore.count(), 0)
        XCTAssertNil(UniqueProblemStore.earliestDate(), "earliestDate should be nil when nothing was added")
    }

    // MARK: - contains

    func testContains_returnsTrueForAdded() {
        UniqueProblemStore.add(problems: [(slug: "two-sum", title: "Two Sum")])
        XCTAssertTrue(UniqueProblemStore.contains(slug: "two-sum"))
    }

    func testContains_returnsFalseForNotAdded() {
        XCTAssertFalse(UniqueProblemStore.contains(slug: "two-sum"))
    }

    // MARK: - earliestDate

    func testEarliestDate_nilBeforeFirstAdd() {
        XCTAssertNil(UniqueProblemStore.earliestDate())
    }

    func testEarliestDate_setOnFirstAdd() {
        let before = Date()
        UniqueProblemStore.add(problems: [(slug: "two-sum", title: "Two Sum")])
        let after = Date()

        guard let earliest = UniqueProblemStore.earliestDate() else {
            XCTFail("earliestDate must be set after first add")
            return
        }
        XCTAssertGreaterThanOrEqual(earliest, before)
        XCTAssertLessThanOrEqual(earliest, after)
    }

    // MARK: - recentEntries

    func testRecentEntries_returnsEntriesWithTitles() {
        UniqueProblemStore.add(problems: [
            (slug: "two-sum", title: "Two Sum"),
            (slug: "3sum", title: "3Sum")
        ])
        let entries = UniqueProblemStore.recentEntries()
        XCTAssertEqual(entries.count, 2)
        // recentEntries returns most recent first
        let titles = Set(entries.map(\.title))
        XCTAssertTrue(titles.contains("Two Sum"))
        XCTAssertTrue(titles.contains("3Sum"))
    }

    // MARK: - recentSlugs

    func testRecentSlugs_returnsSetOfSlugs() {
        UniqueProblemStore.add(problems: [
            (slug: "two-sum", title: "Two Sum"),
            (slug: "3sum", title: "3Sum")
        ])
        let slugs = UniqueProblemStore.recentSlugs()
        XCTAssertEqual(slugs, ["two-sum", "3sum"])
    }
}
