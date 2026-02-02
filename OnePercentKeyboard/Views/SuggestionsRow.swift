import SwiftUI
import SharedKit

struct SuggestionsRow: View {
    let messages: [GeneratedMessage]
    let onSelect: (GeneratedMessage) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(messages) { message in
                    SuggestionCard(
                        message: message,
                        onTap: { onSelect(message) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(height: 120)
    }
}

struct SuggestionCard: View {
    let message: GeneratedMessage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: message.type == .opener ? "hand.wave" : "arrow.turn.down.right")
                        .font(.system(size: 10))
                    
                    Text(message.type.displayName)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(message.type == .opener ? .pink : .purple)
                
                // Message text
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Spacer()
                
                // Tap hint
                HStack {
                    Spacer()
                    Text("Tap to insert")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .frame(width: 200, height: 100)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SuggestionsRow(
        messages: [
            GeneratedMessage(type: .opener, text: "Hey! I noticed you're into hiking - what's been your favorite trail this year?"),
            GeneratedMessage(type: .opener, text: "A fellow coffee enthusiast! Do you have a go-to order?"),
            GeneratedMessage(type: .followUp, text: "I'd love to hear more about your dog! What breed?"),
        ],
        onSelect: { _ in }
    )
    .background(Color(.systemBackground))
}
