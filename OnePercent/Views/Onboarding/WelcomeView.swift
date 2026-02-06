import SwiftUI

struct WelcomeView: View {
    let step: Int
    let onContinue: () -> Void

    // Animation states - GSAP-style with blur + offset + scale
    @State private var logoVisible = false
    @State private var titleVisible = false
    @State private var featuresVisible = false
    @State private var buttonVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo/Icon with entrance animation
            VStack(spacing: 24) {
                // Use the logo image (copied from app icon)
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .opacity(logoVisible ? 1 : 0)
                    .scaleEffect(
                        x: logoVisible ? 1 : 1,
                        y: logoVisible ? 1 : 2
                    )
                    .offset(y: logoVisible ? 0 : 100)
                    .blur(radius: logoVisible ? 0 : 10)

                VStack(spacing: 8) {
                    Text("One Percent")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Brand.textPrimary)

                    Text("Your AI dating wingman")
                        .font(.title3)
                        .foregroundStyle(Brand.textSecondary)
                }
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : 30)
                .blur(radius: titleVisible ? 0 : 8)
            }

            Spacer()

            // Features with staggered entrance
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "keyboard",
                    title: "Works in Your Keyboard",
                    description: "No app switching needed",
                    index: 0,
                    visible: featuresVisible
                )

                FeatureRow(
                    icon: "video.fill",
                    title: "Screen Record Profiles",
                    description: "AI analyzes their interests",
                    index: 1,
                    visible: featuresVisible
                )

                FeatureRow(
                    icon: "sparkles",
                    title: "Perfect Openers",
                    description: "Personalized messages in seconds",
                    index: 2,
                    visible: featuresVisible
                )

                FeatureRow(
                    icon: "paperplane.fill",
                    title: "Send Instantly",
                    description: "One tap to insert",
                    index: 3,
                    visible: featuresVisible
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA Button with entrance animation
            Button(action: onContinue) {
                Text("Get Started")
            }
            .buttonStyle(.brandPrimary)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(buttonVisible ? 1 : 0)
            .offset(y: buttonVisible ? 0 : 40)
            .blur(radius: buttonVisible ? 0 : 6)
        }
        .background(Brand.background.ignoresSafeArea())
        .onAppear {
            if step == 0 {
                startEntranceAnimations()
            }
        }
        .onChange(of: step) { _, newValue in
            if newValue == 0 {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    logoVisible = false
                    titleVisible = false
                    featuresVisible = false
                    buttonVisible = false
                }
                startEntranceAnimations()
            }
        }
    }

    private func startEntranceAnimations() {
        // GSAP-style staggered entrance with spring physics
        // Separate asyncAfter calls ensure each animation runs in its own execution context
        let base: TimeInterval = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + base) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0)) {
                logoVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.09) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                titleVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.11) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0)) {
                featuresVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                buttonVisible = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var index: Int = 0
    var visible: Bool = true

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
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 30)
        .blur(radius: visible ? 0 : 4)
        .animation(
            .easeOut(duration: 0.5).delay(Double(index) * 0.1),
            value: visible
        )
    }
}

#Preview {
    WelcomeView(step: 0, onContinue: {})
}
