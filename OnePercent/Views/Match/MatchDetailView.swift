import SwiftUI
import SharedKit

struct MatchDetailView: View {
    let match: MatchProfile
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var messages: GeneratedMessageSet?
    @State private var isRegenerating = false
    @State private var copiedMessageId: UUID?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text(match.displayName.prefix(1).uppercased())
                            .font(.system(size: 40))
                            .fontWeight(.bold)
                            .foregroundStyle(.pink)
                    }
                    
                    VStack(spacing: 4) {
                        Text(match.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if !match.summary.isEmpty {
                            Text(match.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Added \(match.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 20)
                
                // Saved messages
                if let messageSet = messages {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Saved Messages")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: regenerateMessages) {
                                HStack(spacing: 4) {
                                    if isRegenerating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Regenerate")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.pink)
                            }
                            .disabled(isRegenerating)
                        }
                        .padding(.horizontal, 24)
                        
                        ForEach(messageSet.messages) { message in
                            MessageCard(
                                message: message,
                                isCopied: copiedMessageId == message.id,
                                onCopy: { copyMessage(message) }
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("No messages generated yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button(action: regenerateMessages) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Generate Messages")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                        .disabled(isRegenerating)
                    }
                    .padding(.vertical, 40)
                }
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Profile details
                VStack(alignment: .leading, spacing: 20) {
                    Text("Profile Details")
                        .font(.headline)
                        .padding(.horizontal, 24)
                    
                    if let bio = match.bio, !bio.isEmpty {
                        DetailSection(title: "Bio", content: bio)
                    }
                    
                    if !match.prompts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Prompts")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                            
                            ForEach(match.prompts) { prompt in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prompt.prompt)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(prompt.answer)
                                        .font(.subheadline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    if !match.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interests")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(match.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.pink.opacity(0.1))
                                        .foregroundStyle(.pink)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    if !match.hooks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text("Conversation Hooks")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 24)
                            
                            ForEach(match.hooks, id: \.self) { hook in
                                HStack {
                                    Image(systemName: "sparkle")
                                        .foregroundStyle(.pink)
                                        .font(.caption)
                                    Text(hook)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                
                // Delete button
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Match")
                    }
                    .font(.subheadline)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            messages = MatchStore.shared.loadMessages(for: match.matchId)
        }
        .alert("Delete Match?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                appState.deleteMatch(match)
                dismiss()
            }
        } message: {
            Text("This will permanently delete \(match.displayName) and all generated messages.")
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
    
    private func regenerateMessages() {
        guard let userProfile = appState.userProfile else { return }
        
        isRegenerating = true
        
        Task {
            do {
                let apiClient = APIClient.shared
                let newMessages = try await apiClient.generateMessages(
                    userProfile: userProfile,
                    matchProfile: match
                )
                
                let messageSet = GeneratedMessageSet(
                    matchId: match.matchId,
                    messages: newMessages,
                    toneUsed: userProfile.voiceTone
                )
                
                MatchStore.shared.saveMessages(messageSet)
                
                await MainActor.run {
                    messages = messageSet
                    isRegenerating = false
                }
            } catch {
                await MainActor.run {
                    isRegenerating = false
                }
            }
        }
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(content)
                .font(.body)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(match: MatchProfile(
            name: "Emma",
            age: 28,
            bio: "Dog mom, coffee enthusiast, hiking lover",
            prompts: [
                PromptAnswer(prompt: "A perfect day would be", answer: "Morning hike, afternoon coffee shop, evening cooking dinner with friends")
            ],
            interests: ["Hiking", "Coffee", "Dogs", "Travel"],
            job: "Product Designer",
            location: "San Francisco",
            hooks: ["Loves hiking", "Has a dog"]
        ))
        .environmentObject(AppState())
    }
}
