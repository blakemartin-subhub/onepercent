import Foundation
import SharedKit

/// API client for keyboard extension
actor KeyboardAPIClient {
    static let shared = KeyboardAPIClient()
    
    // Backend URL - Your Mac's IP address (on iPhone hotspot)
    private let baseURL = "http://172.20.10.10:3002"
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90  // Increased for OpenAI API calls
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }
    
    /// Parse OCR text into structured profile
    func parseProfile(ocrText: String) async throws -> KeyboardParseProfileResponse {
        let request = KeyboardParseProfileRequest(ocrText: ocrText)
        return try await post("/v1/profile/parse", body: request)
    }
    
    /// Generate messages for a match (new opener)
    func generateMessages(
        userProfile: UserProfile,
        matchProfile: MatchProfile
    ) async throws -> (messages: [GeneratedMessage], reasoning: String?) {
        let request = KeyboardGenerateMessagesRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            conversationContext: nil
        )
        
        let response: KeyboardGenerateMessagesResponse = try await post("/v1/message/generate", body: request)
        return (response.messages, response.reasoning)
    }
    
    /// Generate follow-up messages based on conversation context
    func generateConversationMessages(
        userProfile: UserProfile,
        matchProfile: MatchProfile,
        conversationContext: String
    ) async throws -> (messages: [GeneratedMessage], reasoning: String?) {
        let request = KeyboardGenerateMessagesRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            conversationContext: conversationContext
        )
        
        let response: KeyboardGenerateMessagesResponse = try await post("/v1/message/generate", body: request)
        return (response.messages, response.reasoning)
    }
    
    /// Regenerate a single line in a message sequence
    func regenerateLine(
        userProfile: UserProfile,
        matchProfile: MatchProfile,
        allMessages: [String],
        lineIndex: Int,
        tone: String? = nil
    ) async throws -> (text: String, reasoning: String?) {
        let request = KeyboardRegenLineRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            allMessages: allMessages,
            lineIndex: lineIndex,
            tone: tone
        )
        
        let response: KeyboardRegenLineResponse = try await post("/v1/message/regen-line", body: request)
        return (response.text, response.reasoning)
    }
    
    private func post<T: Encodable, R: Decodable>(_ path: String, body: T) async throws -> R {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use device ID from UserDefaults
        let deviceToken = getDeviceToken()
        request.setValue("Bearer \(deviceToken)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyboardAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(KeyboardAPIErrorResponse.self, from: data) {
                throw KeyboardAPIError.serverError(errorResponse.message)
            }
            throw KeyboardAPIError.httpError(httpResponse.statusCode)
        }
        
        return try decoder.decode(R.self, from: data)
    }
    
    private func getDeviceToken() -> String {
        let defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)
        if let token = defaults?.string(forKey: "deviceToken") {
            return token
        }
        let token = UUID().uuidString
        defaults?.set(token, forKey: "deviceToken")
        return token
    }
}

// MARK: - Request/Response Types

struct KeyboardParseProfileRequest: Encodable {
    let ocrText: String
}

struct KeyboardParseProfileResponse: Decodable {
    let name: String?
    let age: Int?
    let bio: String?
    let location: String?
    let occupation: String?
    let interests: [String]
    let hooks: [String]
    
    // Defensive decoder - handles nulls and field name variations
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decode(String.self, forKey: .name)
        age = try? container.decode(Int.self, forKey: .age)
        bio = try? container.decode(String.self, forKey: .bio)
        location = try? container.decode(String.self, forKey: .location)
        // Backend returns "job", we store as occupation
        occupation = (try? container.decode(String.self, forKey: .job)) ?? 
                     (try? container.decode(String.self, forKey: .occupation))
        // Handle null arrays gracefully
        interests = (try? container.decode([String].self, forKey: .interests)) ?? []
        hooks = (try? container.decode([String].self, forKey: .hooks)) ?? []
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, age, bio, location, occupation, job, interests, hooks
    }
    
    func toMatchProfile(rawOcrText: String) -> MatchProfile {
        MatchProfile(
            name: name,
            age: age,
            bio: bio,
            interests: interests,
            job: occupation,
            location: location,
            hooks: hooks,
            rawOcrText: rawOcrText
        )
    }
}

struct KeyboardGenerateMessagesRequest: Encodable {
    let userProfile: UserProfile
    let matchProfile: MatchProfile
    let conversationContext: String?
}

struct KeyboardGenerateMessagesResponse: Decodable {
    let messages: [GeneratedMessage]
    let reasoning: String?
    
    // Defensive decoder - uses try? to silently handle any decoding failures
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = (try? container.decode([GeneratedMessage].self, forKey: .messages)) ?? []
        reasoning = try? container.decode(String.self, forKey: .reasoning)
    }
    
    private enum CodingKeys: String, CodingKey {
        case messages, reasoning
    }
}

struct KeyboardRegenLineRequest: Encodable {
    let userProfile: UserProfile
    let matchProfile: MatchProfile
    let allMessages: [String]
    let lineIndex: Int
    let tone: String?
}

struct KeyboardRegenLineResponse: Decodable {
    let text: String
    let reasoning: String?
}

struct KeyboardAPIErrorResponse: Decodable {
    let message: String
}

enum KeyboardAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .serverError(let message):
            return message
        }
    }
}
