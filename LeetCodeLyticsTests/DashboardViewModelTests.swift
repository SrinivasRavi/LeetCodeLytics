import XCTest
@testable import LeetCodeLytics

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private var mock: MockLeetCodeService!
    private var vm: DashboardViewModel!

    override func setUp() {
        super.setUp()
        CacheService.suiteName = "com.leetcodelytics.tests.dashboard"
        CacheService.clear(key: "dashboard_spacewanderer")
        mock = MockLeetCodeService()
        vm = DashboardViewModel(service: mock)
    }

    override func tearDown() {
        CacheService.clear(key: "dashboard_spacewanderer")
        CacheService.suiteName = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func configureAllSucceeding() {
        mock.profileResult  = .success(MockLeetCodeService.makeMatchedUser())
        mock.questionsResult = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult  = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .success(StreakCounterResponse(streakCount: 1, currentDayCompleted: true))
    }

    // MARK: - Successful load

    func testLoad_populatesProfile() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertNotNil(vm.profile)
        XCTAssertEqual(vm.profile?.username, "spacewanderer")
    }

    func testLoad_populatesAllQuestionsCount() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.allQuestionsCount.isEmpty)
        XCTAssertEqual(vm.totalEasy, 930)
        XCTAssertEqual(vm.totalHard, 913)
    }

    func testLoad_populatesComputedStats() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.easySolved, 134)
        XCTAssertEqual(vm.mediumSolved, 199)
        XCTAssertEqual(vm.hardSolved, 29)
        XCTAssertEqual(vm.totalSolved, 362)
    }

    func testLoad_computesAcceptanceRate() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertGreaterThan(vm.acceptanceRate, 0)
        XCTAssertLessThanOrEqual(vm.acceptanceRate, 100)
    }

    func testLoad_populatesDCCStreak() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.dccStreak, 1)
    }

    func testLoad_clearsErrorMessage_onSuccess() async {
        configureAllSucceeding()
        vm.errorMessage = "previous error"
        await vm.load(username: "spacewanderer")
        XCTAssertNil(vm.errorMessage)
    }

    func testLoad_isLoadingFalse_afterCompletion() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Error handling

    func testLoad_setsErrorMessage_onProfileFailure() async {
        mock.profileResult  = .failure(LeetCodeError.networkError(URLError(.notConnectedToInternet)))
        mock.questionsResult = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult  = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .failure(URLError(.unknown))
        await vm.load(username: "spacewanderer")
        XCTAssertNotNil(vm.errorMessage)
    }

    func testLoad_setsErrorMessage_onInvalidUsername() async {
        mock.profileResult   = .failure(LeetCodeError.invalidUsername)
        mock.questionsResult = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult  = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .failure(URLError(.unknown))
        await vm.load(username: "nobody")
        XCTAssertNotNil(vm.errorMessage)
    }

    func testLoad_isLoadingFalse_afterFailure() async {
        mock.profileResult   = .failure(LeetCodeError.networkError(URLError(.timedOut)))
        mock.questionsResult = .failure(URLError(.unknown))
        mock.calendarResult  = .failure(URLError(.unknown))
        mock.streakCounterResult = .failure(URLError(.unknown))
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - DCC preservation on failure (the bug from v1.5.x)

    func testDCCStreak_preservedWhenFetchFails() async {
        mock.profileResult   = .success(MockLeetCodeService.makeMatchedUser())
        mock.questionsResult = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult  = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .failure(LeetCodeError.unauthorized)

        // Pre-set a known DCC value (as if loaded from a prior session)
        vm.dccStreak = 5
        await vm.load(username: "spacewanderer")

        XCTAssertEqual(vm.dccStreak, 5, "DCC streak must not reset to 0 when fetch fails")
    }

    func testDCCStreak_updatedWhenFetchSucceeds() async {
        configureAllSucceeding()
        mock.streakCounterResult = .success(StreakCounterResponse(streakCount: 7, currentDayCompleted: true))
        vm.dccStreak = 5
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(vm.dccStreak, 7)
    }

    // MARK: - Multiple calls

    func testMultipleCalls_eachFetchesFromService() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(mock.profileCallCount, 2)
    }
}
