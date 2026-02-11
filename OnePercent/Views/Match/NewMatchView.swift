import SwiftUI
import PhotosUI
import SharedKit
import AVFoundation
import UniformTypeIdentifiers

struct NewMatchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var fromShareExtension: Bool = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var ocrProgress: Double = 0
    @State private var ocrText: String?
    @State private var parsedProfile: MatchProfile?
    @State private var generatedMessages: GeneratedMessageSet?
    @State private var currentStep: ImportStep = .selectImages
    @State private var errorMessage: String?
    
    enum ImportStep {
        case selectImages
        case processing
        case reviewProfile
        case viewMessages
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .selectImages:
                    ImageSelectionView(
                        selectedItems: $selectedItems,
                        selectedImages: $selectedImages,
                        onProcess: startProcessing,
                        onVideoSelected: { url in
                            startVideoProcessing(videoURL: url)
                        }
                    )
                case .processing:
                    OCRProgressView(progress: ocrProgress)
                case .reviewProfile:
                    if let profile = parsedProfile {
                        ProfilePreviewView(
                            profile: Binding(
                                get: { profile },
                                set: { parsedProfile = $0 }
                            ),
                            onContinue: generateMessages,
                            onCancel: resetFlow
                        )
                    }
                case .viewMessages:
                    if let profile = parsedProfile, let messages = generatedMessages {
                        MessagesResultView(
                            match: profile,
                            messages: messages,
                            onSave: saveMatchAndDismiss,
                            onRegenerate: regenerateMessages
                        )
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep == .selectImages {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .onAppear {
            if fromShareExtension {
                loadShareExtensionImages()
            }
        }
    }
    
    private var navigationTitle: String {
        switch currentStep {
        case .selectImages: return "New Match"
        case .processing: return "Processing"
        case .reviewProfile: return "Review Profile"
        case .viewMessages: return "Messages"
        }
    }
    
    private func loadShareExtensionImages() {
        print("[NewMatchView] Loading share extension content...")
        
        // Check for video first (screen recording)
        if let videoURL = MatchStore.shared.getShareInboxVideoURL() {
            print("[NewMatchView] Found video at: \(videoURL)")
            print("[NewMatchView] Video exists: \(FileManager.default.fileExists(atPath: videoURL.path))")
            // Don't clear inbox here - do it after processing completes
            startVideoProcessing(videoURL: videoURL, clearInboxAfter: true)
            return
        }
        
        // Otherwise load images
        let urls = MatchStore.shared.getShareInboxImageURLs()
        print("[NewMatchView] Found \(urls.count) images")
        for url in urls {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
        // Clear inbox after loading images into memory
        MatchStore.shared.clearShareInbox()
        
        if !selectedImages.isEmpty {
            print("[NewMatchView] Starting image processing with \(selectedImages.count) images")
            startProcessing()
        } else {
            print("[NewMatchView] No content found in share inbox")
        }
    }
    
    private func startVideoProcessing(videoURL: URL, clearInboxAfter: Bool = false) {
        print("[NewMatchView] 🎬 Starting video processing for: \(videoURL)")
        print("[NewMatchView] Video path: \(videoURL.path())")
        print("[NewMatchView] Video exists: \(FileManager.default.fileExists(atPath: videoURL.path()))")
        
        if FileManager.default.fileExists(atPath: videoURL.path()) {
            let attrs = try? FileManager.default.attributesOfItem(atPath: videoURL.path())
            let fileSize = attrs?[.size] as? UInt64 ?? 0
            print("[NewMatchView] Video file size: \(fileSize) bytes (\(Double(fileSize) / 1024.0 / 1024.0) MB)")
        }
        
        currentStep = .processing
        isProcessing = true
        ocrProgress = 0
        
        Task {
            do {
                // Process video frames
                print("[NewMatchView] Creating VideoProcessingService...")
                let videoService = VideoProcessingService()
                print("[NewMatchView] Extracting text from video...")
                let text = try await videoService.extractTextFromVideo(at: videoURL) { progress, status in
                    Task { @MainActor in
                        ocrProgress = progress * 0.5
                        print("[NewMatchView] 📊 Video extraction progress: \(Int(progress * 100))% - \(status)")
                    }
                }
                
                print("[NewMatchView] ✅ Extracted text length: \(text.count) characters")
                print("[NewMatchView] Text preview: \(text.prefix(200))...")
                
                // Clear inbox after video frames have been extracted
                if clearInboxAfter {
                    print("[NewMatchView] Clearing share inbox...")
                    MatchStore.shared.clearShareInbox()
                }
                
                await MainActor.run {
                    ocrText = text
                    ocrProgress = 0.5
                }
                
                // Parse profile with AI
                print("[NewMatchView] 🤖 Parsing profile with AI...")
                let apiClient = APIClient.shared
                let parseResponse = try await apiClient.parseProfile(ocrText: text)
                
                print("[NewMatchView] ✅ Profile parsed successfully: \(parseResponse.name ?? "unknown")")
                
                await MainActor.run {
                    ocrProgress = 1.0
                    parsedProfile = parseResponse.toMatchProfile(rawOcrText: text)
                    currentStep = .reviewProfile
                    isProcessing = false
                }
            } catch {
                print("[NewMatchView] ❌ Video processing error: \(error)")
                print("[NewMatchView] Error type: \(type(of: error))")
                if let nsError = error as NSError? {
                    print("[NewMatchView] Error domain: \(nsError.domain), code: \(nsError.code)")
                    print("[NewMatchView] Error userInfo: \(nsError.userInfo)")
                }
                
                // Clean up even on error
                if clearInboxAfter {
                    MatchStore.shared.clearShareInbox()
                }
                await MainActor.run {
                    errorMessage = "Failed to process video: \(error.localizedDescription)"
                    currentStep = .selectImages
                    isProcessing = false
                }
            }
        }
    }
    
    private func startProcessing() {
        guard !selectedImages.isEmpty else { return }
        
        currentStep = .processing
        isProcessing = true
        ocrProgress = 0
        
        Task {
            do {
                // OCR
                print("[NewMatchView] Starting OCR...")
                let ocrService = OCRService()
                let text = try await ocrService.recognizeText(
                    from: selectedImages,
                    progressHandler: { progress in
                        Task { @MainActor in
                            ocrProgress = progress * 0.5 // OCR is 50% of progress
                        }
                    }
                )
                
                print("[NewMatchView] OCR completed. Text length: \(text.count)")
                
                await MainActor.run {
                    ocrText = text
                    ocrProgress = 0.5
                }
                
                // Parse profile with AI
                print("[NewMatchView] Starting AI parsing...")
                let apiClient = APIClient.shared
                
                // Add a timeout wrapper
                let parseResponse = try await withTimeout(seconds: 90) {
                    try await apiClient.parseProfile(ocrText: text)
                }
                
                print("[NewMatchView] AI parsing completed successfully")
                
                await MainActor.run {
                    ocrProgress = 1.0
                    parsedProfile = parseResponse.toMatchProfile(rawOcrText: text)
                    currentStep = .reviewProfile
                    isProcessing = false
                }
            } catch is TimeoutError {
                print("[NewMatchView] Request timed out")
                await MainActor.run {
                    errorMessage = "Request timed out. The server took too long to respond. Please try again."
                    currentStep = .selectImages
                    isProcessing = false
                }
            } catch {
                print("[NewMatchView] Processing error: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to process images: \(error.localizedDescription)"
                    currentStep = .selectImages
                    isProcessing = false
                }
            }
        }
    }
    
    private func generateMessages() {
        guard let profile = parsedProfile,
              let userProfile = appState.userProfile else { return }
        
        currentStep = .processing
        ocrProgress = 0
        
        Task {
            do {
                let apiClient = APIClient.shared
                let messages = try await apiClient.generateMessages(
                    userProfile: userProfile,
                    matchProfile: profile
                )
                
                let messageSet = GeneratedMessageSet(
                    matchId: profile.matchId,
                    messages: messages,
                    toneUsed: userProfile.voiceTone
                )
                
                await MainActor.run {
                    generatedMessages = messageSet
                    currentStep = .viewMessages
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate messages: \(error.localizedDescription)"
                    currentStep = .reviewProfile
                }
            }
        }
    }
    
    private func regenerateMessages() {
        generateMessages()
    }
    
    private func saveMatchAndDismiss() {
        guard let profile = parsedProfile,
              let messages = generatedMessages else { return }
        
        appState.addMatch(profile)
        MatchStore.shared.saveMessages(messages)
        MatchStore.shared.saveLastSelectedMatch(profile.matchId)
        
        dismiss()
    }
    
    private func resetFlow() {
        selectedItems = []
        selectedImages = []
        ocrText = nil
        parsedProfile = nil
        generatedMessages = nil
        currentStep = .selectImages
    }
}

struct ImageSelectionView: View {
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    let onProcess: () -> Void
    var onVideoSelected: ((URL) -> Void)?
    
    @State private var selectedVideoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 24) {
            if selectedImages.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Brand.accentLight)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(Brand.accent)
                    }
                    
                    Text("Import Dating Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Brand.textPrimary)
                    
                    Text("Choose screenshots or a screen recording\nof their dating profile")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            } else {
                // Selected images grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button(action: { removeImage(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                }
                                .padding(8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Buttons
            VStack(spacing: 12) {
                // Screen Recording option (recommended)
                PhotosPicker(
                    selection: $selectedVideoItem,
                    matching: .videos
                ) {
                    HStack {
                        Image(systemName: "record.circle")
                        Text("Import Screen Recording")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Brand.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                }
                .onChange(of: selectedVideoItem) { _, newItem in
                    if let item = newItem {
                        loadVideo(from: item)
                    }
                }
                
                // Screenshots option
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text(selectedImages.isEmpty ? "Select Screenshots" : "Add More Screenshots")
                    }
                    .font(.headline)
                    .foregroundStyle(Brand.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Brand.accentLight)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                }
                .onChange(of: selectedItems) { _, newItems in
                    loadImages(from: newItems)
                }
                
                if !selectedImages.isEmpty {
                    Button(action: onProcess) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Process Screenshots")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Brand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                    }
                }
                
                // Pro tip
                if selectedImages.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Pro tip: Screen recordings capture the full profile!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                selectedImages = images
            }
        }
    }
    
    private func loadVideo(from item: PhotosPickerItem) {
        print("[ImageSelectionView] 🎥 Starting video load...")
        Task {
            do {
                print("[ImageSelectionView] 🎥 Loading transferable Movie type...")
                if let movie = try await item.loadTransferable(type: Movie.self) {
                    print("[ImageSelectionView] ✅ Video loaded successfully!")
                    print("[ImageSelectionView] Video URL: \(movie.url)")
                    print("[ImageSelectionView] Video exists: \(FileManager.default.fileExists(atPath: movie.url.path()))")
                    
                    if FileManager.default.fileExists(atPath: movie.url.path()) {
                        let attrs = try? FileManager.default.attributesOfItem(atPath: movie.url.path())
                        let fileSize = attrs?[.size] as? UInt64 ?? 0
                        print("[ImageSelectionView] Video file size: \(fileSize) bytes")
                    }
                    
                    await MainActor.run {
                        onVideoSelected?(movie.url)
                    }
                } else {
                    print("[ImageSelectionView] ❌ Movie.loadTransferable returned nil")
                }
            } catch {
                print("[ImageSelectionView] ❌ Failed to load video: \(error)")
                print("[ImageSelectionView] Error type: \(type(of: error))")
                print("[ImageSelectionView] Error details: \((error as NSError).domain) code: \((error as NSError).code)")
            }
        }
    }
    
    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
        if index < selectedItems.count {
            selectedItems.remove(at: index)
        }
    }
}

// MARK: - Movie Transferable

struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "movie.\(received.file.pathExtension)")
            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Timeout Helper

struct TimeoutError: Error {}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

#Preview {
    NavigationStack {
        NewMatchView()
            .environmentObject(AppState())
    }
}
