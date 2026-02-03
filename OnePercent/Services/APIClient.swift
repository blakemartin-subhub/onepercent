import Foundation
import SharedKit

/// API client for backend communication
actor APIClient {
    static let shared = APIClient()
    
    // Backend URL - Your Mac's IP address (on iPhone hotspot)
    private let baseURL = "http://172.20.10.10:3002"
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    /// Device token for authentication
    private var deviceToken: String?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public API
    
    /// Parse OCR text into structured profile
    func parseProfile(ocrText: String) async throws -> ParseProfileResponse {
        let request = ParseProfileRequest(ocrText: ocrText)
        return try await post("/v1/profile/parse", body: request)
    }
    
    /// Generate messages for a match
    func generateMessages(
        userProfile: UserProfile,
        matchProfile: MatchProfile,
        conversationContext: String? = nil
    ) async throws -> [GeneratedMessage] {
        let request = GenerateMessagesRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            conversationContext: conversationContext
        )
        
        let response: GenerateMessagesResponse = try await post("/v1/message/generate", body: request)
        return response.messages
    }
    
    // MARK: - Private Helpers
    
    private func post<T: Encodable, R: Decodable>(_ path: String, body: T) async throws -> R {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let token = await getOrCreateDeviceToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try encoder.encode(body)
        
        // Perform request with retry
        return try await performWithRetry(request: request)
    }
    
    private func performWithRetry<R: Decodable>(
        request: URLRequest,
        maxRetries: Int = 3
    ) async throws -> R {
        var lastError: Error = APIError.unknown
        
        print("[APIClient] Attempting request to: \(request.url?.absoluteString ?? "unknown")")
        
        for attempt in 0..<maxRetries {
            do {
                print("[APIClient] Attempt \(attempt + 1)/\(maxRetries)")
                let (data, response) = try await session.data(for: request)
                print("[APIClient] Request succeeded!")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return try decoder.decode(R.self, from: data)
                case 401:
                    // Clear token and retry once
                    deviceToken = nil
                    if attempt == 0 {
                        continue
                    }
                    throw APIError.unauthorized
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
                    // Try to decode error message
                    if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                        throw APIError.serverError(errorResponse.message)
                    }
                    throw APIError.httpError(httpResponse.statusCode)
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as APIError {
                print("[APIClient] APIError on attempt \(attempt + 1): \(error.localizedDescription)")
                lastError = error
            } catch {
                print("[APIClient] Network error on attempt \(attempt + 1): \(error)")
                print("[APIClient] Error details: \((error as NSError).domain) code: \((error as NSError).code)")
                lastError = error
                // Network error - retry with backoff
                let waitTime = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        
        print("[APIClient] All retries failed. Final error: \(lastError)")
        throw lastError
    }
    
    private func getOrCreateDeviceToken() async -> String? {
        if let token = deviceToken {
            return token
        }
        
        // Generate a device token
        // In production, this should be stored in Keychain
        let token = UUID().uuidString
        deviceToken = token
        return token
    }
}

// MARK: - Request/Response Types

struct ParseProfileRequest: Encodable {
    let ocrText: String
}

struct GenerateMessagesRequest: Encodable {
    let userProfile: UserProfile
    let matchProfile: MatchProfile
    let conversationContext: String?
}

struct APIErrorResponse: Decodable {
    let message: String
    let code: String?
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please try again."
        case .httpError(let code):
            return "Server returned error code \(code)"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Offline Support

extension APIClient {
    /// Check if the device has network connectivity
    var isOnline: Bool {
        // Simple check - in production use NWPathMonitor
        return true
    }
}
