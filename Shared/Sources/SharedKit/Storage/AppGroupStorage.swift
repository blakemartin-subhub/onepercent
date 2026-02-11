import Foundation

/// Constants for App Group storage
public enum AppGroupConstants {
    public static let groupIdentifier = "group.com.blakemartin.onepercentapp"
    public static let userProfileKey = "userProfile"
    public static let matchIndexKey = "matchIndex"
    public static let lastSelectedMatchKey = "lastSelectedMatchId"
    public static let shareInboxManifestFile = "shareInbox.json"
}

/// Extension for UserDefaults with App Group support
public extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)!
}

/// Provides access to the App Group container
public final class AppGroupStorage: @unchecked Sendable {
    public static let shared = AppGroupStorage()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// URL of the shared App Group container
    public var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.groupIdentifier)
    }
    
    /// Directory for storing match data
    public var matchesDirectory: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent("matches", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Directory for storing generated messages
    public var messagesDirectory: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent("messages", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Directory for share extension inbox
    public var shareInboxDirectory: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent("shareInbox", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic File Operations
    
    /// Save a Codable object to a file atomically
    public func save<T: Codable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        let tempURL = url.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)
        
        // Atomic replace
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: tempURL, to: url)
    }
    
    /// Load a Codable object from a file
    public func load<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    /// Delete a file
    public func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    /// Check if a file exists
    public func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// List all files in a directory
    public func listFiles(in directory: URL) -> [URL] {
        (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }
}

/// Share extension inbox manifest
public struct ShareInboxManifest: Codable, Sendable {
    public var imageFiles: [String]
    public var videoFile: String?
    public var createdAt: Date
    
    public init(imageFiles: [String], videoFile: String? = nil, createdAt: Date = Date()) {
        self.imageFiles = imageFiles
        self.videoFile = videoFile
        self.createdAt = createdAt
    }
    
    // Defensive decoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageFiles = try container.decodeIfPresent([String].self, forKey: .imageFiles) ?? []
        videoFile = try container.decodeIfPresent(String.self, forKey: .videoFile)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
    
    private enum CodingKeys: String, CodingKey {
        case imageFiles, videoFile, createdAt
    }
    
    /// Check if this manifest contains a video
    public var hasVideo: Bool {
        videoFile != nil
    }
}
