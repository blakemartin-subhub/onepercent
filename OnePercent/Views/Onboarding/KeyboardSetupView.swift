import SwiftUI

struct KeyboardSetupView: View {
    let onContinue: () -> Void
    @State private var currentStep = 0
    @State private var animatingStep = 0  // For the fill animation
    @State private var hasCheckedKeyboard = false
    @State private var showingFullAccessWarning = false
    @State private var isAnimatingSequence = false
    
    private let steps = [
        SetupStep(
            number: 1,
            title: "Open Keyboard Settings",
            description: "Settings → General → Keyboard → Keyboards",
            icon: "gear"
        ),
        SetupStep(
            number: 2,
            title: "Add OnePercent Keyboard",
            description: "Tap 'Add New Keyboard...' → select 'OnePercent'",
            icon: "plus.circle"
        ),
        SetupStep(
            number: 3,
            title: "Allow Full Access",
            description: "Tap 'OnePercent' → toggle ON 'Allow Full Access'",
            icon: "lock.open"
        ),
        SetupStep(
            number: 4,
            title: "You're Ready!",
            description: "While typing, tap 🌐 to switch to OnePercent",
            icon: "checkmark.circle"
        )
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 60))
                    .foregroundStyle(.pink)
                
                Text("Enable Keyboard")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("The keyboard is where all the magic happens")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Steps
            VStack(spacing: 12) {
                ForEach(steps.indices, id: \.self) { index in
                    SetupStepRow(
                        step: steps[index],
                        isActive: index == currentStep || index == animatingStep,
                        isCompleted: index < animatingStep,
                        isRequired: index == 2 && index >= animatingStep // Full Access step
                    )
                    .onTapGesture {
                        if !isAnimatingSequence {
                            withAnimation {
                                currentStep = index
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Why Full Access is Required
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Full Access is Required")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    RequirementRow(icon: "photo", text: "Access your photo library to import recordings")
                    RequirementRow(icon: "network", text: "Connect to AI for message generation")
                    RequirementRow(icon: "cpu", text: "Process videos directly in the keyboard")
                }
                .padding(.horizontal, 8)
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    Text("We never log keystrokes or read your messages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: openKeyboardSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // Quick path hint
                Text("Then: General → Keyboard → Keyboards → Add New Keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: verifyAndContinue) {
                    HStack {
                        Text("I've Enabled Full Access")
                        Image(systemName: "checkmark.circle")
                    }
                    .font(.headline)
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .alert("Full Access Required", isPresented: $showingFullAccessWarning) {
            Button("Open Settings") {
                openKeyboardSettings()
            }
            Button("Continue Anyway", role: .destructive) {
                onContinue()
            }
        } message: {
            Text("Without Full Access enabled, the keyboard won't be able to access your photos or generate messages. Are you sure you want to continue?")
        }
    }
    
    private func openKeyboardSettings() {
        // Animate the step sequence before opening settings
        isAnimatingSequence = true
        
        // Step 1 is already highlighted, animate step 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animatingStep = 2
            }
        }
        
        // Animate step 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animatingStep = 3
            }
        }
        
        // After animation sequence (0.75s), open settings and schedule step 4 fill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            // Open settings
            actuallyOpenSettings()
            
            // Fill step 4 after 2 seconds (simulating user completing the steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatingStep = 4
                }
                isAnimatingSequence = false
            }
        }
    }
    
    private func actuallyOpenSettings() {
        // Try different URL schemes for keyboard settings (iOS version dependent)
        let keyboardURLs = [
            "prefs:root=General&path=Keyboard/KEYBOARDS",  // iOS 15+
            "App-prefs:root=General&path=Keyboard/KEYBOARDS",  // Older iOS
            "App-prefs:General&path=Keyboard/KEYBOARDS"
        ]
        
        for urlString in keyboardURLs {
            if let url = URL(string: urlString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback: Open the app's own settings page
        // This shows our keyboard extension if it's installed
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func verifyAndContinue() {
        // Check if keyboard likely has full access
        // Note: There's no direct API to check this, so we show a warning
        if !hasCheckedKeyboard {
            hasCheckedKeyboard = true
            showingFullAccessWarning = true
        } else {
            onContinue()
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.pink)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

struct SetupStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
    let icon: String
}

struct SetupStepRow: View {
    let step: SetupStep
    let isActive: Bool
    let isCompleted: Bool
    var isRequired: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number/checkmark
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isActive ? Color.pink : Color(.systemGray4)))
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(step.number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isActive ? .white : .secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isActive ? .primary : .secondary)
                    
                    if isRequired && !isCompleted {
                        Text("REQUIRED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
                
                Text(step.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: step.icon)
                .foregroundStyle(isActive ? .pink : .secondary)
        }
        .padding()
        .background(isActive ? Color.pink.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    KeyboardSetupView(onContinue: {})
}
