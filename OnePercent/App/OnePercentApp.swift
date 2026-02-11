import SwiftUI
import SharedKit
import Network

@main
struct OnePercentApp: App {
    @StateObject private var appState: AppState
    
    init() {
        #if DEBUG
        // DEBUG: Set to true to clear all data on app launch for testing
        let shouldResetOnLaunch = false
        
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
    
    /// Triggers the local network permission dialog using NWBrowser (Bonjour discovery).
    /// URLSession alone does not reliably prompt the user. NWBrowser immediately triggers
    /// the system "Allow Local Network Access" alert on first launch.
    private func triggerLocalNetworkPermission() {
        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
        browser.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[OnePercent] Local network permission granted")
                browser.cancel()
            case .failed(let error):
                print("[OnePercent] NWBrowser failed: \(error)")
                browser.cancel()
            case .cancelled:
                break
            default:
                break
            }
        }
        browser.start(queue: .main)
        
        // Cancel after a few seconds regardless — we only need the prompt to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            browser.cancel()
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
        UserDefaults.appGroup.removeObject(forKey: "onboardingStep")
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
