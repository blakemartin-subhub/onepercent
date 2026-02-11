import Foundation

/// The user's own profile and preferences
public struct UserProfile: Codable, Identifiable, Sendable {
    public var id: UUID
    public var displayName: String
    public var ageRange: String?
    public var bio: String?
    public var voiceTone: VoiceTone
    public var voiceTones: [VoiceTone]
    public var datingIntent: String?
    public var emojiStyle: EmojiStyle
    public var activities: [String]
    public var nationalities: [String]
    public var firstDateGoal: FirstDateGoal?
    
    // Template-aligned fields (power the template matching system)
    public var canCook: Bool?
    public var cookingLevel: CookingLevel?
    public var cuisineTypes: [String]?
    public var playsMusic: Bool?
    public var instruments: [String]?
    public var instrumentLevel: InstrumentLevel?
    public var outdoorActivities: [String]?
    public var localSpots: [String]?
    
    public var createdAt: Date
    public var updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, displayName, ageRange, bio, voiceTone, voiceTones
        case datingIntent, emojiStyle
        case activities, nationalities, firstDateGoal
        case canCook, cookingLevel, cuisineTypes
        case playsMusic, instruments, instrumentLevel
        case outdoorActivities, localSpots
        case createdAt, updatedAt
        // Legacy keys
        case ethnicity, hardBoundaries, profileContext
    }
    
    public init(
        id: UUID = UUID(),
        displayName: String,
        ageRange: String? = nil,
        bio: String? = nil,
        voiceTone: VoiceTone = .playful,
        voiceTones: [VoiceTone] = [],
        datingIntent: String? = nil,
        emojiStyle: EmojiStyle = .light,
        activities: [String] = [],
        nationalities: [String] = [],
        firstDateGoal: FirstDateGoal? = nil,
        canCook: Bool? = nil,
        cookingLevel: CookingLevel? = nil,
        cuisineTypes: [String]? = nil,
        playsMusic: Bool? = nil,
        instruments: [String]? = nil,
        instrumentLevel: InstrumentLevel? = nil,
        outdoorActivities: [String]? = nil,
        localSpots: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.ageRange = ageRange
        self.bio = bio
        self.voiceTone = voiceTone
        self.voiceTones = voiceTones
        self.datingIntent = datingIntent
        self.emojiStyle = emojiStyle
        self.activities = activities
        self.nationalities = nationalities
        self.firstDateGoal = firstDateGoal
        self.canCook = canCook
        self.cookingLevel = cookingLevel
        self.cuisineTypes = cuisineTypes
        self.playsMusic = playsMusic
        self.instruments = instruments
        self.instrumentLevel = instrumentLevel
        self.outdoorActivities = outdoorActivities
        self.localSpots = localSpots
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Backward-compatible decoder (handles old profiles with hardBoundaries, profileContext, ethnicity)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        displayName = try container.decode(String.self, forKey: .displayName)
        ageRange = try container.decodeIfPresent(String.self, forKey: .ageRange)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        voiceTone = try container.decodeIfPresent(VoiceTone.self, forKey: .voiceTone) ?? .playful
        voiceTones = try container.decodeIfPresent([VoiceTone].self, forKey: .voiceTones) ?? []
        datingIntent = try container.decodeIfPresent(String.self, forKey: .datingIntent)
        emojiStyle = try container.decodeIfPresent(EmojiStyle.self, forKey: .emojiStyle) ?? .light
        activities = try container.decodeIfPresent([String].self, forKey: .activities) ?? []
        firstDateGoal = try container.decodeIfPresent(FirstDateGoal.self, forKey: .firstDateGoal)
        
        // Template-aligned fields
        canCook = try container.decodeIfPresent(Bool.self, forKey: .canCook)
        cookingLevel = try container.decodeIfPresent(CookingLevel.self, forKey: .cookingLevel)
        cuisineTypes = try container.decodeIfPresent([String].self, forKey: .cuisineTypes)
        playsMusic = try container.decodeIfPresent(Bool.self, forKey: .playsMusic)
        instruments = try container.decodeIfPresent([String].self, forKey: .instruments)
        instrumentLevel = try container.decodeIfPresent(InstrumentLevel.self, forKey: .instrumentLevel)
        outdoorActivities = try container.decodeIfPresent([String].self, forKey: .outdoorActivities)
        localSpots = try container.decodeIfPresent([String].self, forKey: .localSpots)
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        
        // Handle migration: try nationalities first, fall back to ethnicity
        if let nats = try container.decodeIfPresent([String].self, forKey: .nationalities) {
            nationalities = nats
        } else if let oldEthnicity = try container.decodeIfPresent(String.self, forKey: .ethnicity) {
            nationalities = oldEthnicity.isEmpty ? [] : [oldEthnicity]
        } else {
            nationalities = []
        }
        
        // Legacy fields silently ignored (hardBoundaries, profileContext)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(ageRange, forKey: .ageRange)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(voiceTone, forKey: .voiceTone)
        try container.encode(voiceTones, forKey: .voiceTones)
        try container.encodeIfPresent(datingIntent, forKey: .datingIntent)
        try container.encode(emojiStyle, forKey: .emojiStyle)
        try container.encode(activities, forKey: .activities)
        try container.encode(nationalities, forKey: .nationalities)
        try container.encodeIfPresent(firstDateGoal, forKey: .firstDateGoal)
        try container.encodeIfPresent(canCook, forKey: .canCook)
        try container.encodeIfPresent(cookingLevel, forKey: .cookingLevel)
        try container.encodeIfPresent(cuisineTypes, forKey: .cuisineTypes)
        try container.encodeIfPresent(playsMusic, forKey: .playsMusic)
        try container.encodeIfPresent(instruments, forKey: .instruments)
        try container.encodeIfPresent(instrumentLevel, forKey: .instrumentLevel)
        try container.encodeIfPresent(outdoorActivities, forKey: .outdoorActivities)
        try container.encodeIfPresent(localSpots, forKey: .localSpots)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Enums

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

public enum CookingLevel: String, Codable, CaseIterable, Sendable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Pretty Good"
        case .advanced: return "Chef Level"
        }
    }
}

public enum InstrumentLevel: String, Codable, CaseIterable, Sendable {
    case learning = "learning"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    public var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .intermediate: return "Can Play"
        case .advanced: return "Expert"
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
    case surfing = "Surfing"
    case snowboarding = "Snowboarding"
    case skiing = "Skiing"
    case rockClimbing = "Rock Climbing"
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
}
