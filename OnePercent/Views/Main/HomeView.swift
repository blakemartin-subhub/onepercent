import SwiftUI
import SharedKit

/// Main home view showing saved matches and options
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var matches: [MatchProfile] = []
    @State private var showingNewMatch = false
    @State private var selectedMatch: MatchProfile?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Action buttons
                actionButtonsSection
                
                // Saved matches
                if !matches.isEmpty {
                    savedMatchesSection
                } else {
                    emptyStateSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Brand.backgroundSecondary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("One Percent")
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
            }
        }
        .onAppear(perform: loadMatches)
        .sheet(isPresented: $showingNewMatch, onDismiss: loadMatches) {
            NewMatchView()
        }
        .navigationDestination(item: $selectedMatch) { match in
            MatchProfileDetailView(
                match: match,
                userProfile: appState.userProfile,
                messages: MatchStore.shared.loadMessages(for: match.id)
            )
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                
                Text(appState.userProfile?.displayName ?? "there")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
            }
            
            Spacer()
            
            // Profile avatar
            Circle()
                .fill(Brand.accent)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(appState.userProfile?.displayName.prefix(1).uppercased() ?? "?")
                        .font(.headline)
                        .foregroundStyle(.white)
                )
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Add new profile button
            Button(action: { showingNewMatch = true }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Brand.accent)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add New Match")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Screen record their dating profile")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.textMuted)
                }
                .padding(16)
                .background(Brand.card)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusLarge))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Saved Matches
    private var savedMatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Matches")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                
                Spacer()
                
                Text("\(matches.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Brand.accentLight)
                    .foregroundStyle(Brand.accent)
                    .clipShape(Capsule())
            }
            
            ForEach(matches) { match in
                MatchCard(match: match) {
                    selectedMatch = match
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Brand.accentLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.text.square")
                    .font(.system(size: 32))
                    .foregroundStyle(Brand.accent)
            }
            
            VStack(spacing: 8) {
                Text("No matches yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                
                Text("Add a screen recording of someone's\nprofile to get started")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer().frame(height: 40)
        }
    }
    
    // MARK: - Load Data
    private func loadMatches() {
        matches = MatchStore.shared.loadAllMatches()
    }
}

// MARK: - Match Card
struct MatchCard: View {
    let match: MatchProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar (placeholder - could be photo in future)
                ZStack {
                    RoundedRectangle(cornerRadius: Brand.radiusMedium)
                        .fill(Brand.accent)
                        .frame(width: 60, height: 60)
                    
                    Text(match.name?.prefix(1).uppercased() ?? "?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(match.name ?? "Unknown")
                            .font(.headline)
                            .foregroundStyle(Brand.textPrimary)
                        
                        if let age = match.age {
                            Text("· \(age)")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    }
                    
                    // Interests preview
                    if !match.interests.isEmpty {
                        Text(match.interests.prefix(3).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                            .lineLimit(1)
                    }
                    
                    // Last interaction date
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(match.updatedAt.timeAgoDisplay())
                            .font(.caption)
                    }
                    .foregroundStyle(Brand.textMuted)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.textMuted)
            }
            .padding(16)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusLarge))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let days = components.day, days > 0 {
            if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: self)
            }
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}
