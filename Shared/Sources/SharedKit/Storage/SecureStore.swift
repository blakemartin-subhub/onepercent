import Foundation
import CryptoKit

/// Provides encryption for sensitive data at rest
public final class SecureStore: @unchecked Sendable {
    public static let shared = SecureStore()
    
    private let keyIdentifier = "com.onepercent.encryption.key"
    
    private init() {}
    
    /// Get or create the encryption key
    /// Stores key in App Group container for sharing between app and extensions
    private func getOrCreateKey() throws -> SymmetricKey {
        let defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)
        
        // Try to load existing key from App Group UserDefaults
        if let keyData = defaults?.data(forKey: keyIdentifier) {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key and save to App Group
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        defaults?.set(keyData, forKey: keyIdentifier)
        return key
    }
    
    /// Encrypt data using AES-GCM
    public func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw SecureStoreError.encryptionFailed
        }
        return combined
    }
    
    /// Decrypt data using AES-GCM
    public func decrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// Encrypt and save a Codable object
    public func saveSecure<T: Codable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(value)
        let encryptedData = try encrypt(jsonData)
        
        // Atomic write
        let tempURL = url.appendingPathExtension("tmp")
        try encryptedData.write(to: tempURL, options: .atomic)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: tempURL, to: url)
    }
    
    /// Load and decrypt a Codable object
    public func loadSecure<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        let encryptedData = try Data(contentsOf: url)
        let jsonData = try decrypt(encryptedData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: jsonData)
    }
    
    /// Delete all encryption keys (for complete data wipe)
    public func deleteAllKeys() {
        let defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)
        defaults?.removeObject(forKey: keyIdentifier)
    }
}

public enum SecureStoreError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Failed to encrypt data"
        case .decryptionFailed: return "Failed to decrypt data"
        case .keyGenerationFailed: return "Failed to generate encryption key"
        }
    }
}

/// Simple keychain wrapper
public final class KeychainHelper: @unchecked Sendable {
    public static let shared = KeychainHelper()
    
    /// The keychain access group for sharing between app and extensions
    /// This is derived at runtime from the app's bundle seed ID
    private var accessGroup: String? {
        // Get the team ID from the app's entitlements
        guard let teamID = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String ??
              getTeamIdFromProvisioning() else {
            return nil
        }
        let cleanTeamID = teamID.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return "\(cleanTeamID).com.dave.onepercent.shared"
    }
    
    /// Try to get team ID from the embedded provisioning profile
    private func getTeamIdFromProvisioning() -> String? {
        // First try to query an existing keychain item to get the access group
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.onepercent.teamid.check",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let attrs = result as? [String: Any],
           let group = attrs[kSecAttrAccessGroup as String] as? String {
            // Extract team ID from access group (format: TEAMID.bundleid)
            let components = group.components(separatedBy: ".")
            if let teamID = components.first, !teamID.isEmpty {
                return teamID
            }
        }
        return nil
    }
    
    private init() {}
    
    public func save(_ data: Data, service: String, account: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Add access group if available for sharing between app and extensions
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    public func read(service: String, account: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    public func delete(service: String, account: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        SecItemDelete(query as CFDictionary)
    }
}

public enum KeychainError: Error {
    case unableToSave
    case unableToRead
}
