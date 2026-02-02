import Foundation

/// Manages persistence of matches and messages
public final class MatchStore: @unchecked Sendable {
    public static let shared = MatchStore()
    
    private let storage = AppGroupStorage.shared
    private let secureStore = SecureStore.shared
    private let defaults = UserDefaults.appGroup
    
    private init() {}
    
    // MARK: - User Profile
    
    /// Save user profile (encrypted)
    public func saveUserProfile(_ profile: UserProfile) {
        guard let container = storage.containerURL else { return }
        let url = container.appendingPathComponent("userProfile.enc")
        try? secureStore.saveSecure(profile, to: url)
    }
    
    /// Load user profile
    public func loadUserProfile() -> UserProfile? {
        guard let container = storage.containerURL else { return nil }
        let url = container.appendingPathComponent("userProfile.enc")
        return try? secureStore.loadSecure(UserProfile.self, from: url)
    }
    
    // MARK: - Match Index
    
    /// Save match index
    private func saveMatchIndex(_ index: [MatchIndexEntry]) {
        guard let container = storage.containerURL else { return }
        let url = container.appendingPathComponent("matchIndex.json")
        try? storage.save(index, to: url)
    }
    
    /// Load match index
    public func loadMatchIndex() -> [MatchIndexEntry] {
        guard let container = storage.containerURL else { return [] }
        let url = container.appendingPathComponent("matchIndex.json")
        return (try? storage.load([MatchIndexEntry].self, from: url)) ?? []
    }
    
    // MARK: - Individual Matches
    
    /// Save a match profile (encrypted)
    public func saveMatch(_ match: MatchProfile) {
        guard let matchesDir = storage.matchesDirectory else { return }
        let url = matchesDir.appendingPathComponent("\(match.matchId.uuidString).enc")
        try? secureStore.saveSecure(match, to: url)
        
        // Update index
        var index = loadMatchIndex()
        index.removeAll { $0.matchId == match.matchId }
        index.insert(MatchIndexEntry(from: match), at: 0)
        saveMatchIndex(index)
    }
    
    /// Load a single match
    public func loadMatch(_ matchId: UUID) -> MatchProfile? {
        guard let matchesDir = storage.matchesDirectory else { return nil }
        let url = matchesDir.appendingPathComponent("\(matchId.uuidString).enc")
        return try? secureStore.loadSecure(MatchProfile.self, from: url)
    }
    
    /// Load all matches (sorted by most recent)
    public func loadAllMatches() -> [MatchProfile] {
        let index = loadMatchIndex()
        return index.compactMap { loadMatch($0.matchId) }
    }
    
    /// Delete a match
    public func deleteMatch(_ matchId: UUID) {
        guard let matchesDir = storage.matchesDirectory,
              let messagesDir = storage.messagesDirectory else { return }
        
        // Delete match file
        let matchUrl = matchesDir.appendingPathComponent("\(matchId.uuidString).enc")
        try? storage.delete(at: matchUrl)
        
        // Delete associated messages
        let messagesUrl = messagesDir.appendingPathComponent("\(matchId.uuidString).enc")
        try? storage.delete(at: messagesUrl)
        
        // Update index
        var index = loadMatchIndex()
        index.removeAll { $0.matchId == matchId }
        saveMatchIndex(index)
    }
    
    // MARK: - Generated Messages
    
    /// Save generated messages for a match
    public func saveMessages(_ messageSet: GeneratedMessageSet) {
        guard let messagesDir = storage.messagesDirectory else { return }
        let url = messagesDir.appendingPathComponent("\(messageSet.matchId.uuidString).enc")
        try? secureStore.saveSecure(messageSet, to: url)
    }
    
    /// Load generated messages for a match
    public func loadMessages(for matchId: UUID) -> GeneratedMessageSet? {
        guard let messagesDir = storage.messagesDirectory else { return nil }
        let url = messagesDir.appendingPathComponent("\(matchId.uuidString).enc")
        return try? secureStore.loadSecure(GeneratedMessageSet.self, from: url)
    }
    
    // MARK: - Last Selected Match (for keyboard)
    
    /// Save the last selected match ID
    public func saveLastSelectedMatch(_ matchId: UUID) {
        defaults.set(matchId.uuidString, forKey: AppGroupConstants.lastSelectedMatchKey)
    }
    
    /// Load the last selected match ID
    public func loadLastSelectedMatchId() -> UUID? {
        guard let string = defaults.string(forKey: AppGroupConstants.lastSelectedMatchKey) else { return nil }
        return UUID(uuidString: string)
    }
    
    // MARK: - Data Management
    
    /// Delete all user data
    public func deleteAllData() {
        guard let container = storage.containerURL else { return }
        
        // Delete all files in container
        let fileManager = FileManager.default
        if let contents = try? fileManager.contentsOfDirectory(at: container, includingPropertiesForKeys: nil) {
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
        
        // Clear UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleId)
        }
        
        // Delete encryption keys
        secureStore.deleteAllKeys()
    }
    
    // MARK: - Share Extension Inbox
    
    /// Read share extension manifest
    public func readShareInboxManifest() -> ShareInboxManifest? {
        guard let inbox = storage.shareInboxDirectory else { return nil }
        let manifestUrl = inbox.appendingPathComponent(AppGroupConstants.shareInboxManifestFile)
        return try? storage.load(ShareInboxManifest.self, from: manifestUrl)
    }
    
    /// Get share inbox image URLs
    public func getShareInboxImageURLs() -> [URL] {
        guard let manifest = readShareInboxManifest(),
              let inbox = storage.shareInboxDirectory else { return [] }
        return manifest.imageFiles.map { inbox.appendingPathComponent($0) }
    }
    
    /// Get share inbox video URL (if present)
    public func getShareInboxVideoURL() -> URL? {
        guard let manifest = readShareInboxManifest(),
              let videoFile = manifest.videoFile,
              let inbox = storage.shareInboxDirectory else { return nil }
        return inbox.appendingPathComponent(videoFile)
    }
    
    /// Check if share inbox has a video
    public func shareInboxHasVideo() -> Bool {
        readShareInboxManifest()?.hasVideo ?? false
    }
    
    /// Clear share extension inbox
    public func clearShareInbox() {
        guard let inbox = storage.shareInboxDirectory else { return }
        let fileManager = FileManager.default
        if let contents = try? fileManager.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil) {
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
