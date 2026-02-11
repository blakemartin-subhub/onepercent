import Foundation
import SharedKit

/// API client for keyboard extension
actor KeyboardAPIClient {
    static let shared = KeyboardAPIClient()
    
    // Backend URL - read from shared App Group config (set in main app Settings)
    private var baseURL: String { BackendConfig.shared.baseURL }
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
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
    
    /// Generate messages for a match (opener)
    func generateMessages(
        userProfile: UserProfile,
        matchProfile: MatchProfile,
        direction: String? = nil,
        lineMode: String? = nil
    ) async throws -> (messages: [GeneratedMessage], reasoning: String?, matchedPrompt: String?) {
        let request = KeyboardGenerateMessagesRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            conversationContext: nil,
            direction: direction,
            lineMode: lineMode
        )
        
        let response: KeyboardGenerateMessagesResponse = try await post("/v1/message/generate", body: request)
        return (response.messages, response.reasoning, response.matchedPrompt)
    }
    
    /// Generate follow-up messages based on conversation context
    func generateConversationMessages(
        userProfile: UserProfile,
        matchProfile: MatchProfile,
        conversationContext: String,
        direction: String? = nil,
        lineMode: String? = nil
    ) async throws -> (messages: [GeneratedMessage], reasoning: String?, matchedPrompt: String?) {
        let request = KeyboardGenerateMessagesRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            conversationContext: conversationContext,
            direction: direction,
            lineMode: lineMode
        )
        
        let response: KeyboardGenerateMessagesResponse = try await post("/v1/message/generate", body: request)
        return (response.messages, response.reasoning, response.matchedPrompt)
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
        
        let deviceToken = getDeviceToken()
        request.setValue("Bearer \(deviceToken)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try encoder.encode(body)
        
        // Retry with exponential backoff (matches main app behavior)
        return try await performWithRetry(request: request)
    }
    
    private func performWithRetry<R: Decodable>(
        request: URLRequest,
        maxRetries: Int = 3
    ) async throws -> R {
        var lastError: Error = KeyboardAPIError.invalidResponse
        
        print("[KeyboardAPI] Requesting: \(request.url?.absoluteString ?? "unknown")")
        
        for attempt in 0..<maxRetries {
            do {
                print("[KeyboardAPI] Attempt \(attempt + 1)/\(maxRetries)")
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw KeyboardAPIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return try decoder.decode(R.self, from: data)
                case 429:
                    // Rate limited - wait and retry
                    let waitTime = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    continue
                case 500...599:
                    // Server error - retry with backoff
                    let waitTime = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    continue
                default:
                    if let errorResponse = try? decoder.decode(KeyboardAPIErrorResponse.self, from: data) {
                        throw KeyboardAPIError.serverError(errorResponse.message)
                    }
                    throw KeyboardAPIError.httpError(httpResponse.statusCode)
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as KeyboardAPIError {
                lastError = error
            } catch {
                print("[KeyboardAPI] Network error on attempt \(attempt + 1): \(error)")
                lastError = error
                // Network error - retry with backoff
                if attempt < maxRetries - 1 {
                    let waitTime = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                }
            }
        }
        
        print("[KeyboardAPI] All retries failed. URL: \(request.url?.absoluteString ?? "unknown"), Error: \(lastError)")
        throw lastError
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
    let contentType: String? // "profile" or "conversation" — auto-detected by backend
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decode(String.self, forKey: .name)
        age = try? container.decode(Int.self, forKey: .age)
        bio = try? container.decode(String.self, forKey: .bio)
        location = try? container.decode(String.self, forKey: .location)
        occupation = (try? container.decode(String.self, forKey: .job)) ??
                     (try? container.decode(String.self, forKey: .occupation))
        interests = (try? container.decode([String].self, forKey: .interests)) ?? []
        hooks = (try? container.decode([String].self, forKey: .hooks)) ?? []
        contentType = try? container.decode(String.self, forKey: .contentType)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, age, bio, location, occupation, job, interests, hooks, contentType
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
    let direction: String? // MVP: user's direction (e.g. "Funny. get her to grab coffee with me")
    let lineMode: String? // "one" | "twoThree" | "threePlus"
}

struct KeyboardGenerateMessagesResponse: Decodable {
    let messages: [GeneratedMessage]
    let reasoning: String?
    let matchedPrompt: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = (try? container.decode([GeneratedMessage].self, forKey: .messages)) ?? []
        reasoning = try? container.decode(String.self, forKey: .reasoning)
        matchedPrompt = try? container.decode(String.self, forKey: .matchedPrompt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case messages, reasoning, matchedPrompt
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
