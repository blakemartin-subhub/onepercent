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
            // Main content area - fills available space
            mainContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(KeyboardBrand.keyboardBackground)
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
                onInsertText: { text in onInsertText(text) },
                onSwitchKeyboard: onNextKeyboard,
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
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(KeyboardBrand.accentLight.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.text.square")
                    .font(.system(size: 34))
                    .foregroundStyle(KeyboardBrand.accent)
            }
            
            VStack(spacing: 8) {
                Text("Add Your First Match")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                
                Text("Screen record their dating profile")
                    .font(.subheadline)
                    .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
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
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(KeyboardBrand.accent)
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Match List
    
    private var matchListView: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Your Matches")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(KeyboardBrand.accent)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            // Match cards - vertical list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(matches) { match in
                        MatchRow(
                            match: match,
                            onTapMessages: { selectMatch(match) },
                            onTapUpdate: { startConversationUpdate(for: match) }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                print("[Keyboard] API error: \(nsError.domain) code: \(nsError.code) - \(nsError.localizedDescription)")
                if nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet:
                        throw KeyboardProcessingError.networkError("No internet connection")
                    case NSURLErrorNetworkConnectionLost:
                        throw KeyboardProcessingError.networkError("Connection lost")
                    case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut:
                        throw KeyboardProcessingError.serverUnreachable
                    case -1020: // NSURLErrorNotPermittedByDNE (Local Network permission denied)
                        throw KeyboardProcessingError.networkError("Local Network access denied. Go to Settings → Privacy → Local Network → Enable One Percent")
                    default:
                        throw KeyboardProcessingError.networkError("Code \(nsError.code): \(nsError.localizedDescription)")
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
                print("[Keyboard] Generate messages error: \(nsError.domain) code: \(nsError.code) - \(nsError.localizedDescription)")
                if nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet:
                        throw KeyboardProcessingError.networkError("No internet connection")
                    case NSURLErrorNetworkConnectionLost:
                        throw KeyboardProcessingError.networkError("Connection lost")
                    case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut:
                        throw KeyboardProcessingError.serverUnreachable
                    case -1020: // NSURLErrorNotPermittedByDNE (Local Network permission denied)
                        throw KeyboardProcessingError.networkError("Local Network access denied. Go to Settings → Privacy → Local Network → Enable One Percent")
                    default:
                        throw KeyboardProcessingError.networkError("Code \(nsError.code): \(nsError.localizedDescription)")
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
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                if let progress = progress {
                    Circle()
                        .stroke(KeyboardBrand.accent.opacity(0.2), lineWidth: 4)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(KeyboardBrand.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(KeyboardBrand.accent)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
            
            HStack(spacing: 14) {
                // Animated pill
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(KeyboardBrand.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drafting for \(name)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                    
                    Text(step.rawValue + String(repeating: ".", count: dotCount))
                        .font(.subheadline)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(KeyboardBrand.accentLight.opacity(0.2))
            .overlay(
                Capsule()
                    .strokeBorder(KeyboardBrand.accent.opacity(0.5), lineWidth: 1)
            )
            .clipShape(Capsule())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    let onInsertText: (String) -> Void
    let onSwitchKeyboard: () -> Void
    let onClose: () -> Void
    
    @State private var confirmedIndices: Set<Int> = []
    
    private var allConfirmed: Bool {
        confirmedIndices.count == messages.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tap to send")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                    Text("Tap each message to paste")
                        .font(.caption)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
                
                Spacer()
                
                // Switch to system keyboard button
                Button(action: onSwitchKeyboard) {
                    Image(systemName: "keyboard")
                        .font(.title3)
                        .foregroundStyle(KeyboardBrand.accent)
                }
                .padding(.trailing, 8)
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Scrollable message list
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        TapToConfirmPill(
                            text: message,
                            index: index + 1,
                            isConfirmed: confirmedIndices.contains(index),
                            onTap: {
                                // Paste the text
                                onInsertText(message)
                                
                                // Mark as confirmed with animation
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    confirmedIndices.insert(index)
                                }
                                
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                // Auto-close when all confirmed
                                if confirmedIndices.count + 1 == messages.count {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        onClose()
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
}

// MARK: - Tap to Confirm Pill

struct TapToConfirmPill: View {
    let text: String
    let index: Int
    let isConfirmed: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Order indicator
                Text("\(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(isConfirmed ? KeyboardBrand.success : KeyboardBrand.accent)
                    .clipShape(Circle())
                
                // Message text
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Confirmed indicator
                if isConfirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(KeyboardBrand.success)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        }
        .disabled(isConfirmed)
        .frame(height: 50)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(KeyboardBrand.warning)
            
            Text("Something went wrong")
                .font(.title3.weight(.semibold))
                .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onDismiss) {
                Text("Try Again")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(KeyboardBrand.accent)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
                .fill(KeyboardBrand.accent)
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
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                
                if let interests = match.interests.first {
                    Text(interests)
                        .font(.caption)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
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
                        .foregroundStyle(KeyboardBrand.warning)
                        .frame(width: 36, height: 36)
                        .background(KeyboardBrand.warning.opacity(0.15))
                        .clipShape(Circle())
                }
                .onChange(of: selectedVideo) { _, newItem in
                    if let item = newItem {
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
                        .foregroundStyle(KeyboardBrand.accent)
                        .frame(width: 36, height: 36)
                        .background(KeyboardBrand.accentLight.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(KeyboardBrand.keyboardCard)
        .clipShape(RoundedRectangle(cornerRadius: KeyboardBrand.radiusMedium))
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
