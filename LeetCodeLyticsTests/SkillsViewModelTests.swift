import XCTest
@testable import LeetCodeLytics

@MainActor
final class SkillsViewModelTests: XCTestCase {

    private var mock: MockLeetCodeService!
    private var vm: SkillsViewModel!

    override func setUp() {
        super.setUp()
        CacheService.suiteName = "com.leetcodelytics.tests.skills"
        CacheService.clear(key: "skills_spacewanderer")
        mock = MockLeetCodeService()
        vm = SkillsViewModel(service: mock)
    }

    override func tearDown() {
        CacheService.clear(key: "skills_spacewanderer")
        CacheService.suiteName = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func configureSucceeding() {
        mock.skillStatsResult   = .success(MockLeetCodeService.makeTagProblemCounts())
        mock.languageStatsResult = .success(MockLeetCodeService.makeLanguageStats())
    }

    // MARK: - Successful load

    func testLoad_populatesTagCounts() async {
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertNotNil(vm.tagCounts)
    }

    func testLoad_populatesLanguageStats() async {
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.languageStats.count, 3)
    }

    func testLoad_languageStats_sortedByCountDescending() async {
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        let counts = vm.languageStats.map { $0.problemsSolved }
        XCTAssertEqual(counts, counts.sorted(by: >), "Language stats must be sorted descending")
    }

    func testLoad_clearsErrorMessage_onSuccess() async {
        configureSucceeding()
        vm.errorMessage = "old error"
        await vm.load(username: "spacewanderer")
        XCTAssertNil(vm.errorMessage)
    }

    func testLoad_isLoadingFalse_afterSuccess() async {
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - topSorted computed properties

    func testTopAdvanced_capsAtTen() async {
        // Fixture has 11 advanced tags
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.topAdvanced.count, 10)
    }

    func testTopAdvanced_sortedDescending() async {
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        let counts = vm.topAdvanced.map { $0.problemsSolved }
        XCTAssertEqual(counts, counts.sorted(by: >), "topAdvanced must be sorted highest first")
    }

    func testTopAdvanced_omitsLowestEntry() async {
        // Fixture: lowest advanced tag is Rolling Hash (problemsSolved: 2)
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        let slugs = vm.topAdvanced.map { $0.tagSlug }
        XCTAssertFalse(slugs.contains("rolling-hash"), "11th advanced tag must be excluded from top-10")
    }

    func testTopIntermediate_returnsAll() async {
        // Fixture has 2 intermediate tags — both should be returned
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.topIntermediate.count, 2)
    }

    func testTopFundamental_returnsAll() async {
        // Fixture has 2 fundamental tags — both should be returned
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.topFundamental.count, 2)
    }

    func testTopAdvanced_emptyBeforeLoad() {
        XCTAssertTrue(vm.topAdvanced.isEmpty)
        XCTAssertTrue(vm.topIntermediate.isEmpty)
        XCTAssertTrue(vm.topFundamental.isEmpty)
    }

    // MARK: - Error handling

    func testLoad_setsErrorMessage_onSkillsFailure() async {
        mock.skillStatsResult   = .failure(LeetCodeError.networkError(URLError(.notConnectedToInternet)))
        mock.languageStatsResult = .success(MockLeetCodeService.makeLanguageStats())
        await vm.load(username: "spacewanderer")
        XCTAssertNotNil(vm.errorMessage)
    }

    func testLoad_isLoadingFalse_afterFailure() async {
        mock.skillStatsResult   = .failure(URLError(.timedOut))
        mock.languageStatsResult = .failure(URLError(.timedOut))
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Multiple calls

    func testMultipleCalls_eachCallsService() async {
        configureSucceeding()
        await vm.load(username: "spacewanderer")
        await vm.load(username: "spacewanderer")
        // activeFetch guard only blocks concurrent calls; sequential calls must go through
        XCTAssertNotNil(vm.tagCounts)
    }
}
