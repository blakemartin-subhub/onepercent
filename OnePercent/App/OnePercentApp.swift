import SwiftUI
import SharedKit

@main
struct OnePercentApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

/// Global app state
@MainActor
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var userProfile: UserProfile?
    @Published var matches: [MatchProfile] = []
    @Published var isLoading: Bool = false
    
    private let storage = MatchStore.shared
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.appGroup.bool(forKey: "hasCompletedOnboarding")
        self.userProfile = storage.loadUserProfile()
        self.matches = storage.loadAllMatches()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.appGroup.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
        storage.saveUserProfile(profile)
    }
    
    func addMatch(_ match: MatchProfile) {
        matches.insert(match, at: 0)
        storage.saveMatch(match)
    }
    
    func deleteMatch(_ match: MatchProfile) {
        matches.removeAll { $0.matchId == match.matchId }
        storage.deleteMatch(match.matchId)
    }
    
    func refreshMatches() {
        matches = storage.loadAllMatches()
    }
}
