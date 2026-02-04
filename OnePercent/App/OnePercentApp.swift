import SwiftUI
import SharedKit

@main
struct OnePercentApp: App {
    @StateObject private var appState: AppState
    
    init() {
        // DEBUG: Set to true to clear all data on app launch for testing
        let shouldResetOnLaunch = false
        
        #if DEBUG
        if shouldResetOnLaunch {
            print("[OnePercent] DEBUG: Clearing all data on launch...")
            MatchStore.shared.deleteAllData()
            
            // Also clear the App Group UserDefaults
            if let defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier) {
                defaults.removePersistentDomain(forName: AppGroupConstants.groupIdentifier)
                defaults.synchronize()
            }
            print("[OnePercent] DEBUG: All data cleared!")
        }
        #endif
        
        _appState = StateObject(wrappedValue: AppState())
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleURL(url)
                }
                .onAppear {
                    // Trigger local network permission prompt early
                    triggerLocalNetworkPermission()
                    
                    // Check if share inbox has content when app launches
                    // (in case URL didn't trigger but content was shared)
                    checkShareInbox()
                }
        }
    }
    
    /// Triggers the local network permission dialog by making a lightweight request
    /// This ensures users see the prompt early instead of when they first use the keyboard
    private func triggerLocalNetworkPermission() {
        Task {
            // Make a simple request to trigger the local network permission prompt
            // This will show the "Allow local network access" dialog
            let url = URL(string: "http://172.20.10.10:3002/health")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2 // Short timeout - we just need to trigger the prompt
            
            do {
                let _ = try await URLSession.shared.data(for: request)
                print("[OnePercent] Local network check succeeded")
            } catch {
                // It's okay if this fails - the permission dialog will still show
                print("[OnePercent] Local network check: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        print("[OnePercent] Received URL: \(url)")
        guard url.scheme == "onepercent" else { return }
        
        if url.host == "import" {
            print("[OnePercent] Posting share extension notification")
            NotificationCenter.default.post(
                name: .didReceiveShareExtensionImages,
                object: nil
            )
        }
    }
    
    private func checkShareInbox() {
        // Check if there's content waiting from share extension
        let hasVideo = MatchStore.shared.shareInboxHasVideo()
        let hasImages = !MatchStore.shared.getShareInboxImageURLs().isEmpty
        
        if hasVideo || hasImages {
            print("[OnePercent] Found content in share inbox on launch (video: \(hasVideo), images: \(hasImages))")
            // Small delay to ensure RootView is ready to receive notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: .didReceiveShareExtensionImages,
                    object: nil
                )
            }
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
