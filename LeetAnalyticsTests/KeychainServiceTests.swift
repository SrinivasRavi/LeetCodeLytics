import XCTest
@testable import LeetAnalytics

final class KeychainServiceTests: XCTestCase {

    private let testKey = "com.leetanalytics.tests.keychainKey"
    private let testKey2 = "com.leetanalytics.tests.keychainKey2"

    override func setUp() {
        super.setUp()
        // Clean up any leftover state before each test
        KeychainService.delete(key: testKey)
        KeychainService.delete(key: testKey2)
        KeychainService.delete(key: KeychainService.sessionKey)
        KeychainService.delete(key: KeychainService.csrfKey)
    }

    override func tearDown() {
        KeychainService.delete(key: testKey)
        KeychainService.delete(key: testKey2)
        KeychainService.delete(key: KeychainService.sessionKey)
        KeychainService.delete(key: KeychainService.csrfKey)
        super.tearDown()
    }

    // MARK: - Round-trip

    func testStore_andRetrieve_roundtrip() {
        KeychainService.store("my-secret-value", key: testKey)
        let retrieved = KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrieved, "my-secret-value")
    }

    // MARK: - Nil when not stored

    func testRetrieve_returnsNil_whenKeyNotStored() {
        let retrieved = KeychainService.retrieve(key: testKey)
        XCTAssertNil(retrieved)
    }

    // MARK: - Overwrite

    func testStore_overwritesExistingValue() {
        KeychainService.store("first-value", key: testKey)
        KeychainService.store("second-value", key: testKey)
        let retrieved = KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrieved, "second-value")
    }

    // MARK: - Delete

    func testDelete_removesStoredValue() {
        KeychainService.store("to-be-deleted", key: testKey)
        KeychainService.delete(key: testKey)
        let retrieved = KeychainService.retrieve(key: testKey)
        XCTAssertNil(retrieved)
    }

    func testDelete_nonexistentKey_doesNotCrash() {
        // Should not throw or crash when deleting a key that was never stored
        KeychainService.delete(key: testKey)
        XCTAssertNil(KeychainService.retrieve(key: testKey))
    }

    // MARK: - hasCredentials

    func testHasCredentials_returnsFalse_whenNeitherKeyStored() {
        XCTAssertFalse(KeychainService.hasCredentials())
    }

    func testHasCredentials_returnsTrue_whenBothKeysStored() {
        KeychainService.store("session-value", key: KeychainService.sessionKey)
        KeychainService.store("csrf-value", key: KeychainService.csrfKey)
        XCTAssertTrue(KeychainService.hasCredentials())
    }

    func testHasCredentials_returnsFalse_whenOnlySessionStored() {
        KeychainService.store("session-value", key: KeychainService.sessionKey)
        XCTAssertFalse(KeychainService.hasCredentials())
    }

    func testHasCredentials_returnsFalse_whenOnlyCsrfStored() {
        KeychainService.store("csrf-value", key: KeychainService.csrfKey)
        XCTAssertFalse(KeychainService.hasCredentials())
    }

    // MARK: - clearAll

    func testClearAll_removesSessionAndCsrf() {
        KeychainService.store("session-value", key: KeychainService.sessionKey)
        KeychainService.store("csrf-value", key: KeychainService.csrfKey)
        KeychainService.clearAll()
        XCTAssertNil(KeychainService.retrieve(key: KeychainService.sessionKey))
        XCTAssertNil(KeychainService.retrieve(key: KeychainService.csrfKey))
        XCTAssertFalse(KeychainService.hasCredentials())
    }

    // MARK: - Empty string

    func testStore_emptyString_roundtrip() {
        KeychainService.store("", key: testKey)
        let retrieved = KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrieved, "")
    }

    func testHasCredentials_returnsFalse_whenEmptyStringStored() {
        KeychainService.store("", key: KeychainService.sessionKey)
        KeychainService.store("", key: KeychainService.csrfKey)
        XCTAssertFalse(KeychainService.hasCredentials())
    }
}
