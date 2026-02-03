import SwiftUI
import SharedKit

/// Main home view showing saved matches and options
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var matches: [MatchProfile] = []
    @State private var showingNewMatch = false
    @State private var selectedMatch: MatchProfile?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Action buttons
                    actionButtonsSection
                    
                    // Saved matches
                    if !matches.isEmpty {
                        savedMatchesSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("OnePercent")
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
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Add new profile button
            Button(action: { showingNewMatch = true }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "record.circle")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add New Profile")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Drop a screen recording of their profile")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Update existing profile
            if !matches.isEmpty {
                Button(action: { /* TODO: Update flow */ }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Update Previous Profiles")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Add more context or regenerate messages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    // MARK: - Saved Matches
    private var savedMatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Matches")
                    .font(.title2.weight(.bold))
                
                Spacer()
                
                Text("\(matches.count)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.1))
                    .foregroundStyle(.pink)
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
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No matches yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text("Add a screen recording of someone's\nprofile to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: 40)
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
    
    // Random compatibility score
    private var compatibilityScore: Int {
        let seed = match.id.hashValue
        srand48(seed)
        return Int(drand48() * 42) + 32
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(match.name?.prefix(1).uppercased() ?? "?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(match.name ?? "Unknown")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let age = match.age {
                            Text("• \(age)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Interests preview
                    if !match.interests.isEmpty {
                        Text(match.interests.prefix(3).joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Compatibility badge
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("\(compatibilityScore)% match")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.pink)
                }
                
                Spacer()
                
                // Messages indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundStyle(.green)
                    
                    Text("Ready")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
