import Foundation
import SharedKit

/// API client for backend communication
actor APIClient {
    static let shared = APIClient()
    
    // Backend URL - read from shared App Group config so keyboard uses the same URL
    private var baseURL: String { BackendConfig.shared.baseURL }
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    /// Device token for authentication
    private var deviceToken: String?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60 // Increased from 30 for GPT-4
        config.timeoutIntervalForResource = 120 // Increased from 60
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public API
    
    /// Check if server is reachable
    func healthCheck() async throws -> Bool {
        let url = URL(string: baseURL + "/health")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("[APIClient] Health check failed: \(error)")
            return false
        }
    }
    
    /// Get backend info including model version
    func getBackendInfo() async throws -> BackendInfo {
        let url = URL(string: baseURL + "/info")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode(BackendInfo.self, from: data)
    }
    
    /// Debug: Get raw response from parse endpoint
    func debugParseProfile(ocrText: String) async throws -> String {
        let url = URL(string: baseURL + "/v1/profile/parse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = await getOrCreateDeviceToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = ParseProfileRequest(ocrText: ocrText)
        let bodyData = try encoder.encode(requestBody)
        request.httpBody = bodyData
        
        print("[APIClient] 🔍 Debug request to: \(url.absoluteString)")
        print("[APIClient] 🔍 Request body: \(String(data: bodyData, encoding: .utf8) ?? "none")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return "❌ Not an HTTP response"
            }
            
            let statusCode = httpResponse.statusCode
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response data"
            
            var result = "📊 Status Code: \(statusCode)\n\n"
            result += "📝 Headers:\n"
            for (key, value) in httpResponse.allHeaderFields {
                result += "  \(key): \(value)\n"
            }
            result += "\n📦 Response Body:\n"
            result += responseString
            
            return result
        } catch {
            return "❌ Request failed:\n\(error.localizedDescription)\n\nError: \(error)"
        }
    }
    
    /// Parse OCR text into structured profile
    func parseProfile(ocrText: String) async throws -> ParseProfileResponse {
        let request = ParseProfileRequest(ocrText: ocrText)
        return try await post("/v1/profile/parse", body: request)
    }
    
    /// Generate messages for a match
    func generateMessages(
        userProfile: UserProfile,
        matchProfile: MatchProfile,
        conversationContext: String? = nil,
        lineMode: String? = nil
    ) async throws -> [GeneratedMessage] {
        let request = GenerateMessagesRequest(
            userProfile: userProfile,
            matchProfile: matchProfile,
            conversationContext: conversationContext,
            lineMode: lineMode
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
        
        let encodedBody = try encoder.encode(body)
        request.httpBody = encodedBody
        
        // Log request details
        print("[APIClient] 📤 POST \(path)")
        if let bodyString = String(data: encodedBody, encoding: .utf8) {
            print("[APIClient] Request body: \(bodyString.prefix(500))...")
        }
        
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
                
                print("[APIClient] ✅ Got response with status: \(httpResponse.statusCode)")
                print("[APIClient] Response headers: \(httpResponse.allHeaderFields)")
                
                switch httpResponse.statusCode {
                case 200...299:
                    // Log the raw response
                    let responseString = String(data: data, encoding: .utf8)
                    if let responseString = responseString {
                        print("[APIClient] 📥 Response body: \(responseString)")
                    }
                    
                    do {
                        let decoded = try decoder.decode(R.self, from: data)
                        print("[APIClient] ✅ Successfully decoded response")
                        return decoded
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("[APIClient] ❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
                        print("[APIClient] Coding path: \(context.codingPath)")
                        throw APIError.decodingError(DecodingError.keyNotFound(key, context), responseBody: responseString)
                    } catch let DecodingError.typeMismatch(type, context) {
                        print("[APIClient] ❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
                        print("[APIClient] Coding path: \(context.codingPath)")
                        throw APIError.decodingError(DecodingError.typeMismatch(type, context), responseBody: responseString)
                    } catch let DecodingError.valueNotFound(type, context) {
                        print("[APIClient] ❌ Value not found for type '\(type)' - \(context.debugDescription)")
                        print("[APIClient] Coding path: \(context.codingPath)")
                        throw APIError.decodingError(DecodingError.valueNotFound(type, context), responseBody: responseString)
                    } catch let DecodingError.dataCorrupted(context) {
                        print("[APIClient] ❌ Data corrupted - \(context.debugDescription)")
                        print("[APIClient] Coding path: \(context.codingPath)")
                        throw APIError.decodingError(DecodingError.dataCorrupted(context), responseBody: responseString)
                    } catch {
                        print("[APIClient] ❌ Unknown decoding error: \(error)")
                        throw APIError.decodingError(error, responseBody: responseString)
                    }
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
    let lineMode: String? // "one" | "twoThree" | "threePlus"
}

struct APIErrorResponse: Decodable {
    let message: String
    let code: String?
}

struct BackendInfo: Decodable {
    let version: String?
    let model: String?
    let environment: String?
    
    enum CodingKeys: String, CodingKey {
        case version
        case model
        case environment
    }
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error, responseBody: String?)
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
        case .decodingError(let error, let responseBody):
            var message = "Failed to parse response: \(error.localizedDescription)"
            if let body = responseBody {
                message += "\n\nServer response: \(body.prefix(200))"
            }
            return message
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
