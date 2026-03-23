import Foundation

extension UserDefaults {
    /// Shared App Group store used by both the main app and the widget extension.
    /// Falls back to .standard if the entitlement is missing (e.g., in unit tests).
    static let appGroup = UserDefaults(suiteName: "group.com.leetanalytics.shared") ?? .standard
}
