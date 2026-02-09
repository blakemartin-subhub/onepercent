import SwiftUI
import SharedKit

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var navigatingForward = true
    @State private var userProfile = UserProfile(displayName: "")
    
    // MVP: 3-step onboarding (Welcome → Quick Setup → Keyboard Setup)
    // Previous flow had ProfileImportView at step 1 and ProfileSetupView at step 2
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Page content
            Group {
                switch currentStep {
                case 0:
                    WelcomeView(step: currentStep, onContinue: { goTo(1) })
                case 1:
                    QuickSetupView(profile: $userProfile, step: currentStep, onComplete: saveProfileAndContinue)
                case 2:
                    KeyboardSetupView(step: currentStep, onContinue: completeOnboarding)
                default:
                    EmptyView()
                }
            }
            .id(currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: navigatingForward ? .trailing : .leading),
                removal: .opacity
            ))
            
            // Back button — visible on step 1+
            if currentStep > 0 {
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
    }
    
    private func goBack() {
        navigatingForward = false
        currentStep = max(0, currentStep - 1)
    }
    
    private func saveProfileAndContinue() {
        appState.saveUserProfile(userProfile)
        goTo(2)
    }
    
    private func completeOnboarding() {
        appState.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
