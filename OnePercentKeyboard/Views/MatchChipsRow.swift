import SwiftUI
import SharedKit

struct MatchChipsRow: View {
    let matches: [MatchProfile]
    @Binding var selectedMatchId: UUID?
    let onSelect: (UUID) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(matches) { match in
                    MatchChip(
                        match: match,
                        isSelected: match.matchId == selectedMatchId,
                        onTap: { onSelect(match.matchId) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

struct MatchChip: View {
    let match: MatchProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.pink : Color(.systemGray5))
                        .frame(width: 28, height: 28)
                    
                    Text(match.displayName.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                
                // Name
                Text(match.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.pink : Color(.systemGray6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MatchChipsRow(
        matches: [
            MatchProfile(name: "Emma"),
            MatchProfile(name: "Sofia"),
            MatchProfile(name: "Ava"),
        ],
        selectedMatchId: .constant(nil),
        onSelect: { _ in }
    )
    .background(Color(.systemBackground))
}
