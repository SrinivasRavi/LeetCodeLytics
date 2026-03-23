import Foundation

/// V2.0: suiteName changed to App Group for widget data sharing.
enum CacheService {
    static var suiteName: String? = "group.com.leetanalytics.shared"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Codable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    static func saveTimestamp(for key: String) {
        defaults.set(Date().timeIntervalSince1970, forKey: key + "_ts")
    }

    static func timestamp(for key: String) -> Date? {
        let ts = defaults.double(forKey: key + "_ts")
        guard ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    /// Cache is considered stale after 30 minutes.
    static func isStale(key: String, maxAge: TimeInterval = 1800) -> Bool {
        guard let ts = timestamp(for: key) else { return true }
        return Date().timeIntervalSince(ts) > maxAge
    }

    static func clear(key: String) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: key + "_ts")
    }
}
