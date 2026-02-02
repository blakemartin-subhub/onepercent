// SharedKit - Shared code between main app, keyboard, and share extension

// Re-export all public types
@_exported import Foundation

// Models
public typealias Models = (UserProfile, MatchProfile, GeneratedMessage, GeneratedMessageSet)

// Storage
public typealias Storage = (AppGroupStorage, SecureStore, MatchStore)
