import SwiftUI
import SharedKit

struct MessagesResultView: View {
    let match: MatchProfile
    let messages: GeneratedMessageSet
    let onSave: () -> Void
    let onRegenerate: () -> Void
    
    @State private var copiedMessageId: UUID?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Brand.gradient)
                            .frame(width: 80, height: 80)
                        
                        Text(match.displayName.prefix(1).uppercased())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    Text("Messages for \(match.displayName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Brand.textPrimary)
                    
                    Text("Tap to copy, or save to use from keyboard")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }
                .padding(.top, 20)
                
                // Openers
                let openers = messages.messages.filter { $0.type == .opener }
                if !openers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "hand.wave.fill")
                                .foregroundStyle(Brand.accent)
                            Text("Openers")
                                .font(.headline)
                                .foregroundStyle(Brand.textPrimary)
                        }
                        .padding(.horizontal, 24)
                        
                        ForEach(openers) { message in
                            MessageCard(
                                message: message,
                                isCopied: copiedMessageId == message.id,
                                onCopy: { copyMessage(message) }
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                // Follow-ups
                let followUps = messages.messages.filter { $0.type == .followup }
                if !followUps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                                .foregroundStyle(Brand.accent.opacity(0.7))
                            Text("Follow-ups")
                                .font(.headline)
                                .foregroundStyle(Brand.textPrimary)
                        }
                        .padding(.horizontal, 24)
                        
                        ForEach(followUps) { message in
                            MessageCard(
                                message: message,
                                isCopied: copiedMessageId == message.id,
                                onCopy: { copyMessage(message) }
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save & Use from Keyboard")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Brand.buttonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                    }
                    
                    Button(action: onRegenerate) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate Messages")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Brand.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func copyMessage(_ message: GeneratedMessage) {
        UIPasteboard.general.string = message.text
        
        withAnimation {
            copiedMessageId = message.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                if copiedMessageId == message.id {
                    copiedMessageId = nil
                }
            }
        }
    }
}

struct MessageCard: View {
    let message: GeneratedMessage
    let isCopied: Bool
    let onCopy: () -> Void
    
    var body: some View {
        Button(action: onCopy) {
            VStack(alignment: .leading, spacing: 12) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    // Type badge
                    Text(message.type.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Brand.accentLight)
                        .foregroundStyle(Brand.accent)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Copy indicator
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Tap to copy")
                    }
                    .font(.caption)
                    .foregroundStyle(isCopied ? Brand.success : Brand.textSecondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: Brand.radiusLarge)
                    .stroke(isCopied ? Brand.success : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MessagesResultView(
            match: MatchProfile(name: "Emma", age: 28),
            messages: GeneratedMessageSet(
                matchId: UUID(),
                messages: [
                    GeneratedMessage(type: .opener, text: "Hey Emma! I noticed you're into hiking - what's been your favorite trail this year?"),
                    GeneratedMessage(type: .opener, text: "A fellow coffee enthusiast! Do you have a go-to order or are you more of an adventurous try-something-new type?"),
                    GeneratedMessage(type: .followup, text: "I'd love to hear more about your dog! What breed?")
                ],
                toneUsed: .playful
            ),
            onSave: {},
            onRegenerate: {}
        )
    }
}
