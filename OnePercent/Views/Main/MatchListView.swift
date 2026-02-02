import SwiftUI
import SharedKit

struct MatchListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showNewMatch = false
    @State private var searchText = ""
    
    var filteredMatches: [MatchProfile] {
        if searchText.isEmpty {
            return appState.matches
        }
        return appState.matches.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            if appState.matches.isEmpty {
                EmptyMatchesView(onAddMatch: { showNewMatch = true })
            } else {
                List {
                    ForEach(filteredMatches) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            MatchRow(match: match)
                        }
                    }
                    .onDelete(perform: deleteMatches)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search matches")
            }
        }
        .navigationTitle("Matches")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewMatch = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewMatch) {
            NavigationStack {
                NewMatchView()
            }
        }
    }
    
    private func deleteMatches(at offsets: IndexSet) {
        for index in offsets {
            let match = filteredMatches[index]
            appState.deleteMatch(match)
        }
    }
}

struct MatchRow: View {
    let match: MatchProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(match.displayName.prefix(1).uppercased())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.pink)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(match.displayName)
                    .font(.headline)
                
                if !match.summary.isEmpty {
                    Text(match.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Text(match.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptyMatchesView: View {
    let onAddMatch: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Matches Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Import a dating profile to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onAddMatch) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Match")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        MatchListView()
            .environmentObject(AppState())
    }
}
