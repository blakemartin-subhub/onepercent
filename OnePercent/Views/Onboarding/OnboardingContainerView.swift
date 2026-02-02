import SwiftUI
import SharedKit

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var userProfile = UserProfile(displayName: "")
    
    var body: some View {
        TabView(selection: $currentStep) {
            WelcomeView(onContinue: { currentStep = 1 })
                .tag(0)
            
            KeyboardSetupView(onContinue: { currentStep = 2 })
                .tag(1)
            
            ProfileSetupView(profile: $userProfile, onComplete: completeOnboarding)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
    }
    
    private func completeOnboarding() {
        appState.saveUserProfile(userProfile)
        appState.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
