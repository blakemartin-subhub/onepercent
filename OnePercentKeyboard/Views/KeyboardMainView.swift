import SwiftUI
import SharedKit
import PhotosUI

/// Main keyboard view with the new keyboard-centric UX
struct KeyboardMainView: View {
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void
    let onNextKeyboard: () -> Void
    let onOpenApp: () -> Void
    
    @State private var matches: [MatchProfile] = []
    @State private var currentMatch: MatchProfile?
    @State private var currentMessages: GeneratedMessageSet?
    @State private var processingState: ProcessingState = .idle
    @State private var approvedLines: Set<Int> = []
    @State private var currentSendIndex: Int = 0
    @State private var showingResults: Bool = false
    
    enum ProcessingState: Equatable {
        case idle
        case drafting(name: String, step: DraftingStep)
        case ready(name: String)
        case sending(index: Int, total: Int)
        case complete
        
        enum DraftingStep: Equatable {
            case starting
            case analyzing(interest: String)
            case finding(commonality: String)
            case optimizing(tone: String)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch processingState {
            case .idle:
                if matches.isEmpty {
                    EmptyStateView(onOpenApp: onOpenApp)
                } else if showingResults, let match = currentMatch, let messages = currentMessages {
                    ResultsView(
                        match: match,
                        messages: messages,
                        approvedLines: $approvedLines,
                        currentSendIndex: $currentSendIndex,
                        onInsertText: onInsertText,
                        onClose: { showingResults = false }
                    )
                } else {
                    MatchListView(
                        matches: matches,
                        onSelectMatch: selectMatch,
                        onOpenApp: onOpenApp
                    )
                }
                
            case .drafting(let name, let step):
                DraftingAnimationView(name: name, step: step)
                
            case .ready(let name):
                ReadyPillView(name: name) {
                    showingResults = true
                    processingState = .idle
                }
                
            case .sending(let index, let total):
                SendingView(index: index, total: total)
                
            case .complete:
                CompleteView {
                    processingState = .idle
                    showingResults = false
                }
            }
            
            // Bottom controls
            ControlsRow(
                onNextKeyboard: onNextKeyboard,
                onDeleteBackward: onDeleteBackward,
                onOpenApp: onOpenApp
            )
        }
        .background(Color(.systemGray6))
        .onAppear(perform: loadData)
    }
    
    private func loadData() {
        matches = MatchStore.shared.getAllMatches()
        
        // Check for any pending processing results
        if let lastMatchId = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)?.string(forKey: "lastProcessedMatchId"),
           let match = matches.first(where: { $0.id.uuidString == lastMatchId }) {
            currentMatch = match
            currentMessages = MatchStore.shared.getMessages(for: match.id)
            processingState = .ready(name: match.name ?? "Match")
        }
    }
    
    private func selectMatch(_ match: MatchProfile) {
        currentMatch = match
        currentMessages = MatchStore.shared.getMessages(for: match.id)
        showingResults = true
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onOpenApp: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "record.circle")
                .font(.system(size: 40))
                .foregroundStyle(.pink)
            
            Text("Drop a 3-second screen recording")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("of the match's profile")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: onOpenApp) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Recording")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Match List View
