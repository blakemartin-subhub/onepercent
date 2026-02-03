import Foundation

/// A set of generated messages for a match
public struct GeneratedMessageSet: Codable, Identifiable, Sendable {
    public var id: UUID
    public var matchId: UUID
    public var messages: [GeneratedMessage]
    public var toneUsed: VoiceTone
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        matchId: UUID,
        messages: [GeneratedMessage],
        toneUsed: VoiceTone,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.matchId = matchId
        self.messages = messages
        self.toneUsed = toneUsed
        self.createdAt = createdAt
    }
}

/// A single generated message
public struct GeneratedMessage: Codable, Identifiable, Sendable {
    public var id: UUID
    public var type: MessageType
    public var text: String
    public var order: Int?
    public var riskFlags: [String]?
    public var reasoning: String?
    public var potentialOutcome: String?
    
    public init(
        id: UUID = UUID(),
        type: MessageType,
        text: String,
        order: Int? = nil,
        riskFlags: [String]? = nil,
        reasoning: String? = nil,
        potentialOutcome: String? = nil
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.order = order
        self.riskFlags = riskFlags
        self.reasoning = reasoning
        self.potentialOutcome = potentialOutcome
    }
    
    /// Get message broken into separate lines
    public var lines: [String] {
        text.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}

/// Type of message
public enum MessageType: String, Codable, Sendable {
    case opener = "opener"
    case followup = "followup"
    case hook = "hook"
    case question = "question"
    case reply = "reply"
    
    public var displayName: String {
        switch self {
        case .opener: return "Opener"
        case .followup: return "Follow-up"
        case .hook: return "Hook"
        case .question: return "Question"
        case .reply: return "Reply"
        }
    }
}

/// API response for message generation
public struct GenerateMessagesResponse: Codable, Sendable {
    public var messages: [GeneratedMessage]
    
    public init(messages: [GeneratedMessage]) {
        self.messages = messages
    }
}

/// API response for profile parsing
public struct ParseProfileResponse: Codable, Sendable {
    public var name: String?
    public var nameCandidates: [String]?
    public var age: Int?
    public var bio: String?
    public var prompts: [PromptAnswer]?
    public var interests: [String]?
    public var job: String?
    public var school: String?
    public var location: String?
    public var hooks: [String]?
    public var confidence: Double?
    
    public init(
        name: String? = nil,
        nameCandidates: [String]? = nil,
        age: Int? = nil,
        bio: String? = nil,
        prompts: [PromptAnswer]? = nil,
        interests: [String]? = nil,
        job: String? = nil,
        school: String? = nil,
        location: String? = nil,
        hooks: [String]? = nil,
        confidence: Double? = nil
    ) {
        self.name = name
        self.nameCandidates = nameCandidates
        self.age = age
        self.bio = bio
        self.prompts = prompts
        self.interests = interests
        self.job = job
        self.school = school
        self.location = location
        self.hooks = hooks
        self.confidence = confidence
    }
    
    /// Convert to MatchProfile
    public func toMatchProfile(rawOcrText: String? = nil) -> MatchProfile {
        MatchProfile(
            name: name,
            age: age,
            bio: bio,
            prompts: prompts ?? [],
            interests: interests ?? [],
            job: job,
            school: school,
            location: location,
            hooks: hooks ?? [],
            rawOcrText: rawOcrText
        )
    }
}
