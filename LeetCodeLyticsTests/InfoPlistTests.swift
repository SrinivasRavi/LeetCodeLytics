import XCTest
@testable import LeetCodeLytics

final class InfoPlistTests: XCTestCase {

    /// Accesses the app target bundle via a class that lives in it.
    private var appBundle: Bundle { Bundle(for: DashboardViewModel.self) }

    func testBundleShortVersionString_isNotXcodeGenPlaceholder() {
        let version = appBundle.infoDictionary?["CFBundleShortVersionString"] as? String
        XCTAssertNotNil(version, "CFBundleShortVersionString must be present in Info.plist")
        XCTAssertNotEqual(version, "1.0", "Version must not be XcodeGen's default placeholder '1.0' — check MARKETING_VERSION in project.yml")
    }

    func testBundleShortVersionString_isNonEmpty() {
        let version = appBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        XCTAssertFalse(version.isEmpty, "CFBundleShortVersionString must not be empty")
    }

    func testBundleIdentifier_matchesExpectedPrefix() {
        let bundleID = appBundle.bundleIdentifier ?? ""
        XCTAssertTrue(bundleID.hasPrefix("com.leetcodelytics"), "Bundle identifier must start with com.leetcodelytics")
    }
}
