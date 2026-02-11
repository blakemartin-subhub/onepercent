import SwiftUI
import SharedKit
import PhotosUI
import AVFoundation

/// MVP keyboard view: Import → Processing → Direction → Results (stateless sessions)
struct KeyboardMainView: View {
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void
    let onNextKeyboard: () -> Void
    let onOpenApp: () -> Void
    var onRequestHeight: ((CGFloat) -> Void)? = nil
    
    @State private var processingState: KeyboardState = .idle
    
    // Import pickers
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedImageItems: [PhotosPickerItem] = []
    
    // Parsed context (passed between states)
    @State private var parsedProfile: MatchProfile?
    @State private var ocrText: String = ""
    @State private var contentType: ContentType = .profile // auto-detected
    
    // Direction state
    @State private var selectedDirection: MessageDirection?
    @State private var selectedLineMode: MessageLineMode = .twoThreeLines
    @State private var customInstruction: String = ""
    @State private var showTailoredKeyboard: Bool = false
    
    enum ContentType {
        case profile     // First message / opener
        case conversation // Reply to ongoing chat
    }
    
    enum KeyboardState: Equatable {
        case idle
        case loadingVideo
        case extractingFrames(progress: Double)
        case runningOCR(progress: Double)
        case parsingProfile
        case direction(name: String)
        case generatingMessages(name: String, step: DraftingStep)
        case ready(messages: [String], reasoning: String, matchedPrompt: String?)
        case returningHome
        case error(String)
        
        enum DraftingStep: String, Equatable {
            case analyzing = "Analyzing context..."
            case finding = "Finding conversation hooks..."
            case crafting = "Crafting messages..."
            case optimizing = "Optimizing tone..."
        }
    }
    
    enum MessageDirection: String, CaseIterable {
        case funny = "Funny"
        case flirty = "Flirty"
        case bold = "Bold"
        case chill = "Chill"
        case date = "Schedule a Date"
        
        var icon: String {
            switch self {
            case .funny: return "face.smiling"
            case .flirty: return "heart"
            case .bold: return "flame"
            case .chill: return "leaf"
            case .date: return "calendar"
            }
        }
    }
    
    enum MessageLineMode: String, CaseIterable {
        case oneLine = "one"
        case twoThreeLines = "twoThree"
        case threePlusLines = "threePlus"
        
        var displayLabel: String {
            switch self {
            case .oneLine: return "1 Line"
            case .twoThreeLines: return "2-3 Lines"
            case .threePlusLines: return "3+ Lines"
            }
        }
        
        var icon: String {
            switch self {
            case .oneLine: return "text.alignleft"
            case .twoThreeLines: return "text.justify.left"
            case .threePlusLines: return "text.justify"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(KeyboardBrand.keyboardBackground)
        .onChange(of: selectedVideoItem) { _, newItem in
            if let item = newItem {
                processSelectedVideo(item)
            }
        }
        .onChange(of: selectedImageItems) { _, newItems in
            if !newItems.isEmpty {
                processSelectedImages(newItems)
            }
        }
        .onChange(of: processingState) { _, _ in
            updateRequestedHeight()
        }
        .onChange(of: showTailoredKeyboard) { _, _ in
            updateRequestedHeight()
        }
        .onChange(of: resultsTypingActive) { _, _ in
            updateRequestedHeight()
        }
    }
    
    private func updateRequestedHeight() {
        switch processingState {
        case .ready:
            if resultsTypingActive {
                onRequestHeight?(380)
            } else {
                onRequestHeight?(280)
            }
        case .direction:
            if showTailoredKeyboard {
                onRequestHeight?(310)
            } else {
                onRequestHeight?(290)
            }
        default:
            onRequestHeight?(380)
        }
    }
    
    // Tracks if ResultsView typing keyboard is showing (for height updates)
    @State private var resultsTypingActive: Bool = false
    
    // MARK: - Main Content Router
    
    @ViewBuilder
    private var mainContentView: some View {
        switch processingState {
        case .idle:
            importView
            
        case .loadingVideo:
            ProcessingView(
                icon: "arrow.down.circle",
                title: "Loading...",
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
                title: "Reading content...",
                subtitle: "\(Int(progress * 100))%",
                progress: progress
            )
            
        case .parsingProfile:
            ProcessingView(
                icon: "person.text.rectangle",
                title: "Understanding context...",
                subtitle: nil,
                progress: nil
            )
            
        case .direction(let name):
            directionView(name: name)
            
        case .generatingMessages(let name, let step):
            DraftingAnimationView(name: name, step: step)
            
        case .ready(let messages, let reasoning, let matchedPrompt):
            ResultsView(
                initialMessages: messages,
                reasoning: reasoning,
                matchedPrompt: matchedPrompt,
                matchProfile: parsedProfile,
                selectedDirection: selectedDirection,
                customInstruction: customInstruction,
                onInsertText: { text in onInsertText(text) },
                onDeleteBackward: onDeleteBackward,
                onRegenerate: { direction, instruction in
                    // Regenerate all with new direction
                    selectedDirection = direction
                    customInstruction = instruction
                    generateMessages()
                },
                onClose: { resetToIdle() },
                onTypingToggle: { isTyping in
                    resultsTypingActive = isTyping
                }
            )
            
        case .returningHome:
            ReturningHomeView()
            
        case .error(let message):
            ErrorView(message: message) {
                processingState = .idle
            }
        }
    }
    
    // MARK: - State 1: Import View
    
    private var importView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // User name greeting
            if let profile = MatchStore.shared.loadUserProfile() {
                Text("Hey \(profile.displayName)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
            }
            
            // Icon
            ZStack {
                Circle()
                    .fill(KeyboardBrand.accentLight.opacity(0.3))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 28))
                    .foregroundStyle(KeyboardBrand.accent)
            }
            
