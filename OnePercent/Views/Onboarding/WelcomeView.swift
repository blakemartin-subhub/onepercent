import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to OnePercent")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your AI dating assistant\nlives in your keyboard")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // How it works - keyboard centric
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "keyboard",
                    title: "Works Right in Your Keyboard",
                    description: "No app switching - everything happens while you chat"
                )
                
                FeatureRow(
                    icon: "record.circle",
                    title: "Drop a Screen Recording",
                    description: "Record their profile, upload from the keyboard"
                )
                
                FeatureRow(
                    icon: "sparkles",
                    title: "Get Perfect Openers Instantly",
                    description: "AI crafts personalized messages in seconds"
                )
                
                FeatureRow(
                    icon: "paperplane.fill",
                    title: "Send with One Tap",
                    description: "Insert messages directly into any dating app"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Get Started")
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
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.pink)
                .frame(width: 44, height: 44)
                .background(Color.pink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
