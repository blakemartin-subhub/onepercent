import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo/Icon
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Brand.gradient)
                        .frame(width: 100, height: 100)
                    
                    Text("1%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 8) {
                    Text("One Percent")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Brand.textPrimary)
                    
                    Text("Your AI dating wingman")
                        .font(.title3)
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            
            Spacer()
            
            // Features
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "keyboard",
                    title: "Works in Your Keyboard",
                    description: "No app switching needed"
                )
                
                FeatureRow(
                    icon: "video.fill",
                    title: "Screen Record Profiles",
                    description: "AI analyzes their interests"
                )
                
                FeatureRow(
                    icon: "sparkles",
                    title: "Perfect Openers",
                    description: "Personalized messages in seconds"
                )
                
                FeatureRow(
                    icon: "paperplane.fill",
                    title: "Send Instantly",
                    description: "One tap to insert"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // CTA Button
            Button(action: onContinue) {
                Text("Get Started")
            }
            .buttonStyle(.brandPrimary)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Brand.background)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Brand.accent)
                .frame(width: 44, height: 44)
                .background(Brand.accentLight)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusSmall))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