struct MatchListView: View {
    let matches: [MatchProfile]
    let onSelectMatch: (MatchProfile) -> Void
    let onOpenApp: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Add new match button
            Button(action: onOpenApp) {
                HStack {
                    Image(systemName: "record.circle")
                        .foregroundStyle(.pink)
                    Text("Drop a screen recording")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.pink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 12)
            
            // Existing matches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(matches) { match in
                        MatchChip(match: match) {
                            onSelectMatch(match)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MatchChip: View {
    let match: MatchProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(match.name?.prefix(1).uppercased() ?? "?")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    )
                
                Text(match.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Drafting Animation View
struct DraftingAnimationView: View {
    let name: String
    let step: KeyboardMainView.ProcessingState.DraftingStep
    
    @State private var dotCount = 0
    @State private var showText = false
    
    private var displayText: String {
        let dots = String(repeating: ".", count: dotCount)
        switch step {
        case .starting:
            return "Drafting message to \(name)\(dots)"
        case .analyzing(let interest):
            return "\(name) likes \(interest)\(dots)"
        case .finding(let commonality):
            return "\(name) wants to \(commonality)\(dots)"
        case .optimizing(let tone):
            return "Optimizing for \(tone) tone\(dots)"
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text(displayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .animation(.easeInOut(duration: 0.3), value: displayText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.pink.opacity(0.2), .purple.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            
            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Ready Pill View
struct ReadyPillView: View {
    let name: String
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: onTap) {
                HStack(spacing: 10) {
                    // Red notification dot
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                    
                    Text("Message ready for \(name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.pink.opacity(0.15), .purple.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                )
                .clipShape(Capsule())
            }
            
            Spacer()
        }
    }
}

// MARK: - Results View
struct ResultsView: View {
    let match: MatchProfile
    let messages: GeneratedMessageSet
    @Binding var approvedLines: Set<Int>
    @Binding var currentSendIndex: Int
    let onInsertText: (String) -> Void
    let onClose: () -> Void
    
    private var messageLines: [String] {
        messages.messages.first?.text.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []
    }
    
    private var allApproved: Bool {
        approvedLines.count == messageLines.count && !messageLines.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            if allApproved {
                // Send mode
                SendModeView(
                    messageLines: messageLines,
                    currentSendIndex: $currentSendIndex,
                    onInsertText: onInsertText,
                    onComplete: onClose
                )
            } else {
                // Approval mode
                ScrollView {
                    VStack(spacing: 12) {
                        // Reasoning section
                        ReasoningCard(match: match, messages: messages)
                        
                        // Message lines to approve
                        ForEach(Array(messageLines.enumerated()), id: \.offset) { index, line in
                            SwipeablePill(
                                text: line,
                                index: index,
                                isApproved: approvedLines.contains(index),
                                onApprove: {
                                    approvedLines.insert(index)
                                }
                            )
                        }
                        
                        // Status
                        Text("\(approvedLines.count) of \(messageLines.count) ready to send")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

// MARK: - Reasoning Card
struct ReasoningCard: View {
    let match: MatchProfile
    let messages: GeneratedMessageSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.pink)
                Text("Why this message?")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Text(generateReasoning())
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateReasoning() -> String {
        let name = match.name ?? "They"
        let interest = match.interests.first ?? "interesting things"
        let hook = match.hooks.first ?? "conversation"
        
        return "\(name) mentioned \(interest), so we're starting with that to build rapport. If this goes well, it could lead to meeting up to explore that shared interest together."
    }
}

// MARK: - Swipeable Pill
struct SwipeablePill: View {
    let text: String
    let index: Int
    let isApproved: Bool
    let onApprove: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var hasTriggeredHaptic = false
    
    private let approveThreshold: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background (revealed on swipe)
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(.leading, 16)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green)
            .clipShape(Capsule())
            
            // Foreground pill
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(isApproved ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if !isApproved {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isApproved ? Color.green : Color(.systemGray5))
            .clipShape(Capsule())
            .offset(x: offset)
            .gesture(
                isApproved ? nil : DragGesture()
                    .onChanged { value in
                        if value.translation.width > 0 {
                            offset = value.translation.width
                            
                            // Haptic feedback at threshold
                            if offset >= approveThreshold && !hasTriggeredHaptic {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                hasTriggeredHaptic = true
                            }
                        }
                    }
                    .onEnded { value in
                        if offset >= approveThreshold {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                            onApprove()
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        }
                        hasTriggeredHaptic = false
                    }
            )
        }
        .frame(height: 50)
    }
}

// MARK: - Send Mode View
struct SendModeView: View {
    let messageLines: [String]
    @Binding var currentSendIndex: Int
    let onInsertText: (String) -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Current message preview
            Text(messageLines[safe: currentSendIndex] ?? "")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
            
            // Send button
            Button(action: sendCurrentMessage) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send message \(currentSendIndex + 1) of \(messageLines.count)")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
    }
    
    private func sendCurrentMessage() {
        guard currentSendIndex < messageLines.count else { return }
        
        onInsertText(messageLines[currentSendIndex])
        
        if currentSendIndex < messageLines.count - 1 {
            currentSendIndex += 1
        } else {
            onComplete()
        }
    }
}

// MARK: - Sending View
struct SendingView: View {
    let index: Int
    let total: Int
    
    var body: some View {
        VStack {
            Spacer()
            Text("Sending message \(index) of \(total)...")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Complete View
struct CompleteView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            
            Text("All messages sent!")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Button("Done", action: onDismiss)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.pink)
                .padding(.top, 8)
            
            Spacer()
        }
    }
}

// MARK: - Controls Row
struct ControlsRow: View {
    let onNextKeyboard: () -> Void
    let onDeleteBackward: () -> Void
    let onOpenApp: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Globe button
            Button(action: onNextKeyboard) {
                Image(systemName: "globe")
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.primary)
            }
            .frame(width: 60, height: 44)
            
            Spacer()
            
            // Backspace
            Button(action: onDeleteBackward) {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.primary)
            }
            .frame(width: 60, height: 44)
        }
        .background(Color(.systemGray5))
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
