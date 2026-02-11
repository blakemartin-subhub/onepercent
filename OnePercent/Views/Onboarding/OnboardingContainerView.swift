import SwiftUI
import SharedKit

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: Int
    @State private var navigatingForward = true
    @State private var userProfile = UserProfile(displayName: "")
    
    // Flow: Welcome → ProfileSetup → KeyboardSetup → PersonalityScore
    
    init() {
        _currentStep = State(initialValue: UserDefaults.appGroup.integer(forKey: "onboardingStep"))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Page content
            Group {
                switch currentStep {
                case 0:
                    WelcomeView(step: currentStep, onContinue: { goTo(1) })
                case 1:
                    ProfileSetupView(profile: $userProfile, step: currentStep, onComplete: saveProfileAndContinue)
                case 2:
                    KeyboardSetupView(step: currentStep, onContinue: { goTo(3) })
                case 3:
                    PersonalityScoreView(userName: userProfile.displayName.isEmpty ? "there" : userProfile.displayName, onComplete: completeOnboarding)
                default:
                    EmptyView()
                }
            }
            .id(currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: navigatingForward ? .trailing : .leading),
                removal: .opacity
            ))
            
            // Back button — visible on steps 1 and 2
            if currentStep > 0 && currentStep < 3 {
                Button(action: goBack) {
                    Image(systemName: "chevron.backward.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Brand.textPrimary, Brand.card)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
                }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .padding(.top, 8)
                .padding(.leading, 12)
                .transition(.opacity.combined(with: .offset(x: -10)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
    }
    
    private func goTo(_ step: Int) {
        navigatingForward = step > currentStep
        currentStep = step
        UserDefaults.appGroup.set(step, forKey: "onboardingStep")
    }
    
    private func goBack() {
        navigatingForward = false
        currentStep = max(0, currentStep - 1)
        UserDefaults.appGroup.set(currentStep, forKey: "onboardingStep")
    }
    
    private func saveProfileAndContinue() {
        appState.saveUserProfile(userProfile)
        goTo(2)
    }
    
    private func completeOnboarding() {
        appState.saveUserProfile(userProfile)
        UserDefaults.appGroup.removeObject(forKey: "onboardingStep")
        appState.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
