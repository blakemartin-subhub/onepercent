import SwiftUI

struct KeyboardSetupView: View {
    let onContinue: () -> Void
    @State private var currentStep = 0
    
    private let steps = [
        SetupStep(
            number: 1,
            title: "Open Settings",
            description: "Go to Settings → General → Keyboard → Keyboards",
            icon: "gear"
        ),
        SetupStep(
            number: 2,
            title: "Add New Keyboard",
            description: "Tap 'Add New Keyboard...' and select 'OnePercent'",
            icon: "plus.circle"
        ),
        SetupStep(
            number: 3,
            title: "Allow Full Access",
            description: "Tap OnePercent, then enable 'Allow Full Access' for AI regeneration",
            icon: "lock.open"
        ),
        SetupStep(
            number: 4,
            title: "You're Ready!",
            description: "Switch keyboards using the globe icon while typing",
            icon: "globe"
        )
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 60))
                    .foregroundStyle(.pink)
                
                Text("Enable Keyboard")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Follow these steps to enable the OnePercent keyboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Steps
            VStack(spacing: 16) {
                ForEach(steps.indices, id: \.self) { index in
                    SetupStepRow(
                        step: steps[index],
                        isActive: index == currentStep,
                        isCompleted: index < currentStep
                    )
                    .onTapGesture {
                        withAnimation {
                            currentStep = index
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Privacy note
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                    Text("Your Privacy is Protected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text("We never log your keystrokes or access your messages.\nFull Access is only used for AI message regeneration.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: openSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button(action: onContinue) {
                    Text("Continue")
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isActive ? .primary : .secondary)
                
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
