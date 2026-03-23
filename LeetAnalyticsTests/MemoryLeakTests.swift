import XCTest
@testable import LeetAnalytics

/// Verifies that ViewModels do not retain themselves after their owner releases them.
/// Each test holds a `weak` reference, then drops the strong reference; if the weak
/// ref is still non-nil after, a retain cycle exists.
///
/// Note: `autoreleasepool` is intentionally absent. Swift ARC deallocates pure Swift
/// `ObservableObject` classes synchronously when the reference count drops to zero —
/// autoreleasepool only drains Objective-C autorelease pools and has no bearing on
/// Swift ARC. The `weak` reference pattern is sufficient to detect retain cycles.
@MainActor
final class MemoryLeakTests: XCTestCase {

    // MARK: - DashboardViewModel

    func testDashboardViewModel_deallocatesWithoutLoad() {
        weak var weakVM: DashboardViewModel?
        do {
            let vm = DashboardViewModel(service: MockLeetCodeService())
            weakVM = vm
        }
        XCTAssertNil(weakVM, "DashboardViewModel must deallocate when never loaded")
    }

    /// Verifies that DashboardViewModel deallocates after a complete load cycle.
    /// This guards against retain cycles introduced by the unstructured Task + self capture.
    func testDashboardViewModel_deallocatesAfterLoad() async {
        weak var weakVM: DashboardViewModel?
        let mock = MockLeetCodeService()
        mock.profileResult       = .success(MockLeetCodeService.makeMatchedUser())
        mock.questionsResult     = .success(MockLeetCodeService.makeProblemCounts())
        mock.calendarResult      = .success(MockLeetCodeService.makeStreakData())
        mock.streakCounterResult = .success(StreakCounterResponse(streakCount: 1, currentDayCompleted: true))

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                let vm = DashboardViewModel(service: mock)
                weakVM = vm
                await vm.load(username: "spacewanderer")
                // `vm` goes out of scope when the Task body exits.
                cont.resume()
            }
        }

        XCTAssertNil(weakVM, "DashboardViewModel must deallocate after load — possible retain cycle")
    }

    // MARK: - SubmissionsViewModel

    func testSubmissionsViewModel_deallocatesAfterLoad() async {
        weak var weakVM: SubmissionsViewModel?
        let mock = MockLeetCodeService()
        mock.submissionsResult = .success([])

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                let vm = SubmissionsViewModel(service: mock)
                weakVM = vm
                await vm.load(username: "spacewanderer")
                cont.resume()
            }
        }

        XCTAssertNil(weakVM, "SubmissionsViewModel must deallocate after load — possible retain cycle")
    }

    func testSubmissionsViewModel_deallocatesWithoutLoad() {
        weak var weakVM: SubmissionsViewModel?
        do {
            let vm = SubmissionsViewModel(service: MockLeetCodeService())
            weakVM = vm
        }
        XCTAssertNil(weakVM, "SubmissionsViewModel must deallocate when never loaded")
    }

    // MARK: - SkillsViewModel

    func testSkillsViewModel_deallocatesAfterLoad() async {
        weak var weakVM: SkillsViewModel?
        let mock = MockLeetCodeService()
        mock.skillStatsResult    = .success(MockLeetCodeService.makeTagProblemCounts())
        mock.languageStatsResult = .success(MockLeetCodeService.makeLanguageStats())

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                let vm = SkillsViewModel(service: mock)
                weakVM = vm
                await vm.load(username: "spacewanderer")
                cont.resume()
            }
        }

        XCTAssertNil(weakVM, "SkillsViewModel must deallocate after load — possible retain cycle")
    }

    func testSkillsViewModel_deallocatesWithoutLoad() {
        weak var weakVM: SkillsViewModel?
        do {
            let vm = SkillsViewModel(service: MockLeetCodeService())
            weakVM = vm
        }
        XCTAssertNil(weakVM, "SkillsViewModel must deallocate when never loaded")
    }
}
