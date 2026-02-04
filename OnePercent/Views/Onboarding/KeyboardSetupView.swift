import SwiftUI

struct KeyboardSetupView: View {
    let onContinue: () -> Void
    
    private let steps = [
        SetupStep(
            number: 1,
            title: "Open Keyboard Settings",
            description: "Settings → General → Keyboard → Keyboards",
            icon: "gear"
        ),
        SetupStep(
            number: 2,
            title: "Add One Percent Keyboard",
            description: "Tap 'Add New Keyboard...' → select 'One Percent'",
            icon: "plus.circle"
        ),
        SetupStep(
            number: 3,
            title: "Allow Full Access",
            description: "Tap 'One Percent' → toggle ON 'Allow Full Access'",
            icon: "lock.open"
        ),
        SetupStep(
            number: 4,
            title: "You're Ready!",
            description: "While typing, tap 🌐 to switch to One Percent",
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
                
                Text("Enable the keyboard to generate messages\nwhile chatting in any app")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Steps (informational - shows all steps to follow)
            VStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { index in
                    SetupStepRow(
                        step: steps[index],
                        isActive: true,
                        isCompleted: false,
                        isRequired: index == 2 // Full Access step is required
                    )
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
            
            // Single button - opens settings AND advances to next page
            VStack(spacing: 12) {
                Button(action: openSettingsAndContinue) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                }
                .buttonStyle(.brandPrimary)
                
                Text("Settings → General → Keyboard → Keyboards")
                    .font(.caption)
                    .foregroundStyle(Brand.textMuted)
                
                Text("Add 'One Percent' and enable Full Access")
                    .font(.caption)
                    .foregroundStyle(Brand.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Brand.background)
    }
    
    private func openSettingsAndContinue() {
        // First, advance to the next onboarding step
        onContinue()
        
        // Then open Settings (app's settings page)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
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
