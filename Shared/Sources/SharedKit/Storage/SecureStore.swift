import Foundation
import CryptoKit

/// Provides encryption for sensitive data at rest
public final class SecureStore: @unchecked Sendable {
    public static let shared = SecureStore()
    
    private let keychain = KeychainHelper.shared
    private let keyIdentifier = "com.onepercent.encryption.key"
    
    private init() {}
    
    /// Get or create the encryption key
    private func getOrCreateKey() throws -> SymmetricKey {
        // Try to load existing key from keychain
        if let keyData = keychain.read(service: keyIdentifier, account: "main") {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try keychain.save(keyData, service: keyIdentifier, account: "main")
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
        keychain.delete(service: keyIdentifier, account: "main")
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
    
    private init() {}
    
    public func save(_ data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: "$(AppIdentifierPrefix)com.onepercent.shared",
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    public func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: "$(AppIdentifierPrefix)com.onepercent.shared",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    public func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: "$(AppIdentifierPrefix)com.onepercent.shared"
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum KeychainError: Error {
    case unableToSave
    case unableToRead
}
