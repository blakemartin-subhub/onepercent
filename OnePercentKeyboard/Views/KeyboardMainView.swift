import SwiftUI
import SharedKit
import PhotosUI
import AVFoundation

/// Main keyboard view with full in-keyboard processing
struct KeyboardMainView: View {
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void
    let onNextKeyboard: () -> Void
    let onOpenApp: () -> Void
    
    @State private var matches: [MatchProfile] = []
    @State private var currentMatch: MatchProfile?
    @State private var currentMessages: GeneratedMessageSet?
    @State private var processingState: ProcessingState = .idle
    @State private var errorMessage: String?
    
    // Video picker state
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var isLoadingVideo = false
    
    enum ProcessingState: Equatable {
        case idle
        case loadingVideo
        case extractingFrames(progress: Double)
        case runningOCR(progress: Double)
        case parsingProfile
        case generatingMessages(name: String, step: DraftingStep)
        case ready(messages: [String], reasoning: String)
        case sending(index: Int, total: Int)
        case error(String)
        
        enum DraftingStep: String, Equatable {
            case analyzing = "Analyzing profile..."
            case finding = "Finding conversation hooks..."
            case crafting = "Crafting opener..."
            case optimizing = "Optimizing tone..."
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            mainContentView
            
            // Bottom controls
            ControlsRow(
                onNextKeyboard: onNextKeyboard,
                onDeleteBackward: onDeleteBackward,
                onOpenApp: onOpenApp
            )
        }
        .background(Color(.systemGray6))
        .onAppear(perform: loadData)
        .onChange(of: selectedVideoItem) { _, newItem in
            if let item = newItem {
                processSelectedVideo(item)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .processConversationVideo)) { notification in
            if let userInfo = notification.userInfo,
               let item = userInfo["item"] as? PhotosPickerItem,
               let match = userInfo["match"] as? MatchProfile {
                processConversationVideo(item, for: match)
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        switch processingState {
        case .idle:
            if matches.isEmpty {
                emptyStateView
            } else {
                matchListView
            }
            
        case .loadingVideo:
            ProcessingView(
                icon: "arrow.down.circle",
                title: "Loading video...",
                subtitle: nil,
                progress: nil
            )
            
        case .extractingFrames(let progress):
            ProcessingView(
                icon: "film",
                title: "Extracting frames...",
                subtitle: "\(Int(progress * 100))%",
                progress: progress
            )
            
        case .runningOCR(let progress):
            ProcessingView(
                icon: "text.viewfinder",
                title: "Reading profile...",
                subtitle: "\(Int(progress * 100))%",
                progress: progress
            )
            
        case .parsingProfile:
            ProcessingView(
                icon: "person.text.rectangle",
                title: "Understanding profile...",
                subtitle: nil,
                progress: nil
            )
            
        case .generatingMessages(let name, let step):
            DraftingAnimationView(name: name, step: step)
            
        case .ready(let messages, let reasoning):
            ResultsView(
                messages: messages,
                reasoning: reasoning,
                onSend: { index in sendMessage(at: index) },
                onSendAll: sendAllMessages,
                onClose: { 
                    processingState = .idle
                    // Reload matches to show the new one
                    matches = MatchStore.shared.loadAllMatches()
                }
            )
            
        case .sending(let index, let total):
            ProcessingView(
                icon: "paperplane.fill",
                title: "Sending \(index)/\(total)...",
                subtitle: nil,
                progress: Double(index) / Double(total)
            )
            
        case .error(let message):
            ErrorView(message: message) {
                processingState = .idle
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.pink.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "heart.text.square")
                    .font(.system(size: 30))
                    .foregroundStyle(.pink)
            }
            
            VStack(spacing: 6) {
                Text("Add Your First Match")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Screen record their dating profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            PhotosPicker(
                selection: $selectedVideoItem,
                matching: .videos
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "record.circle.fill")
                    Text("Import Recording")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Match List
    
    private var matchListView: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Your Matches")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                PhotosPicker(
                    selection: $selectedVideoItem,
                    matching: .videos
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("New")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            // Match cards - vertical list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(matches) { match in
                        MatchRow(
                            match: match,
                            onTapMessages: { selectMatch(match) },
                            onTapUpdate: { startConversationUpdate(for: match) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Conversation Update
    
    @State private var matchForConversationUpdate: MatchProfile?
    @State private var conversationVideoItem: PhotosPickerItem?
    
    private func startConversationUpdate(for match: MatchProfile) {
        matchForConversationUpdate = match
        // The PhotosPicker will be triggered by the row
    }
    
    private func processConversationVideo(_ item: PhotosPickerItem, for match: MatchProfile) {
        processingState = .loadingVideo
        
        Task {
            do {
                guard let video = try await item.loadTransferable(type: KeyboardVideoTransferable.self) else {
                    throw KeyboardProcessingError.videoLoadFailed
                }
                
                guard FileManager.default.fileExists(atPath: video.url.path) else {
                    throw KeyboardProcessingError.videoLoadFailed
                }
                
                await processConversationVideoFile(video.url, for: match)
            } catch {
                await MainActor.run {
                    processingState = .error("Unable to load video")
                    conversationVideoItem = nil
                    matchForConversationUpdate = nil
                }
            }
        }
    }
    
    private func processConversationVideoFile(_ url: URL, for match: MatchProfile) async {
        do {
            // Phase 1: Extract frames & OCR
            await MainActor.run { processingState = .extractingFrames(progress: 0) }
            
            let videoService = KeyboardVideoService()
            let conversationText = try await videoService.extractTextFromVideo(at: url) { progress, _ in
                Task { @MainActor in
                    if progress < 0.5 {
                        processingState = .extractingFrames(progress: progress * 2)
                    } else {
                        processingState = .runningOCR(progress: (progress - 0.5) * 2)
                    }
                }
            }
            
            print("[Keyboard] Conversation OCR text length: \(conversationText.count)")
            
            // Phase 2: Generate follow-up messages with conversation context
            guard let userProfile = MatchStore.shared.loadUserProfile() else {
                throw KeyboardProcessingError.noUserProfile
            }
            
            let name = match.name ?? "Match"
            
            for step in [ProcessingState.DraftingStep.analyzing, .finding, .crafting, .optimizing] {
                await MainActor.run {
                    processingState = .generatingMessages(name: name, step: step)
                }
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            
            let apiClient = KeyboardAPIClient.shared
            let result = try await apiClient.generateConversationMessages(
                userProfile: userProfile,
                matchProfile: match,
                conversationContext: conversationText
            )
            
            // Save updated messages
            let messageSet = GeneratedMessageSet(
                matchId: match.matchId,
                messages: result.messages,
                toneUsed: userProfile.voiceTone
            )
            
            MatchStore.shared.saveMessages(messageSet)
            
            // Show results
            let sortedMessages = result.messages.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            let messageTexts = sortedMessages.map { $0.text }
            let reasoning = result.reasoning ?? "Based on your conversation"
            
            await MainActor.run {
                currentMatch = match
                processingState = .ready(messages: messageTexts, reasoning: reasoning)
                conversationVideoItem = nil
                matchForConversationUpdate = nil
            }
            
        } catch {
            print("[Keyboard] Conversation processing error: \(error)")
            await MainActor.run {
                processingState = .error(error.localizedDescription)
                conversationVideoItem = nil
                matchForConversationUpdate = nil
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        matches = MatchStore.shared.loadAllMatches()
    }
    
    private func selectMatch(_ match: MatchProfile) {
        currentMatch = match
        if let messages = MatchStore.shared.loadMessages(for: match.id) {
            let messageTexts = messages.messages.map { $0.text }
            let reasoning = generateReasoning(for: match)
            processingState = .ready(messages: messageTexts, reasoning: reasoning)
        }
    }
    
    // MARK: - Video Processing
    
    private func processSelectedVideo(_ item: PhotosPickerItem) {
        processingState = .loadingVideo
        
        Task {
            do {
                print("[Keyboard] Loading video from PhotosPicker...")
                
                // Try to load the video
                guard let video = try await item.loadTransferable(type: KeyboardVideoTransferable.self) else {
                    print("[Keyboard] Video transferable returned nil")
                    throw KeyboardProcessingError.videoLoadFailed
                }
                
                print("[Keyboard] Video loaded successfully: \(video.url)")
                
                // Check if file exists
                guard FileManager.default.fileExists(atPath: video.url.path) else {
                    print("[Keyboard] Video file doesn't exist at path")
                    throw KeyboardProcessingError.videoLoadFailed
                }
                
                await processVideoFile(video.url)
            } catch {
                print("[Keyboard] Error loading video: \(error)")
                await MainActor.run {
                    // Check if it's likely a permissions issue
                    let errorMessage: String
                    if error.localizedDescription.contains("permission") || 
                       error.localizedDescription.contains("access") ||
                       error.localizedDescription.contains("denied") {
                        errorMessage = "Enable 'Allow Full Access' in Settings → Keyboard → OnePercent"
                    } else {
                        errorMessage = "Unable to load video. Make sure Full Access is enabled for this keyboard."
                    }
                    processingState = .error(errorMessage)
                    selectedVideoItem = nil
                }
            }
        }
    }
    
    private func processVideoFile(_ url: URL) async {
        do {
            // Phase 1: Extract frames
            await MainActor.run { processingState = .extractingFrames(progress: 0) }
            
            let videoService = KeyboardVideoService()
            let ocrText = try await videoService.extractTextFromVideo(at: url) { progress, status in
                Task { @MainActor in
                    if progress < 0.5 {
                        processingState = .extractingFrames(progress: progress * 2)
                    } else {
                        processingState = .runningOCR(progress: (progress - 0.5) * 2)
                    }
                }
            }
            
            print("[Keyboard] OCR text length: \(ocrText.count)")
            
            // Phase 2: Parse profile with AI
            await MainActor.run { processingState = .parsingProfile }
            
            let apiClient = KeyboardAPIClient.shared
            let parseResponse: KeyboardParseProfileResponse
            do {
                parseResponse = try await apiClient.parseProfile(ocrText: ocrText)
            } catch {
                // Check if this is a network error and provide a better message
                let nsError = error as NSError
                print("[Keyboard] API error: \(nsError.domain) code: \(nsError.code)")
                if nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                        throw KeyboardProcessingError.fullAccessRequired
                    case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut:
                        throw KeyboardProcessingError.serverUnreachable
                    default:
                        throw KeyboardProcessingError.networkError(nsError.localizedDescription)
                    }
                }
                throw error
            }
            let matchProfile = parseResponse.toMatchProfile(rawOcrText: ocrText)
            
            print("[Keyboard] Parsed profile: \(matchProfile.name ?? "unknown")")
            
            // Phase 3: Generate messages
            guard let userProfile = MatchStore.shared.loadUserProfile() else {
                throw KeyboardProcessingError.noUserProfile
            }
            
            let name = matchProfile.name ?? "Match"
            
            // Animate through drafting steps
            for step in [ProcessingState.DraftingStep.analyzing, .finding, .crafting, .optimizing] {
                await MainActor.run {
                    processingState = .generatingMessages(name: name, step: step)
                }
                try await Task.sleep(nanoseconds: 600_000_000) // 0.6s per step
            }
            
            let messages: [GeneratedMessage]
            let apiReasoning: String?
            do {
                let result = try await apiClient.generateMessages(
                    userProfile: userProfile,
                    matchProfile: matchProfile
                )
                messages = result.messages
                apiReasoning = result.reasoning
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                        throw KeyboardProcessingError.fullAccessRequired
                    case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut:
                        throw KeyboardProcessingError.serverUnreachable
                    default:
                        throw KeyboardProcessingError.networkError(nsError.localizedDescription)
                    }
                }
                throw error
            }
            
            // Save to store
            let messageSet = GeneratedMessageSet(
                matchId: matchProfile.matchId,
                messages: messages,
                toneUsed: userProfile.voiceTone
            )
            
            MatchStore.shared.saveMatch(matchProfile)
            MatchStore.shared.saveMessages(messageSet)
            MatchStore.shared.saveLastSelectedMatch(matchProfile.matchId)
            
            // Show results - sort messages by order if available
            let sortedMessages = messages.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            let messageTexts = sortedMessages.map { $0.text }
            let reasoning = apiReasoning ?? generateReasoning(for: matchProfile)
            
            await MainActor.run {
                currentMatch = matchProfile
                matches = MatchStore.shared.loadAllMatches()
                processingState = .ready(messages: messageTexts, reasoning: reasoning)
                selectedVideoItem = nil
            }
            
        } catch {
            print("[Keyboard] Processing error: \(error)")
            await MainActor.run {
                processingState = .error(error.localizedDescription)
                selectedVideoItem = nil
            }
        }
    }
    
    // MARK: - Message Sending
    
    private func sendMessage(at index: Int) {
        guard case .ready(let messages, _) = processingState,
              index < messages.count else { return }
        
        onInsertText(messages[index])
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func sendAllMessages() {
        guard case .ready(let messages, _) = processingState else { return }
        
        // Insert all messages with line breaks
        let combined = messages.joined(separator: "\n\n")
        onInsertText(combined)
        
        processingState = .idle
    }
    
    // MARK: - Helpers
    
    private func generateReasoning(for match: MatchProfile) -> String {
        let name = match.name ?? "They"
        let interest = match.interests.first ?? "interesting things"
        return "\(name) mentioned \(interest), so we're leading with that to build genuine connection."
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let progress: Double?
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                if let progress = progress {
                    Circle()
                        .stroke(Color.pink.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.pink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.pink)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Drafting Animation View

struct DraftingAnimationView: View {
    let name: String
    let step: KeyboardMainView.ProcessingState.DraftingStep
    
    @State private var dotCount = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                // Animated pill
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.pink)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Drafting for \(name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(step.rawValue + String(repeating: ".", count: dotCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [.pink.opacity(0.15), .purple.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
            )
            .overlay(
                Capsule()
                    .strokeBorder(LinearGradient(colors: [.pink.opacity(0.5), .purple.opacity(0.5)], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
            )
            .clipShape(Capsule())
            
            Spacer()
        }
        .onAppear { animateDots() }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Results View

struct ResultsView: View {
    let messages: [String]
    let reasoning: String
    let onSend: (Int) -> Void
    let onSendAll: () -> Void
    let onClose: () -> Void
    
    @State private var confirmedIndices: Set<Int> = []
    @State private var sendingMode = false
    @State private var currentSendIndex = 0
    
    private var allConfirmed: Bool {
        confirmedIndices.count == messages.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if sendingMode {
                // Sending mode - just the send button
                sendingModeView
            } else {
                // Confirmation mode - show messages to confirm
                confirmationModeView
            }
        }
    }
    
    // MARK: - Confirmation Mode
    
    private var confirmationModeView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm messages")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Swipe right on each to confirm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Scrollable message list
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        SwipeToConfirmPill(
                            text: message,
                            index: index + 1,
                            total: messages.count,
                            isConfirmed: confirmedIndices.contains(index),
                            onConfirm: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    confirmedIndices.insert(index)
                                }
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                // Auto-enter sending mode when all confirmed
                                if confirmedIndices.count == messages.count {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            sendingMode = true
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 180) // Fixed height for scroll area
        }
    }
    
    // MARK: - Sending Mode
    
    private var sendingModeView: some View {
        VStack {
            Spacer()
            
            Button(action: sendCurrentMessage) {
                Text("Message \(currentSendIndex + 1) of \(messages.count)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func sendCurrentMessage() {
        // Send the current message
        onSend(currentSendIndex)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Move to next or close
        if currentSendIndex < messages.count - 1 {
            currentSendIndex += 1
        } else {
            // All messages sent, close
            onClose()
        }
    }
}

// MARK: - Swipe to Confirm Pill

struct SwipeToConfirmPill: View {
    let text: String
    let index: Int
    let total: Int
    let isConfirmed: Bool
    let onConfirm: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isHorizontalDrag = false
    
    private let confirmThreshold: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background (revealed when swiping) - subtle gray
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .padding(.leading, 16)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Foreground pill
            HStack(spacing: 10) {
                // Order indicator - green only when confirmed
                Text("\(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(isConfirmed ? Color.green : Color.pink)
                    .clipShape(Circle())
                
                // Message text
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Swipe hint or confirmed indicator
                if isConfirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    // Swipe hint arrow
                    Image(systemName: "arrow.right.circle")
                        .font(.body)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            .offset(x: isConfirmed ? 0 : offset)
            .gesture(
                isConfirmed ? nil : DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        // Only activate horizontal drag if moving more horizontally than vertically
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        // First movement determines if this is a horizontal or vertical gesture
                        if !isHorizontalDrag && horizontalAmount > 15 && horizontalAmount > verticalAmount * 1.5 {
                            isHorizontalDrag = true
                        }
                        
                        // Only apply offset if this is a horizontal drag going right
                        if isHorizontalDrag && value.translation.width > 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if isHorizontalDrag && value.translation.width > confirmThreshold {
                            onConfirm()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                        }
                        isHorizontalDrag = false
                    }
            )
        }
        .frame(height: 50)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            
            Text("Something went wrong")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: onDismiss) {
                Text("Try Again")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.pink)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
    }
}

// MARK: - Match Row (for vertical list)

struct MatchRow: View {
    let match: MatchProfile
    let onTapMessages: () -> Void
    let onTapUpdate: () -> Void
    
    @State private var showUpdatePicker = false
    @State private var selectedVideo: PhotosPickerItem?
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(match.name?.prefix(1).uppercased() ?? "?")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                )
            
            // Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(match.name ?? "Unknown")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if let interests = match.interests.first {
                    Text(interests)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Update conversation button
                PhotosPicker(selection: $selectedVideo, matching: .videos) {
                    Image(systemName: "message.badge.filled.fill")
                        .font(.body)
                        .foregroundStyle(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Circle())
                }
                .onChange(of: selectedVideo) { _, newItem in
                    if let item = newItem {
                        // Trigger conversation update flow
                        NotificationCenter.default.post(
                            name: .processConversationVideo,
                            object: nil,
                            userInfo: ["item": item, "match": match]
                        )
                        selectedVideo = nil
                    }
                }
                
                // View saved messages button
                Button(action: onTapMessages) {
                    Image(systemName: "text.bubble.fill")
                        .font(.body)
                        .foregroundStyle(.pink)
                        .frame(width: 36, height: 36)
                        .background(Color.pink.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Notification for conversation video
extension Notification.Name {
    static let processConversationVideo = Notification.Name("processConversationVideo")
}

// MARK: - Match Chip (keeping for compatibility)

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

// MARK: - Controls Row

struct ControlsRow: View {
    let onNextKeyboard: () -> Void
    let onDeleteBackward: () -> Void
    let onOpenApp: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onNextKeyboard) {
                Image(systemName: "globe")
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.primary)
            }
            .frame(width: 60, height: 44)
            
            Spacer()
            
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

// MARK: - Video Transferable

struct KeyboardVideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return KeyboardVideoTransferable(url: tempURL)
        }
    }
}

// MARK: - Errors

enum KeyboardProcessingError: Error, LocalizedError {
    case videoLoadFailed
    case noUserProfile
    case fullAccessRequired
    case serverUnreachable
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .videoLoadFailed:
            return "Could not load the video"
        case .noUserProfile:
            return "Please set up your profile in the app first"
        case .fullAccessRequired:
            return "Enable Full Access: Settings → Keyboards → OnePercent → Allow Full Access"
        case .serverUnreachable:
            return "Cannot connect to server. Make sure your Mac is on the same network and the backend is running."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
