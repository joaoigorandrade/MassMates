import Foundation
import Security
import Synchronization

/// The narrow seam the session store uses to persist the Supabase session.
/// Tests inject an in-memory double so they never touch the real Keychain.
protocol KeychainStoring: Sendable {
    func save(_ data: Data, for key: String) throws
    func load(for key: String) throws -> Data?
    func delete(for key: String) throws
}

/// A thin wrapper over the Apple `Security` framework. Items are stored with
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: readable after the first
/// unlock, never migrated to another device, never in an iCloud backup.
struct KeychainStore: KeychainStoring {
    // MARK: - Dependencies & State
    private let service: String

    // MARK: - Init
    init(service: String = "com.massmates.supabase.session") {
        self.service = service
    }

    // MARK: - Body / Public API
    func save(_ data: Data, for key: String) throws {
        let query = baseQuery(for: key)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard updateStatus == errSecItemNotFound else {
            guard updateStatus == errSecSuccess else { throw BackendError.keychain(updateStatus) }
            return
        }
        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(insert as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw BackendError.keychain(addStatus) }
    }

    func load(for key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw BackendError.keychain(status) }
        return item as? Data
    }

    func delete(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BackendError.keychain(status)
        }
    }

    // MARK: - Subviews / Private Helpers
    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

/// An in-memory `KeychainStoring` used by the unit tests and by previews.
final class InMemoryKeychainStore: KeychainStoring, Sendable {
    private let storage = Mutex<[String: Data]>([:])

    func save(_ data: Data, for key: String) throws {
        storage.withLock { storage in
            storage[key] = data
            return ()
        }
    }

    func load(for key: String) throws -> Data? {
        storage.withLock { $0[key] }
    }

    func delete(for key: String) throws {
        storage.withLock { storage in
            storage.removeValue(forKey: key)
            return ()
        }
    }
}
