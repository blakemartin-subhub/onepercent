import Foundation

/// The user's own profile and preferences
public struct UserProfile: Codable, Identifiable, Sendable {
    public var id: UUID
    public var displayName: String
    public var ageRange: String?
    public var bio: String?
    public var voiceTone: VoiceTone
    public var voiceTones: [VoiceTone]  // Multiple tones
    public var hardBoundaries: [String]
    public var datingIntent: String?
    public var emojiStyle: EmojiStyle
    public var profileContext: String?  // OCR'd profile info
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        displayName: String,
        ageRange: String? = nil,
        bio: String? = nil,
        voiceTone: VoiceTone = .playful,
        voiceTones: [VoiceTone] = [],
        hardBoundaries: [String] = [],
        datingIntent: String? = nil,
        emojiStyle: EmojiStyle = .light,
        profileContext: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.ageRange = ageRange
        self.bio = bio
        self.voiceTone = voiceTone
        self.voiceTones = voiceTones
        self.hardBoundaries = hardBoundaries
        self.datingIntent = datingIntent
        self.emojiStyle = emojiStyle
        self.profileContext = profileContext
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Voice/tone preference for generated messages
public enum VoiceTone: String, Codable, CaseIterable, Sendable {
    case playful = "playful"
    case direct = "direct"
    case witty = "witty"
    case warm = "warm"
    case confident = "confident"
    case spicy = "spicy"
    
    public var displayName: String {
        switch self {
        case .playful: return "Playful"
        case .direct: return "Direct"
        case .witty: return "Witty"
        case .warm: return "Warm"
        case .confident: return "Confident"
        case .spicy: return "Spicy 🔥"
        }
    }
    
    public var description: String {
        switch self {
        case .playful: return "Fun, light-hearted, uses humor"
        case .direct: return "Straightforward, clear, to the point"
        case .witty: return "Clever, quick, intellectually playful"
        case .warm: return "Friendly, genuine, emotionally open"
        case .confident: return "Self-assured, bold, engaging"
        case .spicy: return "Looking for short term fun"
        }
    }
}

/// Emoji usage preference
public enum EmojiStyle: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case light = "light"
    case heavy = "heavy"
    
    public var displayName: String {
        switch self {
        case .none: return "No emojis"
        case .light: return "Light (1-2 max)"
        case .heavy: return "Heavy (expressive)"
        }
    }
}
