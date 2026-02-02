import SwiftUI
import PhotosUI
import SharedKit
import AVFoundation

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
        // Check for video first (screen recording)
        if let videoURL = MatchStore.shared.getShareInboxVideoURL() {
            MatchStore.shared.clearShareInbox()
            startVideoProcessing(videoURL: videoURL)
            return
        }
        
        // Otherwise load images
        let urls = MatchStore.shared.getShareInboxImageURLs()
        for url in urls {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
        MatchStore.shared.clearShareInbox()
        
        if !selectedImages.isEmpty {
            startProcessing()
        }
    }
    
    private func startVideoProcessing(videoURL: URL) {
        currentStep = .processing
        isProcessing = true
        ocrProgress = 0
        
        Task {
            do {
                // Process video frames
                let videoService = VideoProcessingService()
                let text = try await videoService.extractTextFromVideo(at: videoURL) { progress, status in
                    Task { @MainActor in
                        ocrProgress = progress * 0.5
                    }
                }
                
                await MainActor.run {
                    ocrText = text
                    ocrProgress = 0.5
                }
                
                // Parse profile with AI
                let apiClient = APIClient.shared
                let parseResponse = try await apiClient.parseProfile(ocrText: text)
                
                await MainActor.run {
                    ocrProgress = 1.0
                    parsedProfile = parseResponse.toMatchProfile(rawOcrText: text)
                    currentStep = .reviewProfile
                    isProcessing = false
                }
            } catch {
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
                let ocrService = OCRService()
                let text = try await ocrService.recognizeText(
                    from: selectedImages,
                    progressHandler: { progress in
                        Task { @MainActor in
                            ocrProgress = progress * 0.5 // OCR is 50% of progress
                        }
                    }
                )
                
                await MainActor.run {
                    ocrText = text
                    ocrProgress = 0.5
                }
                
                // Parse profile with AI
                let apiClient = APIClient.shared
                let parseResponse = try await apiClient.parseProfile(ocrText: text)
                
                await MainActor.run {
                    ocrProgress = 1.0
                    parsedProfile = parseResponse.toMatchProfile(rawOcrText: text)
                    currentStep = .reviewProfile
                    isProcessing = false
                }
            } catch {
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
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("Import Dating Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose screenshots or a screen recording\nof their dating profile")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
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
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
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
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        Task {
            do {
                if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                    await MainActor.run {
                        onVideoSelected?(movie.url)
                    }
                }
            } catch {
                print("Failed to load video: \(error)")
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

/// Transferable wrapper for video files
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            // Copy to temp location
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return VideoTransferable(url: tempURL)
        }
    }
}

#Preview {
    NavigationStack {
        NewMatchView()
            .environmentObject(AppState())
    }
}
