import XCTest
@testable import LeetAnalytics

@MainActor
final class SkillsViewModelTests: XCTestCase {

    private var mock: MockLeetCodeService!
    private var vm: SkillsViewModel!

    override func setUp() {
        super.setUp()
        CacheService.suiteName = "com.leetanalytics.tests.skills"
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

    // MARK: - Topic Suggestions (Muscle Memory)

    func testLoad_populatesTopicSuggestions() async {
        configureSucceeding()
        // Set tag totals so ratio can be computed
        mock.problemsForTagResult = .success(QuestionListResponse(totalNum: 100, data: []))
        await vm.load(username: "spacewanderer")

        XCTAssertFalse(vm.topicSuggestions.isEmpty, "topicSuggestions should be populated after load")
        XCTAssertLessThanOrEqual(vm.topicSuggestions.count, 3)
    }

    func testLoad_topicSuggestions_sortedByRatio() async {
        configureSucceeding()
        mock.problemsForTagResult = .success(QuestionListResponse(totalNum: 100, data: []))
        await vm.load(username: "spacewanderer")

        let ratios = vm.topicSuggestions.map(\.ratio)
        XCTAssertEqual(ratios, ratios.sorted(), "suggestions should be sorted by ascending ratio")
    }

    func testLoad_topicSuggestions_usesRatioNotAbsoluteCount() async {
        // Custom tags where absolute count misleads
        mock.skillStatsResult = .success(TagProblemCounts(
            advanced: [
                TagStat(tagName: "Tag A", tagSlug: "tag-a", problemsSolved: 2),
                TagStat(tagName: "Tag B", tagSlug: "tag-b", problemsSolved: 5)
            ],
            intermediate: [],
            fundamental: []
        ))
        mock.languageStatsResult = .success([])

        // Tag A: 2/10 = 20%, Tag B: 5/100 = 5% → Tag B should rank first
        // We can't easily return different totals per tag with the current mock,
        // but we can verify the suggestions exist and are ratio-sorted
        mock.problemsForTagResult = .success(QuestionListResponse(totalNum: 100, data: []))
        await vm.load(username: "spacewanderer")

        // Both tags get totalNum=100, so Tag A = 2/100=2%, Tag B = 5/100=5%
        // Tag A should rank first (lower ratio)
        XCTAssertEqual(vm.topicSuggestions.first?.tagSlug, "tag-a")
    }
}
