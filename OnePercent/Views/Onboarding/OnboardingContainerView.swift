import SwiftUI
import SharedKit

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var userProfile = UserProfile(displayName: "")
    @State private var profileContext: String?
    
    var body: some View {
        TabView(selection: $currentStep) {
            // Step 0: Welcome
            WelcomeView(onContinue: { currentStep = 1 })
                .tag(0)
            
            // Step 1: Profile Import (optional OCR of user's own dating profile)
            ProfileImportView(profileContext: $profileContext, onContinue: { currentStep = 2 })
                .tag(1)
            
            // Step 2: Profile Setup (name, vibe, nationality, activities, etc.)
            ProfileSetupView(profile: $userProfile, onComplete: saveProfileAndContinue)
                .tag(2)
            
            // Step 3: Keyboard Setup (at the end, so profile is saved before leaving app)
            KeyboardSetupView(onContinue: completeOnboarding)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
    }
    
    private func saveProfileAndContinue() {
        // Save profile before keyboard setup step (in case user leaves app for Settings)
        if let context = profileContext {
            userProfile.profileContext = context
        }
        appState.saveUserProfile(userProfile)
        currentStep = 3
    }
    
    private func completeOnboarding() {
        appState.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
