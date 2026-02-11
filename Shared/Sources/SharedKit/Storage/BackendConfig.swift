import Foundation

/// Shared backend configuration stored in App Group UserDefaults.
/// Both the main app and keyboard extension read from this.
public final class BackendConfig: @unchecked Sendable {
    public static let shared = BackendConfig()
    
    private static let urlKey = "backendBaseURL"
    
    /// Default URL for local development.
    /// Change this to your Mac's current IP when testing on a real device.
    /// Use "http://localhost:3002" when testing on the simulator.
    #if targetEnvironment(simulator)
    public static let defaultURL = "http://localhost:3002"
    #else
    public static let defaultURL = "http://192.168.1.74:3002"
    #endif
    
    private let defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)
    }
    
    /// The backend base URL (e.g. "http://192.168.1.5:3002").
    /// Reads from App Group UserDefaults so both the main app and keyboard share it.
    public var baseURL: String {
        get {
            defaults?.string(forKey: Self.urlKey) ?? Self.defaultURL
        }
        set {
            defaults?.set(newValue, forKey: Self.urlKey)
            defaults?.synchronize()
        }
    }
    
    /// Convenience: update the IP while keeping the port.
    public func setIP(_ ip: String, port: Int = 3002) {
        baseURL = "http://\(ip):\(port)"
    }
    
    /// Reset to default URL
    public func reset() {
        defaults?.removeObject(forKey: Self.urlKey)
    }
}
