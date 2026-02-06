import SwiftUI
import SharedKit
import PhotosUI

struct ProfileImportView: View {
    @Binding var profileContext: String?
    let step: Int
    let onContinue: () -> Void
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var processingState: ImportState = .idle
    @State private var extractedText = ""
    
    // Entrance animation states
    @State private var headerVisible = false
    @State private var optionsVisible = false
    @State private var benefitsVisible = false
    @State private var buttonVisible = false
    
    enum ImportState: Equatable {
        case idle
        case processing(progress: Double)
        case success
        case error(String)
    }
    
    private var isSuccess: Bool {
        if case .success = processingState { return true }
        return false
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
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 30)
                .blur(radius: headerVisible ? 0 : 8)
                
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
                .opacity(optionsVisible ? 1 : 0)
                .offset(y: optionsVisible ? 0 : 30)
                .blur(radius: optionsVisible ? 0 : 6)
                
                // Processing state
                Group {
                    switch processingState {
                    case .idle:
                        EmptyView()
                        
                    case .processing(let progress):
                        VStack(spacing: 12) {
                            ProgressView(value: progress)
                                .tint(Brand.accent)
                                .animation(.easeInOut(duration: 0.35), value: progress)
                            
                            Text("Analyzing your profile...")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .padding(16)
                        .background(Brand.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .offset(y: 12)))
                        
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
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        
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
                                withAnimation(.smooth(duration: 0.45)) {
                                    processingState = .idle
                                }
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Brand.accent)
                        }
                        .padding(16)
                        .background(Brand.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .offset(y: 12)))
                    }
                }
                .animation(.smooth(duration: 0.4), value: processingState)
                
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
                .opacity(benefitsVisible ? 1 : 0)
                .offset(y: benefitsVisible ? 0 : 30)
                .blur(radius: benefitsVisible ? 0 : 6)
                
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
                            if isSuccess {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            } else {
                                Text("Skip for Now")
                            }
                        }
                        .contentTransition(.interpolate)
                    }
                    .buttonStyle(.brandPrimary)
                    .animation(.smooth(duration: 0.35), value: isSuccess)
                    
                    if !isSuccess {
                        Text("You can import your profile later in settings")
                            .font(.caption)
                            .foregroundStyle(Brand.textMuted)
                            .transition(.opacity.combined(with: .offset(y: 6)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(buttonVisible ? 1 : 0)
                .offset(y: buttonVisible ? 0 : 30)
                .blur(radius: buttonVisible ? 0 : 6)
                .animation(.smooth(duration: 0.35), value: isSuccess)
            }
        }
        .background(Brand.background.ignoresSafeArea())
        .onAppear {
            // Store extracted text but DON'T set processingState yet — let it animate in
            if profileContext != nil {
                extractedText = profileContext ?? ""
            }
            if step == 1 {
                startEntranceAnimations()
                // Stagger success banner into the entrance sequence
                if profileContext != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.smooth(duration: 0.45)) {
                            processingState = .success
                        }
                    }
                }
            }
        }
        .onChange(of: step) { _, newValue in
            if newValue == 1 {
                let shouldRestoreSuccess = processingState == .success || profileContext != nil
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    headerVisible = false
                    optionsVisible = false
                    benefitsVisible = false
                    buttonVisible = false
                    if shouldRestoreSuccess {
                        processingState = .idle
                    }
                }
                if profileContext != nil {
                    extractedText = profileContext ?? ""
                }
                startEntranceAnimations()
                // Re-animate success banner as part of the entrance stagger
                if shouldRestoreSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.smooth(duration: 0.45)) {
                            processingState = .success
                        }
                    }
                }
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
    
    private func startEntranceAnimations() {
        // Separate asyncAfter calls ensure each animation runs in its own execution context,
        // preventing the TabView's .animation(.easeInOut) from interfering with stagger
        let base: TimeInterval = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + base) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                headerVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                optionsVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)) {
                benefitsVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.45) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                buttonVisible = true
            }
        }
    }
    
    private func processVideo(_ item: PhotosPickerItem) {
        withAnimation(.smooth(duration: 0.45)) {
            processingState = .processing(progress: 0)
        }
        
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
                            withAnimation(.smooth(duration: 0.3)) {
                                processingState = .processing(progress: progress)
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    extractedText = text
                    profileContext = text  // Updates binding even if user moved to next step
                    withAnimation(.smooth(duration: 0.45)) {
                        processingState = .success
                    }
                    selectedVideoItem = nil
                }
                
            } catch {
                await MainActor.run {
                    withAnimation(.smooth(duration: 0.45)) {
                        processingState = .error("Unable to process video")
                    }
                    selectedVideoItem = nil
                }
            }
        }
    }
    
    private func processScreenshots(_ items: [PhotosPickerItem]) {
        withAnimation(.smooth(duration: 0.45)) {
            processingState = .processing(progress: 0)
        }
        
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
                            withAnimation(.smooth(duration: 0.3)) {
                                processingState = .processing(progress: Double(index + 1) / Double(items.count))
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    extractedText = allText
                    profileContext = allText  // Updates binding even if user moved to next step
                    withAnimation(.smooth(duration: 0.45)) {
                        processingState = .success
                    }
                    selectedItems = []
                }
                
            } catch {
                await MainActor.run {
                    withAnimation(.smooth(duration: 0.45)) {
                        processingState = .error("Unable to process screenshots")
                    }
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
    ProfileImportView(profileContext: .constant(nil), step: 1, onContinue: {})
}
