import SwiftUI
import SharedKit
import PhotosUI

struct ProfileImportView: View {
    @Binding var profileContext: String?
    let onContinue: () -> Void
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var processingState: ImportState = .idle
    @State private var extractedText = ""
    
    enum ImportState {
        case idle
        case processing(progress: Double)
        case success
        case error(String)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Brand.accentLight)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 32))
                            .foregroundStyle(Brand.accent)
                    }
                    
                    Text("Import Your Profile")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                    
                    Text("Upload your dating profile for\npersonalized message generation")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Upload options
                VStack(spacing: 12) {
                    // Screen recording option
                    PhotosPicker(
                        selection: $selectedVideoItem,
                        matching: .videos
                    ) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Brand.accentLight)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "record.circle")
                                    .font(.title3)
                                    .foregroundStyle(Brand.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Screen Recording")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.textPrimary)
                                
                                Text("Record scrolling through your profile")
                                    .font(.caption)
                                    .foregroundStyle(Brand.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textMuted)
                        }
                        .padding(16)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusLarge))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                    
                    // Screenshots option
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Brand.accentLight)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title3)
                                    .foregroundStyle(Brand.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Screenshots")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.textPrimary)
                                
                                Text("Select screenshots of your profile")
                                    .font(.caption)
                                    .foregroundStyle(Brand.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textMuted)
                        }
                        .padding(16)
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusLarge))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                
                // Processing state
                Group {
                    switch processingState {
                    case .idle:
                        EmptyView()
                        
                    case .processing(let progress):
                        VStack(spacing: 12) {
                            ProgressView(value: progress)
                                .tint(Brand.accent)
                            
                            Text("Analyzing your profile...")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .padding(16)
                        .background(Brand.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                        .padding(.horizontal, 20)
                        
                    case .success:
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Brand.success)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Profile imported!")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.textPrimary)
                                
                                Text("AI will use this for personalized messages")
                                    .font(.caption)
                                    .foregroundStyle(Brand.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Brand.success.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                        .padding(.horizontal, 20)
                        
                    case .error(let message):
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Brand.warning)
                                Text(message)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.textPrimary)
                            }
                            
                            Button("Try Again") {
                                processingState = .idle
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Brand.accent)
                        }
                        .padding(16)
                        .background(Brand.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                        .padding(.horizontal, 20)
                    }
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why import your profile?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BenefitRow(icon: "sparkles", text: "Messages match your personality")
                        BenefitRow(icon: "person.fill", text: "References your actual interests")
                        BenefitRow(icon: "quote.bubble", text: "Uses your bio and prompt answers")
                        BenefitRow(icon: "wand.and.stars", text: "More authentic conversation starters")
                    }
                }
                .padding(16)
                .background(Brand.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Continue buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if case .success = processingState {
                            profileContext = extractedText
                        }
                        onContinue()
                    }) {
                        HStack {
                            if case .success = processingState {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            } else {
                                Text("Skip for Now")
                            }
                        }
                    }
                    .buttonStyle(.brandPrimary)
                    
                    if case .success = processingState {
                        // Already shows continue
                    } else {
                        Text("You can import your profile later in settings")
                            .font(.caption)
                            .foregroundStyle(Brand.textMuted)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Brand.background)
        .onChange(of: selectedVideoItem) { _, newItem in
            if let item = newItem {
                processVideo(item)
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            if !newItems.isEmpty {
                processScreenshots(newItems)
            }
        }
    }
    
    private func processVideo(_ item: PhotosPickerItem) {
        processingState = .processing(progress: 0)
        
        // Auto-advance after 2.5 seconds while OCR continues in background
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Only advance if still processing (not error)
            if case .processing = processingState {
                onContinue()
            }
        }
        
        // Continue OCR in background
        Task {
            do {
                guard let video = try await item.loadTransferable(type: VideoTransferable.self) else {
                    throw ImportError.loadFailed
                }
                
                let videoService = VideoProcessingService()
                let text = try await videoService.extractTextFromVideo(at: video.url) { progress, _ in
                    Task { @MainActor in
                        // Only update progress if still on this view
                        if case .processing = processingState {
                            processingState = .processing(progress: progress)
                        }
                    }
                }
                
                await MainActor.run {
                    extractedText = text
                    profileContext = text  // Updates binding even if user moved to next step
                    processingState = .success
                    selectedVideoItem = nil
                }
                
            } catch {
                await MainActor.run {
                    processingState = .error("Unable to process video")
                    selectedVideoItem = nil
                }
            }
        }
    }
    
    private func processScreenshots(_ items: [PhotosPickerItem]) {
        processingState = .processing(progress: 0)
        
        // Auto-advance after 2.5 seconds while OCR continues in background
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Only advance if still processing (not error)
            if case .processing = processingState {
                onContinue()
            }
        }
        
        // Continue OCR in background
        Task {
            do {
                var allText = ""
                let ocrService = OCRService()
                
                for (index, item) in items.enumerated() {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }
                    
                    let text = try await ocrService.recognizeText(from: [image]) { _ in }
                    allText += text + "\n\n"
                    
                    await MainActor.run {
                        // Only update progress if still on this view
                        if case .processing = processingState {
                            processingState = .processing(progress: Double(index + 1) / Double(items.count))
                        }
                    }
                }
                
                await MainActor.run {
                    extractedText = allText
                    profileContext = allText  // Updates binding even if user moved to next step
                    processingState = .success
                    selectedItems = []
                }
                
            } catch {
                await MainActor.run {
                    processingState = .error("Unable to process screenshots")
                    selectedItems = []
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Brand.accent)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(Brand.textPrimary)
            
            Spacer()
        }
    }
}

struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

enum ImportError: Error {
    case loadFailed
}

#Preview {
    ProfileImportView(profileContext: .constant(nil), onContinue: {})
}
