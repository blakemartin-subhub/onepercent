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
                            .fill(LinearGradient(colors: [.pink.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 36))
                            .foregroundStyle(.pink)
                    }
                    
                    Text("Import Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Upload your dating profile for\npersonalized message generation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Upload options
                VStack(spacing: 16) {
                    // Screen recording option
                    PhotosPicker(
                        selection: $selectedVideoItem,
                        matching: .videos
                    ) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.pink.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "record.circle")
                                    .font(.title2)
                                    .foregroundStyle(.pink)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screen Recording")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Record scrolling through your profile")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Screenshots option
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screenshots")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Select screenshots of your profile")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                
                // Processing state
                switch processingState {
                case .idle:
                    EmptyView()
                    
                case .processing(let progress):
                    VStack(spacing: 12) {
                        ProgressView(value: progress)
                            .tint(.pink)
                        
                        Text("Analyzing your profile...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    
                case .success:
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Profile imported successfully!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("AI will use your bio, prompts, and photos to write authentic messages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    
                case .error(let message):
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(message)
                                .font(.subheadline)
                        }
                        
                        Button("Try Again") {
                            processingState = .idle
                        }
                        .font(.caption)
                        .foregroundStyle(.pink)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why import your profile?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BenefitRow(icon: "sparkles", text: "Messages match your personality")
                        BenefitRow(icon: "person.fill", text: "References your actual interests")
                        BenefitRow(icon: "quote.bubble", text: "Uses your bio and prompt answers")
                        BenefitRow(icon: "wand.and.stars", text: "More authentic conversation starters")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                
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
                    
                    if case .success = processingState {
                        // Already shows continue
                    } else {
                        Text("You can import your profile later in settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
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
        
        Task {
            do {
                // Load video data
                guard let video = try await item.loadTransferable(type: VideoTransferable.self) else {
                    throw ImportError.loadFailed
                }
                
                // Extract text using OCR
                let videoService = VideoProcessingService()
                let text = try await videoService.extractTextFromVideo(at: video.url) { progress, _ in
                    Task { @MainActor in
                        processingState = .processing(progress: progress)
                    }
                }
                
                await MainActor.run {
                    extractedText = text
                    profileContext = text
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
        
        Task {
            do {
                var allText = ""
                let ocrService = OCRService()
                
                for (index, item) in items.enumerated() {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }
                    
                    let text = try await ocrService.recognizeText(in: image)
                    allText += text + "\n\n"
                    
                    await MainActor.run {
                        processingState = .processing(progress: Double(index + 1) / Double(items.count))
                    }
                }
                
                await MainActor.run {
                    extractedText = allText
                    profileContext = allText
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
                .foregroundStyle(.pink)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
            
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
