import SwiftUI
import SharedKit

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImportFlow = false
    
    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveShareExtensionImages)) { _ in
            // Triggered when share extension sends images
            showImportFlow = true
        }
        .sheet(isPresented: $showImportFlow) {
            NavigationStack {
                NewMatchView(fromShareExtension: true)
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationStack {
                MatchListView()
            }
            .tabItem {
                Label("Matches", systemImage: "heart.fill")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(.pink)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
