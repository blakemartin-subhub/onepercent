import Foundation

/// A match's profile extracted from screenshots
public struct MatchProfile: Codable, Identifiable, Sendable, Hashable {
    public var matchId: UUID
    public var name: String?
    public var age: Int?
    public var bio: String?
    public var prompts: [PromptAnswer]
    public var interests: [String]
    public var job: String?
    public var school: String?
    public var location: String?
    public var hooks: [String]
    public var rawOcrText: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public var id: UUID { matchId }
    
    /// Display name with fallback
    public var displayName: String {
        name ?? "Unknown"
    }
    
    /// Brief summary for display
    public var summary: String {
        var parts: [String] = []
        if let age = age { parts.append("\(age)") }
        if let location = location { parts.append(location) }
        if let job = job { parts.append(job) }
        return parts.joined(separator: " • ")
    }
    
    public init(
        matchId: UUID = UUID(),
        name: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        prompts: [PromptAnswer] = [],
        interests: [String] = [],
        job: String? = nil,
        school: String? = nil,
        location: String? = nil,
        hooks: [String] = [],
        rawOcrText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.matchId = matchId
        self.name = name
        self.age = age
        self.bio = bio
        self.prompts = prompts
        self.interests = interests
        self.job = job
        self.school = school
        self.location = location
        self.hooks = hooks
        self.rawOcrText = rawOcrText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// A prompt and its answer from the dating profile
public struct PromptAnswer: Codable, Identifiable, Sendable, Hashable {
    public var id: UUID
    public var prompt: String
    public var answer: String
    
    public init(id: UUID = UUID(), prompt: String, answer: String) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }
}

/// Lightweight match reference for the index
public struct MatchIndexEntry: Codable, Identifiable, Sendable {
    public var matchId: UUID
    public var name: String?
    public var updatedAt: Date
    
    public var id: UUID { matchId }
    
    public init(matchId: UUID, name: String?, updatedAt: Date) {
        self.matchId = matchId
        self.name = name
        self.updatedAt = updatedAt
    }
    
    public init(from match: MatchProfile) {
        self.matchId = match.matchId
        self.name = match.name
        self.updatedAt = match.updatedAt
    }
}
