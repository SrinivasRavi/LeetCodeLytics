import XCTest
@testable import LeetCodeLytics

final class CacheServiceTests: XCTestCase {

    private let testSuite = "com.leetcodelytics.tests.cache"
    private let key = "test_key"

    override func setUp() {
        super.setUp()
        CacheService.suiteName = testSuite
        CacheService.clear(key: key)
        CacheService.clear(key: "key_a")
        CacheService.clear(key: "key_b")
    }

    override func tearDown() {
        CacheService.clear(key: key)
        CacheService.clear(key: "key_a")
        CacheService.clear(key: "key_b")
        CacheService.suiteName = nil
        super.tearDown()
    }

    // MARK: - Save / Load roundtrip

    func testSaveAndLoad_codableStruct() {
        let count = ProblemCount(difficulty: "Easy", count: 42)
        CacheService.save(count, key: key)
        let loaded = CacheService.load(ProblemCount.self, key: key)
        XCTAssertEqual(loaded?.difficulty, "Easy")
        XCTAssertEqual(loaded?.count, 42)
    }

    func testSaveAndLoad_array() {
        let items = [
            ProblemCount(difficulty: "Easy",   count: 100),
            ProblemCount(difficulty: "Medium", count: 200),
            ProblemCount(difficulty: "Hard",   count: 50)
        ]
        CacheService.save(items, key: key)
        let loaded = CacheService.load([ProblemCount].self, key: key)
        XCTAssertEqual(loaded?.count, 3)
        XCTAssertEqual(loaded?[1].count, 200)
    }

    func testLoad_returnsNilWhenNotSaved() {
        let loaded = CacheService.load(ProblemCount.self, key: key)
        XCTAssertNil(loaded)
    }

    func testSave_overwritesPreviousValue() {
        CacheService.save(ProblemCount(difficulty: "Easy", count: 1), key: key)
        CacheService.save(ProblemCount(difficulty: "Hard", count: 99), key: key)
        let loaded = CacheService.load(ProblemCount.self, key: key)
        XCTAssertEqual(loaded?.difficulty, "Hard")
        XCTAssertEqual(loaded?.count, 99)
    }

    // MARK: - Timestamps

    func testTimestamp_nilWhenNotSaved() {
        XCTAssertNil(CacheService.timestamp(for: key))
    }

    func testTimestamp_nonNilAfterSave() {
        CacheService.saveTimestamp(for: key)
        XCTAssertNotNil(CacheService.timestamp(for: key))
    }

    func testTimestamp_approximatelyNow() {
        CacheService.saveTimestamp(for: key)
        let ts = CacheService.timestamp(for: key)!
        XCTAssertLessThan(abs(ts.timeIntervalSinceNow), 2.0, "Timestamp should be within 2 seconds of now")
    }

    // MARK: - isStale

    func testIsStale_trueWhenNoTimestamp() {
        XCTAssertTrue(CacheService.isStale(key: key))
    }

    func testIsStale_falseJustAfterSave() {
        CacheService.saveTimestamp(for: key)
        XCTAssertFalse(CacheService.isStale(key: key))
    }

    func testIsStale_trueWhenMaxAgeExceeded() {
        CacheService.saveTimestamp(for: key)
        // maxAge of 0 seconds means immediately stale
        XCTAssertTrue(CacheService.isStale(key: key, maxAge: 0))
    }

    func testIsStale_falseWithGenerousMaxAge() {
        CacheService.saveTimestamp(for: key)
        XCTAssertFalse(CacheService.isStale(key: key, maxAge: 3600))
    }

    // MARK: - Clear

    func testClear_removesValue() {
        CacheService.save(ProblemCount(difficulty: "Easy", count: 1), key: key)
        CacheService.clear(key: key)
        XCTAssertNil(CacheService.load(ProblemCount.self, key: key))
    }

    func testClear_removesTimestamp() {
        CacheService.saveTimestamp(for: key)
        CacheService.clear(key: key)
        XCTAssertNil(CacheService.timestamp(for: key))
    }

    // MARK: - Key isolation

    func testDifferentKeys_dontInterfere() {
        CacheService.save(ProblemCount(difficulty: "Easy", count: 1), key: "key_a")
        CacheService.save(ProblemCount(difficulty: "Hard", count: 9), key: "key_b")
        XCTAssertEqual(CacheService.load(ProblemCount.self, key: "key_a")?.count, 1)
        XCTAssertEqual(CacheService.load(ProblemCount.self, key: "key_b")?.count, 9)

        CacheService.clear(key: "key_a")
        XCTAssertNil(CacheService.load(ProblemCount.self, key: "key_a"))
        XCTAssertEqual(CacheService.load(ProblemCount.self, key: "key_b")?.count, 9)
    }
}