            VStack(spacing: 6) {
                Text("Import a profile or conversation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                
                Text("Screen record or screenshot what you see")
                    .font(.caption)
                    .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
            }
            
            // Import buttons
            HStack(spacing: 12) {
                // Screen Recording
                PhotosPicker(
                    selection: $selectedVideoItem,
                    matching: .videos
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "record.circle.fill")
                            .font(.caption.weight(.semibold))
                        Text("Recording")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(KeyboardBrand.accent)
                    .clipShape(Capsule())
                }
                
                // Screenshots
                PhotosPicker(
                    selection: $selectedImageItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.caption.weight(.semibold))
                        Text("Screenshots")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(KeyboardBrand.keyboardCard)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(KeyboardBrand.keyboardTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - State 3: Direction View
    
    private func directionView(name: String) -> some View {
        VStack(spacing: 0) {
            // Header with name -- pinned near top
            HStack {
                let label = contentType == .conversation ? "Replying to" : "Vibe For"
                Text("\(label) \(name)")
                    .font(showTailoredKeyboard ? .subheadline.weight(.bold) : .title3.weight(.bold))
                    .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                
                Spacer()
                
                Button(action: { resetToIdle() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(showTailoredKeyboard ? .caption : .title3)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, showTailoredKeyboard ? 4 : 6)
            .padding(.bottom, showTailoredKeyboard ? 8 : 20)
            
            // Direction pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: showTailoredKeyboard ? 4 : 10) {
                    ForEach(MessageDirection.allCases, id: \.self) { direction in
                        DirectionPill(
                            direction: direction,
                            isSelected: selectedDirection == direction,
                            compact: showTailoredKeyboard
                        ) {
                            if selectedDirection == direction {
                                selectedDirection = nil
                            } else {
                                selectedDirection = direction
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, showTailoredKeyboard ? 6 : 14)
            
            // Line mode pills -- FULL WIDTH segmented control
            HStack(spacing: 8) {
                ForEach(MessageLineMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLineMode = mode
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.system(size: showTailoredKeyboard ? 9 : 13))
                            Text(mode.displayLabel)
                                .font(showTailoredKeyboard ? .caption2.weight(.medium) : .subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, showTailoredKeyboard ? 6 : 12)
                        .background(selectedLineMode == mode ? KeyboardBrand.accent : KeyboardBrand.keyboardCard)
                        .foregroundStyle(selectedLineMode == mode ? .white : KeyboardBrand.keyboardTextSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, showTailoredKeyboard ? 6 : 14)
            
            // Tailored note text field + generate button
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showTailoredKeyboard.toggle()
                    }
                }) {
                    HStack {
                        Text(customInstruction.isEmpty ? "e.g. get her to grab coffee with me" : customInstruction)
                            .font(showTailoredKeyboard ? .caption : .subheadline)
                            .foregroundStyle(customInstruction.isEmpty ? KeyboardBrand.keyboardTextSecondary.opacity(0.6) : KeyboardBrand.keyboardTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        if !customInstruction.isEmpty {
                            Button(action: { customInstruction = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(KeyboardBrand.keyboardTextSecondary.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, showTailoredKeyboard ? 8 : 12)
                    .background(KeyboardBrand.keyboardCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(showTailoredKeyboard ? KeyboardBrand.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Generate button
                Button(action: {
                    showTailoredKeyboard = false
                    generateMessages()
                }) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(KeyboardBrand.accent)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            
            if !showTailoredKeyboard {
                Spacer(minLength: 4)
            }
            
            // Internal QWERTY keyboard for tailored note
            if showTailoredKeyboard {
                
                TypingKeyboardView(
                    onInsertText: { char in
                        customInstruction.append(char)
                    },
                    onDeleteBackward: {
                        if !customInstruction.isEmpty {
                            customInstruction.removeLast()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: showTailoredKeyboard)
    }
    
    // MARK: - Video Processing
    
    private func processSelectedVideo(_ item: PhotosPickerItem) {
        processingState = .loadingVideo
        
        Task {
            do {
                guard let video = try await item.loadTransferable(type: KeyboardVideoTransferable.self) else {
                    throw KeyboardProcessingError.videoLoadFailed
                }
                guard FileManager.default.fileExists(atPath: video.url.path) else {
                    throw KeyboardProcessingError.videoLoadFailed
                }
                await processVideoFile(video.url)
            } catch {
                await MainActor.run {
                    let errorMessage: String
                    if error.localizedDescription.contains("permission") ||
                       error.localizedDescription.contains("access") ||
                       error.localizedDescription.contains("denied") {
                        errorMessage = "Enable 'Allow Full Access' in Settings → Keyboard → OnePercent"
                    } else {
                        errorMessage = "Unable to load video. Make sure Full Access is enabled."
                    }
                    processingState = .error(errorMessage)
                    selectedVideoItem = nil
                }
            }
        }
    }
    
    private func processVideoFile(_ url: URL) async {
        do {
            await MainActor.run { processingState = .extractingFrames(progress: 0) }
            
            let videoService = KeyboardVideoService()
            let extractedText = try await videoService.extractTextFromVideo(at: url) { progress, _ in
                Task { @MainActor in
                    if progress < 0.5 {
                        processingState = .extractingFrames(progress: progress * 2)
                    } else {
                        processingState = .runningOCR(progress: (progress - 0.5) * 2)
                    }
                }
            }
            
            await parseExtractedText(extractedText)
            
        } catch {
            await handleProcessingError(error)
        }
    }
    
    // MARK: - Image Processing
    
    private func processSelectedImages(_ items: [PhotosPickerItem]) {
        processingState = .loadingVideo // reuse loading state
        
        Task {
            do {
                // Load all images first
                var images: [UIImage] = []
                for item in items {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                
                guard !images.isEmpty else {
                    throw KeyboardProcessingError.videoLoadFailed
                }
                
                let ocrService = KeyboardOCRService()
                let text = try await ocrService.recognizeText(from: images) { progress in
                    Task { @MainActor in
                        processingState = .runningOCR(progress: progress)
                    }
                }
                
                await parseExtractedText(text)
                
            } catch {
                await handleProcessingError(error)
            }
        }
    }
    
    // MARK: - Parse & Transition to Direction
    
    private func parseExtractedText(_ text: String) async {
        do {
            await MainActor.run {
                ocrText = text
                processingState = .parsingProfile
            }
            
            let apiClient = KeyboardAPIClient.shared
            let parseResponse: KeyboardParseProfileResponse
            
            do {
                parseResponse = try await apiClient.parseProfile(ocrText: text)
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet:
                        throw KeyboardProcessingError.networkError("No internet connection")
                    case NSURLErrorCannotConnectToHost, NSURLErrorTimedOut:
                        throw KeyboardProcessingError.serverUnreachable
                    case -1020:
                        throw KeyboardProcessingError.networkError("Local Network access denied. Go to Settings → Privacy → Local Network → Enable One Percent")
                    default:
                        throw KeyboardProcessingError.networkError("Code \(nsError.code): \(nsError.localizedDescription)")
                    }
                }
                throw error
            }
            
            let profile = parseResponse.toMatchProfile(rawOcrText: text)
            let name = profile.name ?? "Match"
            
            // Auto-detect content type from the parse response
            let detected: ContentType = parseResponse.contentType == "conversation" ? .conversation : .profile
            
            await MainActor.run {
                parsedProfile = profile
                contentType = detected
                selectedDirection = nil
                customInstruction = ""
                processingState = .direction(name: name)
                selectedVideoItem = nil
                selectedImageItems = []
            }
            
        } catch {
            await handleProcessingError(error)
        }
    }
    
    // MARK: - Generate Messages
    
    private func generateMessages() {
        guard let match = parsedProfile else { return }
        let name = match.name ?? "Match"
        
        processingState = .generatingMessages(name: name, step: .analyzing)
        
        Task {
            do {
                guard let userProfile = MatchStore.shared.loadUserProfile() else {
                    throw KeyboardProcessingError.noUserProfile
                }
                
                // Animate through drafting steps
                for step in [KeyboardState.DraftingStep.analyzing, .finding, .crafting, .optimizing] {
                    await MainActor.run {
                        processingState = .generatingMessages(name: name, step: step)
                    }
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
                
                let apiClient = KeyboardAPIClient.shared
                
                // Build direction string from pills + custom text
                let directionText = buildDirectionString()
                let lineModeValue = selectedLineMode.rawValue
                
                let result: (messages: [GeneratedMessage], reasoning: String?, matchedPrompt: String?)
                
                if contentType == .conversation {
                    result = try await apiClient.generateConversationMessages(
                        userProfile: userProfile,
                        matchProfile: match,
                        conversationContext: ocrText,
                        direction: directionText,
                        lineMode: lineModeValue
                    )
                } else {
                    result = try await apiClient.generateMessages(
                        userProfile: userProfile,
                        matchProfile: match,
                        direction: directionText,
                        lineMode: lineModeValue
                    )
                }
                
                let sortedMessages = result.messages.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
                let messageTexts = sortedMessages.map { $0.text }
                let reasoning = result.reasoning ?? "Based on their profile"
                
                await MainActor.run {
                    processingState = .ready(messages: messageTexts, reasoning: reasoning, matchedPrompt: result.matchedPrompt)
                }
                
            } catch {
                await handleProcessingError(error)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func buildDirectionString() -> String? {
        var parts: [String] = []
        if let direction = selectedDirection {
            parts.append(direction.rawValue)
        }
        if !customInstruction.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append(customInstruction.trimmingCharacters(in: .whitespaces))
        }
        return parts.isEmpty ? nil : parts.joined(separator: ". ")
    }
    
    private func resetToIdle() {
        processingState = .returningHome
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            processingState = .idle
            parsedProfile = nil
            ocrText = ""
            selectedDirection = nil
            selectedLineMode = .twoThreeLines
            customInstruction = ""
            showTailoredKeyboard = false
            selectedVideoItem = nil
            selectedImageItems = []
        }
    }
    
    private func handleProcessingError(_ error: Error) async {
        print("[Keyboard] Processing error: \(error)")
        await MainActor.run {
            processingState = .error(error.localizedDescription)
            selectedVideoItem = nil
            selectedImageItems = []
        }
    }
}

// MARK: - Direction Pill

struct DirectionPill: View {
    let direction: KeyboardMainView.MessageDirection
    let isSelected: Bool
    var compact: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: compact ? 3 : 6) {
                Image(systemName: direction.icon)
                    .font(.system(size: compact ? 9 : 13, weight: .medium))
                Text(direction.rawValue)
                    .font(compact ? .caption2.weight(.medium) : .subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : KeyboardBrand.keyboardTextPrimary)
            .padding(.horizontal, compact ? 8 : 14)
            .padding(.vertical, compact ? 5 : 10)
            .background(isSelected ? KeyboardBrand.accent : KeyboardBrand.keyboardCard)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? KeyboardBrand.accent : KeyboardBrand.keyboardTextSecondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
        .padding(.vertical, 10)
    }
}

// MARK: - Drafting Animation View

struct DraftingAnimationView: View {
    let name: String
    let step: KeyboardMainView.KeyboardState.DraftingStep
    
    @State private var dotCount = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 14) {
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
        .padding(.vertical, 10)
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
    let initialMessages: [String]
    let reasoning: String
    let matchedPrompt: String?
    let matchProfile: MatchProfile?
    let selectedDirection: KeyboardMainView.MessageDirection?
    let customInstruction: String
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void
    let onRegenerate: (KeyboardMainView.MessageDirection?, String) -> Void
    let onClose: () -> Void
    var onTypingToggle: ((Bool) -> Void)? = nil
    
    @State private var messages: [String] = []
    @State private var sentIndices: Set<Int> = []
    @State private var showTypingKeyboard: Bool = false
    @State private var regeneratingIndex: Int? = nil
    @State private var showDirectionEditor = false
    
    // Local direction state for regen
    @State private var localDirection: KeyboardMainView.MessageDirection?
    @State private var localInstruction: String = ""
    
    private var nextToSend: Int? {
        for i in 0..<messages.count {
            if !sentIndices.contains(i) { return i }
        }
        return nil
    }
    
    private var allSent: Bool {
        !messages.isEmpty && sentIndices.count >= messages.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Matched prompt context -- Prompt title + Match's Answer
            if let prompt = matchedPrompt, !prompt.isEmpty, !showTypingKeyboard {
                VStack(alignment: .leading, spacing: 3) {
                    let parts = prompt.components(separatedBy: " → ")
                    let promptTitle = parts.first?.replacingOccurrences(of: "\"", with: "") ?? prompt
                    let promptAnswer = parts.count > 1 ? parts[1].replacingOccurrences(of: "\"", with: "") : ""
                    
                    Text("Prompt: \(promptTitle)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                    
                    if !promptAnswer.isEmpty {
                        let matchName = matchProfile?.name ?? "Match"
                        Text("\(matchName)'s Answer: \(promptAnswer)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KeyboardBrand.keyboardCard.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            
            // Header row
            HStack {
                if !showTypingKeyboard {
                    Text("Tap Messages To Send In Order")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    showTypingKeyboard.toggle()
                    onTypingToggle?(showTypingKeyboard)
                }) {
                    Image(systemName: showTypingKeyboard ? "text.bubble.fill" : "keyboard")
                        .font(.body)
                        .foregroundStyle(KeyboardBrand.accent)
                }
                .padding(.trailing, 6)
                
                Button(action: {
                    onRegenerate(localDirection, localInstruction)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundStyle(KeyboardBrand.warning)
                }
                .padding(.trailing, 6)
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(KeyboardBrand.keyboardTextSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, matchedPrompt == nil ? 10 : 4)
            .padding(.bottom, 4)
            
            if showTypingKeyboard {
                TypingKeyboardView(
                    onInsertText: onInsertText,
                    onDeleteBackward: onDeleteBackward
                )
            } else {
                // Message sequence
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            MessageSequenceCard(
                                text: message,
                                index: index + 1,
                                isSent: sentIndices.contains(index),
                                isNext: nextToSend == index,
                                isRegenerating: regeneratingIndex == index,
                                onTap: {
                                    onInsertText(message)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        sentIndices.insert(index)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                },
                                onRegenerate: { regenerateLine(at: index) }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                }
                
                // Close Chat button -- appears when all messages sent
                if allSent {
                    Button(action: onClose) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                            Text("Close Chat")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(KeyboardBrand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            if !allSent && !showTypingKeyboard {
                Spacer(minLength: 6)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: allSent)
        .onAppear {
            if messages.isEmpty {
                messages = initialMessages
            }
            localDirection = selectedDirection
            localInstruction = customInstruction
        }
    }
    
    // MARK: - Regenerate Single Line
    
    private func regenerateLine(at index: Int) {
        guard regeneratingIndex == nil else { return }
        regeneratingIndex = index
        
        Task {
            do {
                guard let userProfile = MatchStore.shared.loadUserProfile(),
                      let match = matchProfile else {
                    await MainActor.run { regeneratingIndex = nil }
                    return
                }
                
                let apiClient = KeyboardAPIClient.shared
                let result = try await apiClient.regenerateLine(
                    userProfile: userProfile,
                    matchProfile: match,
                    allMessages: messages,
                    lineIndex: index
                )
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        messages[index] = result.text
                    }
                    regeneratingIndex = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } catch {
                print("[Keyboard] Regen error: \(error)")
                await MainActor.run { regeneratingIndex = nil }
            }
        }
    }
}

// MARK: - Message Sequence Card

struct MessageSequenceCard: View {
    let text: String
    let index: Int
    let isSent: Bool
    let isNext: Bool
    let isRegenerating: Bool
    let onTap: () -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        Button(action: {
            if !isSent { onTap() }
        }) {
            HStack(spacing: 10) {
                // Order indicator
                ZStack {
                    if isSent {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .background(isSent ? KeyboardBrand.success : (isNext ? KeyboardBrand.accent : KeyboardBrand.keyboardTextSecondary.opacity(0.5)))
                .clipShape(Circle())
                
                // Message text
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(isSent ? KeyboardBrand.keyboardTextSecondary : .white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .strikethrough(isSent, color: KeyboardBrand.keyboardTextSecondary)
                
                // Regen button (only for unsent)
                if !isSent {
                    Button(action: onRegenerate) {
                        if isRegenerating {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(KeyboardBrand.warning)
                        }
                    }
                    .disabled(isRegenerating)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isNext && !isSent ? KeyboardBrand.accent.opacity(0.15) : KeyboardBrand.keyboardCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isNext && !isSent ? KeyboardBrand.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .opacity(isSent ? 0.5 : 1.0)
            .opacity(isRegenerating ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isSent)
    }
}

// MARK: - Typing Keyboard View

struct TypingKeyboardView: View {
    let onInsertText: (String) -> Void
    let onDeleteBackward: () -> Void
    
    @State private var isShiftActive = false
    
    private let row1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let row2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let row3 = ["Z", "X", "C", "V", "B", "N", "M"]
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                ForEach(row1, id: \.self) { key in
                    KeyButton(label: isShiftActive ? key : key.lowercased()) { insertKey(key) }
                }
            }
            
            HStack(spacing: 4) {
                ForEach(row2, id: \.self) { key in
                    KeyButton(label: isShiftActive ? key : key.lowercased()) { insertKey(key) }
                }
            }
            
            HStack(spacing: 4) {
                Button(action: { isShiftActive.toggle() }) {
                    Image(systemName: isShiftActive ? "shift.fill" : "shift")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isShiftActive ? .white : KeyboardBrand.keyboardTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isShiftActive ? KeyboardBrand.accent : KeyboardBrand.keyboardCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                ForEach(row3, id: \.self) { key in
                    KeyButton(label: isShiftActive ? key : key.lowercased()) { insertKey(key) }
                }
                
                Button(action: onDeleteBackward) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(KeyboardBrand.keyboardCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            HStack(spacing: 6) {
                Button(action: { onInsertText(" ") }) {
                    Text("space")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(KeyboardBrand.keyboardCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button(action: { onInsertText("\n") }) {
                    Text("return")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 44)
                        .background(KeyboardBrand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.horizontal, 3)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
    
    private func insertKey(_ key: String) {
        let character = isShiftActive ? key : key.lowercased()
        onInsertText(character)
        if isShiftActive { isShiftActive = false }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Key Button

struct KeyButton: View {
    let label: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(KeyboardBrand.keyboardCard)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

// MARK: - Returning Home View

struct ReturningHomeView: View {
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(KeyboardBrand.success.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KeyboardBrand.success)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }
            
            Text("Done!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(KeyboardBrand.keyboardTextPrimary)
                .opacity(checkmarkOpacity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
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
            let url = BackendConfig.shared.baseURL
            return "Cannot connect to server at \(url). Check the Server URL in the app's Settings and make sure the backend is running."
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
