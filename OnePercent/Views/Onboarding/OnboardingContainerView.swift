import SwiftUI
import SharedKit

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var userProfile = UserProfile(displayName: "")
    @State private var profileContext: String?
    
    var body: some View {
        TabView(selection: $currentStep) {
            WelcomeView(onContinue: { currentStep = 1 })
                .tag(0)
            
            KeyboardSetupView(onContinue: { currentStep = 2 })
                .tag(1)
            
            ProfileImportView(profileContext: $profileContext, onContinue: { currentStep = 3 })
                .tag(2)
            
            ProfileSetupView(profile: $userProfile, onComplete: completeOnboarding)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
    }
    
    private func completeOnboarding() {
        // Add profile context if imported
        if let context = profileContext {
            userProfile.profileContext = context
        }
        appState.saveUserProfile(userProfile)
        appState.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
