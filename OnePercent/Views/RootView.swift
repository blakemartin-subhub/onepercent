import SwiftUI
import SharedKit

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        // MVP: Share extension flow commented out — keyboard handles everything
        // .onReceive(NotificationCenter.default.publisher(for: .didReceiveShareExtensionImages)) { _ in ... }
    }
}

// MARK: - All Set View (post-onboarding landing)

struct AllSetView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var iconVisible = false
    @State private var textVisible = false
    @State private var stepsVisible = false
    @State private var settingsVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Brand.accentLight)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Brand.accent)
                }
                .opacity(iconVisible ? 1 : 0)
                .scaleEffect(iconVisible ? 1 : 0.8)
                
                VStack(spacing: 8) {
                    Text("You're All Set!")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                    
                    Text("Open your keyboard in any messaging app\nto start generating messages")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(textVisible ? 1 : 0)
                .offset(y: textVisible ? 0 : 20)
            }
            
            Spacer()
            
            // Quick how-to
            VStack(spacing: 12) {
                HowToRow(number: 1, text: "Open any messaging app")
                HowToRow(number: 2, text: "Tap the globe icon to switch keyboards")
                HowToRow(number: 3, text: "Import a profile or conversation")
                HowToRow(number: 4, text: "Get messages and tap to send")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Brand.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusLarge))
            .padding(.horizontal, 20)
            .opacity(stepsVisible ? 1 : 0)
            .offset(y: stepsVisible ? 0 : 30)
            
            Spacer()
            
            // Settings link
            NavigationLink {
                SettingsView()
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Brand.accent)
                    Text("Settings")
                        .foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.textMuted)
                }
                .padding(16)
                .background(Brand.card)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(settingsVisible ? 1 : 0)
            .offset(y: settingsVisible ? 0 : 20)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { startAnimations() }
    }
    
    private func startAnimations() {
        let base: TimeInterval = 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + base) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                iconVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                textVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.25) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                stepsVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                settingsVisible = true
            }
        }
    }
}

struct HowToRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Brand.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Matches", systemImage: "heart.fill")
            }
            .tag(0)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(1)
        }
        .tint(Brand.accent)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
