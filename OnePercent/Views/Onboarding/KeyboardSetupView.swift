import SwiftUI

struct KeyboardSetupView: View {
    let onContinue: () -> Void
    @State private var currentStep = 0
    @State private var animatingStep = 0
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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Brand.accentLight)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "keyboard")
                        .font(.system(size: 32))
                        .foregroundStyle(Brand.accent)
                }
                
                Text("Enable Keyboard")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                
                Text("The keyboard is where all the magic happens")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Steps
            VStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { index in
                    SetupStepRow(
                        step: steps[index],
                        isActive: index == currentStep || index == animatingStep,
                        isCompleted: index < animatingStep,
                        isRequired: index == 2 && index >= animatingStep
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
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Why Full Access
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(Brand.accent)
                    Text("Why Full Access?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    RequirementRow(icon: "photo", text: "Access your photo library")
                    RequirementRow(icon: "network", text: "Connect to AI for messages")
                    RequirementRow(icon: "cpu", text: "Process videos in keyboard")
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Brand.success)
                    Text("We never log keystrokes or read your messages")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Brand.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: openKeyboardSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                }
                .buttonStyle(.brandPrimary)
                
                Text("General → Keyboard → Keyboards → Add New Keyboard")
                    .font(.caption)
                    .foregroundStyle(Brand.textMuted)
                
                Button(action: verifyAndContinue) {
                    HStack {
                        Text("I've Enabled Full Access")
                        Image(systemName: "checkmark.circle")
                    }
                }
                .buttonStyle(.brandSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Brand.background)
        .alert("Full Access Required", isPresented: $showingFullAccessWarning) {
            Button("Open Settings") {
                openKeyboardSettings()
            }
            Button("Continue Anyway", role: .destructive) {
                onContinue()
            }
        } message: {
            Text("Without Full Access enabled, the keyboard won't be able to access your photos or generate messages.")
        }
    }
    
    private func openKeyboardSettings() {
        isAnimatingSequence = true
        
        // Animate step 2
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
        
        // Open settings and fill step 4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            actuallyOpenSettings()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatingStep = 4
                }
                isAnimatingSequence = false
            }
        }
    }
    
    private func actuallyOpenSettings() {
        let keyboardURLs = [
            "prefs:root=General&path=Keyboard/KEYBOARDS",
            "App-prefs:root=General&path=Keyboard/KEYBOARDS",
            "App-prefs:General&path=Keyboard/KEYBOARDS"
        ]
        
        for urlString in keyboardURLs {
            if let url = URL(string: urlString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func verifyAndContinue() {
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
                .foregroundStyle(Brand.accent)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(Brand.textPrimary)
            
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
        HStack(spacing: 14) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? Brand.success : (isActive ? Brand.accent : Brand.border))
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(step.number)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isActive ? .white : Brand.textMuted)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isActive || isCompleted ? Brand.textPrimary : Brand.textSecondary)
                    
                    if isRequired && !isCompleted {
                        Text("REQUIRED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Brand.warning)
                            .clipShape(Capsule())
                    }
                }
                
                Text(step.description)
                    .font(.caption)
                    .foregroundStyle(Brand.textMuted)
            }
            
            Spacer()
            
            Image(systemName: step.icon)
                .font(.subheadline)
                .foregroundStyle(isActive || isCompleted ? Brand.accent : Brand.textMuted)
        }
        .padding(12)
        .background(isActive ? Brand.accentLight.opacity(0.5) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
    }
}

#Preview {
    KeyboardSetupView(onContinue: {})
}
