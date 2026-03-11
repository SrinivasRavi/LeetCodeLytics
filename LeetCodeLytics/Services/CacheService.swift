import Foundation

/// V1.0 stub — load always returns nil, save is a no-op.
/// V1.1 will replace the body of these two methods with UserDefaults logic.
/// ViewModels must never call UserDefaults directly; always go through CacheService.
enum CacheService {
    static func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        return nil
    }

    static func save<T: Codable>(_ value: T, key: String) {
        // no-op in V1.0
    }
}
