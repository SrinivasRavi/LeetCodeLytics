import Foundation
import Security

enum KeychainService {
    static let sessionKey             = "com.leetanalytics.leetcodeSession"
    static let csrfKey                = "com.leetanalytics.csrfToken"
    static let authenticatedUsernameKey = "com.leetanalytics.authenticatedUsername"
    private static let service = "com.leetanalytics.app"

    static func store(_ value: String, key: String) {
        delete(key: key)
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     key,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func retrieve(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func hasCredentials() -> Bool {
        retrieve(key: sessionKey).map { !$0.isEmpty } == true &&
        retrieve(key: csrfKey).map { !$0.isEmpty } == true
    }

    static func clearAll() {
        delete(key: sessionKey)
        delete(key: csrfKey)
        delete(key: authenticatedUsernameKey)
    }
}
