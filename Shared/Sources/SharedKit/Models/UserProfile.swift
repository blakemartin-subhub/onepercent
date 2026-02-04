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
    public var activities: [String]  // What they like to do
    public var nationalities: [String]  // User's cultural background (Italian, Mexican, etc.)
    public var firstDateGoal: FirstDateGoal?  // Preferred first date type
    public var createdAt: Date
    public var updatedAt: Date
    
    // Coding keys for migration support
    private enum CodingKeys: String, CodingKey {
        case id, displayName, ageRange, bio, voiceTone, voiceTones
        case hardBoundaries, datingIntent, emojiStyle, profileContext
        case activities, nationalities, firstDateGoal, createdAt, updatedAt
        // Legacy key for backward compatibility
        case ethnicity
    }
    
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
        activities: [String] = [],
        nationalities: [String] = [],
        firstDateGoal: FirstDateGoal? = nil,
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
        self.activities = activities
        self.nationalities = nationalities
        self.firstDateGoal = firstDateGoal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom decoder for backward compatibility with old 'ethnicity' field
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        displayName = try container.decode(String.self, forKey: .displayName)
        ageRange = try container.decodeIfPresent(String.self, forKey: .ageRange)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        voiceTone = try container.decodeIfPresent(VoiceTone.self, forKey: .voiceTone) ?? .playful
        voiceTones = try container.decodeIfPresent([VoiceTone].self, forKey: .voiceTones) ?? []
        hardBoundaries = try container.decodeIfPresent([String].self, forKey: .hardBoundaries) ?? []
        datingIntent = try container.decodeIfPresent(String.self, forKey: .datingIntent)
        emojiStyle = try container.decodeIfPresent(EmojiStyle.self, forKey: .emojiStyle) ?? .light
        profileContext = try container.decodeIfPresent(String.self, forKey: .profileContext)
        activities = try container.decodeIfPresent([String].self, forKey: .activities) ?? []
        firstDateGoal = try container.decodeIfPresent(FirstDateGoal.self, forKey: .firstDateGoal)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        
        // Handle migration: try nationalities first, fall back to ethnicity
        if let nats = try container.decodeIfPresent([String].self, forKey: .nationalities) {
            nationalities = nats
        } else if let oldEthnicity = try container.decodeIfPresent(String.self, forKey: .ethnicity) {
            // Migrate old ethnicity to nationalities (if it's not empty)
            nationalities = oldEthnicity.isEmpty ? [] : [oldEthnicity]
        } else {
            nationalities = []
        }
    }
    
    // Custom encoder (only encode nationalities, not ethnicity)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(ageRange, forKey: .ageRange)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(voiceTone, forKey: .voiceTone)
        try container.encode(voiceTones, forKey: .voiceTones)
        try container.encode(hardBoundaries, forKey: .hardBoundaries)
        try container.encodeIfPresent(datingIntent, forKey: .datingIntent)
        try container.encode(emojiStyle, forKey: .emojiStyle)
        try container.encodeIfPresent(profileContext, forKey: .profileContext)
        try container.encode(activities, forKey: .activities)
        try container.encode(nationalities, forKey: .nationalities)
        try container.encodeIfPresent(firstDateGoal, forKey: .firstDateGoal)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
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
        case .spicy: return "Spicy"
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

/// First date goal preference
public enum FirstDateGoal: String, Codable, CaseIterable, Sendable {
    case coffee = "coffee"
    case drinks = "drinks"
    case dinner = "dinner"
    case activity = "activity"
    case cooking = "cooking"
    case walkPark = "walk_park"
    
    public var displayName: String {
        switch self {
        case .coffee: return "Coffee"
        case .drinks: return "Drinks"
        case .dinner: return "Dinner"
        case .activity: return "Activity"
        case .cooking: return "Cook Together"
        case .walkPark: return "Walk in Park"
        }
    }
    
    public var promptDescription: String {
        switch self {
        case .coffee: return "a casual coffee date"
        case .drinks: return "grabbing drinks"
        case .dinner: return "dinner together"
        case .activity: return "doing an activity together"
        case .cooking: return "cooking a meal together"
        case .walkPark: return "a walk in the park"
        }
    }
}

/// Common activities for dating profiles
public enum Activity: String, CaseIterable {
    case cooking = "Cooking"
    case hiking = "Hiking"
    case travel = "Travel"
    case fitness = "Fitness"
    case music = "Music"
    case movies = "Movies"
    case reading = "Reading"
    case gaming = "Gaming"
    case photography = "Photography"
    case art = "Art"
    case dancing = "Dancing"
    case sports = "Sports"
    case yoga = "Yoga"
    case wine = "Wine"
    case coffee = "Coffee"
    case foodie = "Foodie"
    case outdoors = "Outdoors"
    case nightlife = "Nightlife"
}

/// Nationalities/Cultural backgrounds for conversation context
public enum Nationality: String, CaseIterable {
    case italian = "Italian"
    case mexican = "Mexican"
    case irish = "Irish"
    case german = "German"
    case french = "French"
    case spanish = "Spanish"
    case british = "British"
    case polish = "Polish"
    case greek = "Greek"
    case portuguese = "Portuguese"
    case indian = "Indian"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case korean = "Korean"
    case filipino = "Filipino"
    case vietnamese = "Vietnamese"
    case brazilian = "Brazilian"
    case colombian = "Colombian"
    case cuban = "Cuban"
    case puerto_rican = "Puerto Rican"
    case jamaican = "Jamaican"
    case nigerian = "Nigerian"
    case ethiopian = "Ethiopian"
    case lebanese = "Lebanese"
    case persian = "Persian"
    case russian = "Russian"
    case ukrainian = "Ukrainian"
    case swedish = "Swedish"
    case norwegian = "Norwegian"
    case dutch = "Dutch"
    case swiss = "Swiss"
    case australian = "Australian"
    case canadian = "Canadian"
    case american = "American"
    
    /// Cultural traits that can be used in conversation
    public var culturalTraits: [String] {
        switch self {
        case .italian: return ["cooking", "romantic", "passionate", "family-oriented", "good with food & wine"]
        case .mexican: return ["great cooks", "family values", "festive", "warm", "love good food"]
        case .irish: return ["great storytellers", "fun at pubs", "witty humor", "charming"]
        case .german: return ["punctual", "efficient", "beer lovers", "direct"]
        case .french: return ["romantic", "cultured", "good taste", "love wine & cheese"]
        case .spanish: return ["passionate", "love to dance", "late nights", "family-oriented"]
        case .greek: return ["hospitable", "great food", "family values", "love to celebrate"]
        case .indian: return ["great cooks", "family-oriented", "cultured", "spice lovers"]
        case .japanese: return ["detail-oriented", "respectful", "great taste", "adventurous eaters"]
        case .korean: return ["great cooks", "skincare experts", "K-culture", "foodies"]
        case .brazilian: return ["fun-loving", "great dancers", "warm", "beach vibes"]
        case .lebanese: return ["amazing cooks", "hospitable", "family-oriented", "love good food"]
        case .persian: return ["romantic poetry", "great cooks", "cultured", "hospitable"]
        default: return []
        }
    }
}
