import XCTest
@testable import LeetCodeLytics

@MainActor
final class SubmissionsViewModelTests: XCTestCase {

    private var mock: MockLeetCodeService!
    private var vm: SubmissionsViewModel!

    override func setUp() {
        super.setUp()
        CacheService.suiteName = "com.leetcodelytics.tests.submissions"
        CacheService.clear(key: "submissions_spacewanderer")
        mock = MockLeetCodeService()
        vm = SubmissionsViewModel(service: mock)
    }

    override func tearDown() {
        CacheService.clear(key: "submissions_spacewanderer")
        CacheService.suiteName = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeSubmissions() -> [RecentSubmission] {
        [
            RecentSubmission(title: "LRU Cache",        titleSlug: "lru-cache",        timestamp: "1773250833", statusDisplay: "Accepted",     lang: "python3"),
            RecentSubmission(title: "Merge Intervals",  titleSlug: "merge-intervals",  timestamp: "1773249858", statusDisplay: "Accepted",     lang: "python3"),
            RecentSubmission(title: "Two Sum",          titleSlug: "two-sum",          timestamp: "1773100000", statusDisplay: "Wrong Answer", lang: "swift")
        ]
    }

    // MARK: - Successful load

    func testLoad_populatesSubmissions() async {
        mock.submissionsResult = .success(makeSubmissions())
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.submissions.count, 3)
        XCTAssertEqual(vm.submissions[0].title, "LRU Cache")
    }

    func testLoad_clearsErrorMessage_onSuccess() async {
        mock.submissionsResult = .success(makeSubmissions())
        vm.errorMessage = "old error"
        await vm.load(username: "spacewanderer")
        XCTAssertNil(vm.errorMessage)
    }

    func testLoad_isLoadingFalse_afterSuccess() async {
        mock.submissionsResult = .success(makeSubmissions())
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Empty result

    func testLoad_emptySubmissions_noError() async {
        mock.submissionsResult = .success([])
        await vm.load(username: "spacewanderer")
        XCTAssertTrue(vm.submissions.isEmpty)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Error handling

    func testLoad_setsErrorMessage_onFailure() async {
        mock.submissionsResult = .failure(LeetCodeError.networkError(URLError(.notConnectedToInternet)))
        await vm.load(username: "spacewanderer")
        XCTAssertNotNil(vm.errorMessage)
    }

    func testLoad_isLoadingFalse_afterFailure() async {
        mock.submissionsResult = .failure(URLError(.timedOut))
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.isLoading)
    }

    func testLoad_unauthorizedError_setsCorrectMessage() async {
        mock.submissionsResult = .failure(LeetCodeError.unauthorized)
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.errorMessage, LeetCodeError.unauthorized.errorDescription)
    }

    // MARK: - Multiple calls

    func testMultipleCalls_eachCallsService() async {
        mock.submissionsResult = .success(makeSubmissions())
        await vm.load(username: "spacewanderer")
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(mock.submissionsCallCount, 2)
    }
}
