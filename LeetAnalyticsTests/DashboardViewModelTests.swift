import XCTest
@testable import LeetAnalytics

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private var mock: MockLeetCodeService!
    private var vm: DashboardViewModel!

    override func setUp() {
        super.setUp()
        CacheService.suiteName = "com.leetanalytics.tests.dashboard"
        CacheService.clear(key: "dashboard_spacewanderer")
        // Simulate viewing own profile so DCC fetch is not skipped.
        KeychainService.store("spacewanderer", key: KeychainService.authenticatedUsernameKey)
        mock = MockLeetCodeService()
        vm = DashboardViewModel(service: mock)
    }

    override func tearDown() {
        CacheService.clear(key: "dashboard_spacewanderer")
        CacheService.suiteName = nil
        UserDefaults.appGroup.removeObject(forKey: "widgetData")
        KeychainService.delete(key: KeychainService.authenticatedUsernameKey)
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

    // MARK: - Widget data

    func testLoad_writesWidgetData_toAppGroupDefaults() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        let data = UserDefaults.appGroup.data(forKey: "widgetData")
        XCTAssertNotNil(data, "widgetData must be written to UserDefaults.appGroup after successful load")
    }

    func testLoad_widgetData_reflectsComputedStats() async {
        configureAllSucceeding()
        mock.streakCounterResult = .success(StreakCounterResponse(streakCount: 3, currentDayCompleted: true))
        await vm.load(username: "spacewanderer")

        guard let raw = UserDefaults.appGroup.data(forKey: "widgetData"),
              let wd = try? JSONDecoder().decode(WidgetData.self, from: raw) else {
            XCTFail("widgetData missing or not decodable")
            return
        }

        XCTAssertEqual(wd.easySolved, 134)
        XCTAssertEqual(wd.mediumSolved, 199)
        XCTAssertEqual(wd.hardSolved, 29)
        XCTAssertEqual(wd.dccStreak, 3)
    }

    // MARK: - Multiple calls

    func testMultipleCalls_eachFetchesFromService() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        await vm.load(username: "spacewanderer")
        XCTAssertEqual(mock.profileCallCount, 2)
    }

    // MARK: - Session expiry

    func testSessionExpired_setTrue_whenAuthenticatedAndStreakFails() async {
        // Precondition: user was previously authenticated — seed real Keychain credentials
        KeychainService.store("fakeSession", key: KeychainService.sessionKey)
        KeychainService.store("fakeCsrf",    key: KeychainService.csrfKey)
        defer { KeychainService.clearAll() }

        mock.profileResult   = .success(MockLeetCodeService.makeMatchedUser())
        mock.questionsResult = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult  = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .failure(LeetCodeError.invalidUsername)

        await vm.load(username: "spacewanderer")
        XCTAssertTrue(vm.sessionExpired, "sessionExpired must be true when streak returns invalidUsername and user was authenticated")
    }

    func testSessionExpired_notSet_whenNotAuthenticatedAndStreakFails() async {
        // Precondition: user never logged in (isAuthenticated starts false)
        XCTAssertFalse(vm.isAuthenticated)

        mock.profileResult   = .success(MockLeetCodeService.makeMatchedUser())
        mock.questionsResult = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult  = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .failure(LeetCodeError.invalidUsername)

        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.sessionExpired, "sessionExpired must remain false when user was never authenticated")
    }

    func testSessionExpired_resetToFalse_whenStreakFetchSucceeds() async {
        vm.sessionExpired = true

        configureAllSucceeding()
        mock.streakCounterResult = .success(StreakCounterResponse(streakCount: 4, currentDayCompleted: false))
        await vm.load(username: "spacewanderer")
        XCTAssertFalse(vm.sessionExpired, "sessionExpired must be reset to false when streak fetch succeeds")
    }

    func testCredentialsUpdated_setsIsAuthenticated_andClearsSessionExpired() {
        vm.sessionExpired = true
        KeychainService.store("s", key: KeychainService.sessionKey)
        KeychainService.store("c", key: KeychainService.csrfKey)
        defer { KeychainService.clearAll() }

        vm.credentialsUpdated()

        XCTAssertTrue(vm.isAuthenticated)
        XCTAssertFalse(vm.sessionExpired)
    }

    func testCredentialsUpdated_clearsIsAuthenticated_afterSignOut() {
        KeychainService.clearAll()

        vm.credentialsUpdated()

        XCTAssertFalse(vm.isAuthenticated)
    }

    // MARK: - Unique Problem Tracking (v4)

    func testLoad_tracksUniqueProblems_fromAcceptedSubmissions() async {
        configureAllSucceeding()
        mock.submissionsResult = .success([
            RecentSubmission(title: "Two Sum", titleSlug: "two-sum",
                             timestamp: "1715000000", statusDisplay: "Accepted", lang: "python3"),
            RecentSubmission(title: "Add Two Numbers", titleSlug: "add-two-numbers",
                             timestamp: "1715000100", statusDisplay: "Wrong Answer", lang: "python3"),
            RecentSubmission(title: "Three Sum", titleSlug: "3sum",
                             timestamp: "1715000200", statusDisplay: "Accepted", lang: "python3")
        ])

        // Clean slate
        let defaults = UserDefaults(suiteName: "group.com.leetanalytics.shared")!
        defaults.removeObject(forKey: "uniqueProblemEntries")
        defer {
            defaults.removeObject(forKey: "uniqueProblemEntries")
        }

        await vm.load(username: "spacewanderer")

        // Only Accepted submissions should be tracked
        XCTAssertTrue(UniqueProblemStore.contains(slug: "two-sum"))
        XCTAssertTrue(UniqueProblemStore.contains(slug: "3sum"))
        XCTAssertFalse(UniqueProblemStore.contains(slug: "add-two-numbers"))
        XCTAssertEqual(vm.uniqueSolvedCount, 2)
    }

    func testLoad_submissionsFail_doesNotAffectDashboard() async {
        configureAllSucceeding()
        mock.submissionsResult = .failure(URLError(.notConnectedToInternet))

        await vm.load(username: "spacewanderer")

        // Dashboard should still load fine
        XCTAssertNotNil(vm.profile)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - DCC streak with non-own profile (v4.2 regression fix)

    func testLoad_isViewingOwnProfile_trueWhenUsernameMatchesAuthenticated() async {
        configureAllSucceeding()
        await vm.load(username: "spacewanderer")
        XCTAssertTrue(vm.isViewingOwnProfile)
    }

    func testLoad_isViewingOwnProfile_falseWhenUsernameDoesNotMatch() async {
        configureAllSucceeding()
        await vm.load(username: "someoneelse")
        XCTAssertFalse(vm.isViewingOwnProfile)
        XCTAssertEqual(vm.dccStreak, 0, "DCC streak must be 0 when viewing another user's profile")
    }
}
