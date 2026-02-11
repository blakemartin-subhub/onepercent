import SwiftUI
import UIKit
import SharedKit

// MARK: - ProfileSetupView

struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let step: Int
    let onComplete: () -> Void
    
    // MARK: - Core State
    
    @State private var name = ""
    @State private var selectedTones: Set<VoiceTone> = [.playful]
    @State private var selectedEmojiStyle: EmojiStyle = .light
    @State private var selectedActivities: Set<String> = []
    @State private var selectedNationalities: Set<String> = []
    @State private var selectedFirstDateGoal: FirstDateGoal? = nil
    
    // MARK: - Template-Aligned State
    
    @State private var canCook = false
    @State private var selectedCookingLevel: CookingLevel = .beginner
    @State private var selectedCuisines: Set<String> = []
    @State private var playsMusic = false
    @State private var selectedInstrumentLevel: InstrumentLevel = .learning
    @State private var selectedInstruments: Set<String> = []
    @State private var selectedOutdoorActivities: Set<String> = []
    @State private var localSpots: [String] = []
    @State private var newSpotText = ""
    
    // MARK: - "Other" Entry State
    
    @State private var showNationalityOther = false
    @State private var nationalityOtherText = ""
    @State private var showActivityOther = false
    @State private var activityOtherText = ""
    @FocusState private var nationalityOtherFocused: Bool
    @FocusState private var activityOtherFocused: Bool
    @FocusState private var spotFieldFocused: Bool
    
    // MARK: - Entrance Animation
    
    @State private var headerVisible = false
    @State private var nameVisible = false
    @State private var formVisible = false
    @State private var buttonVisible = false
    @State private var buttonReady = false
    
    // MARK: - Elastic Scroll
    
    @State private var spread: CGFloat = 0
    @State private var decayTask: Task<Void, Never>?
    
    // MARK: - Data Constants
    
    private let onboardingNationalities: [Nationality] = [
        .american, .italian, .mexican, .irish, .indian,
        .korean, .greek, .japanese, .brazilian, .french
    ]
    
    private let onboardingActivities: [Activity] = [
        .cooking, .hiking, .fitness, .travel, .music,
        .outdoors, .sports, .photography, .dancing, .nightlife,
        .surfing, .snowboarding, .skiing, .rockClimbing, .yoga,
        .wine, .coffee, .foodie, .movies, .reading,
        .gaming, .art
    ]
    
    private let cuisineOptions = [
        "Italian", "Mexican", "Korean", "French",
        "Spanish", "Japanese", "Thai", "Indian"
    ]
    
    private let instrumentOptions = [
        "Guitar", "Piano", "Drums", "Voice",
        "Violin", "Bass", "DJ", "Ukulele"
    ]
    
    private let outdoorOptions = [
        "Hiking", "Surfing", "Skiing", "Snowboarding",
        "Rock Climbing", "Kayaking", "Trail Running", "Mountain Biking"
    ]
    
    // MARK: - Unique Quality Counter
    
    private var uniqueQualityCount: Int {
        var count = 0
        count += selectedNationalities.count
        count += selectedActivities.count
        if canCook { count += 1 }
        count += selectedCuisines.count
        count += selectedInstruments.count
        count += selectedOutdoorActivities.count
        count += localSpots.count
        return count
    }
    
    private var qualityColor: Color {
        switch uniqueQualityCount {
        case 0..<5: return Brand.textMuted
        case 5...10: return Brand.error
        case 11...15: return Brand.warning
        default: return Brand.success
        }
    }
    
    private var qualityMessage: String {
        switch uniqueQualityCount {
        case 0..<5: return "Add qualities for better messages"
        case 5...10: return "Try to add some more..."
        case 11...15: return "This is rizz territory"
        default: return "Yep... You're a catch"
        }
    }
    
    // MARK: - Validation
    
    private var isFormComplete: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Section Header Helper
    
    @ViewBuilder
    private func sectionTitle(_ title: String, subtitle: String? = nil, isComplete: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.textPrimary)
                
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Brand.success)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isComplete)
            
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 28) {
                    // Header
                    headerSection
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 30)
                    
                    // Name
                    nameSection
                        .opacity(nameVisible ? 1 : 0)
                        .offset(y: nameVisible ? 0 : 30)
                    
                    // All form sections
                    Group {
                        nationalitySection
                        activitySection
                        voiceToneSection
                        emojiStyleSection
                        firstDateGoalSection
                        cookingSection
                        musicSection
                        outdoorSection
                        localSpotsSection
                        qualityCounterView
                    }
                    .opacity(formVisible ? 1 : 0)
                    .offset(y: formVisible ? 0 : 30)
                }
                .padding(.bottom, 120)
                .background(
                    ScrollVelocityTracker { delta in
                        guard abs(delta) > 0.3 && abs(delta) < 80 else { return }
                        let target = min(abs(delta) * 0.8, 18)
                        spread += (target - spread) * 0.25
                        decayTask?.cancel()
                        decayTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(50))
                            guard !Task.isCancelled else { return }
                            withAnimation(.spring(response: 0.9, dampingFraction: 0.45)) {
                                spread = 0
                            }
                        }
                    }
                )
            }
            
            // Sticky bottom button
            stickyBottomButton
                .opacity(buttonVisible ? 1 : 0)
                .offset(y: buttonVisible ? 0 : 30)
        }
        .background(Brand.background.ignoresSafeArea())
        .onAppear {
            restoreFromProfile()
            if step == 1 { startEntranceAnimations() }
        }
        .onDisappear { saveToProfile() }
        .onChange(of: step) { _, newValue in
            if newValue == 1 {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    headerVisible = false
                    nameVisible = false
                    formVisible = false
                    buttonVisible = false
                    buttonReady = false
                }
                startEntranceAnimations()
            }
        }
        .onChange(of: isFormComplete) { _, isComplete in
            if isComplete {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { buttonReady = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { buttonReady = false }
                }
            }
        }
    }
}

// MARK: - Section Views

private extension ProfileSetupView {
    
    var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Brand.accentLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 32))
                    .foregroundStyle(Brand.accent)
            }
            .elasticSpread(spread: spread)
            
            Text("Your Profile")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .elasticSpread(spread: spread)
            
            Text("Help the AI write messages\nthat sound like you")
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .elasticSpread(spread: spread)
        }
        .padding(.top, 32)
    }
    
    var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Your First Name", isComplete: !name.trimmingCharacters(in: .whitespaces).isEmpty)
                .elasticSpread(spread: spread)
            
            TextField("Enter your name", text: $name)
                .textFieldStyle(.plain)
                .foregroundStyle(Brand.textPrimary)
                .tint(Brand.accent)
                .padding(16)
                .background(Brand.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusMedium)
                        .stroke(Brand.border, lineWidth: 1)
                )
                .elasticSpread(spread: spread)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Nationality
    
    var nationalitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(
                "Your Background",
                subtitle: "Select all that apply — helps personalize messages",
                isComplete: !selectedNationalities.isEmpty
            )
            .elasticSpread(spread: spread)
            
            FlowLayoutView(spacing: 8) {
                ForEach(onboardingNationalities, id: \.rawValue) { nationality in
                    PillButton(
                        text: nationality.rawValue,
                        isSelected: selectedNationalities.contains(nationality.rawValue)
                    ) {
                        toggleSet(&selectedNationalities, value: nationality.rawValue)
                    }
                    .elasticSpread(spread: spread)
                }
                
                // Custom entries as removable pills
                let predefined = Set(onboardingNationalities.map(\.rawValue))
                ForEach(Array(selectedNationalities.filter { !predefined.contains($0) }), id: \.self) { custom in
                    PillButton(text: custom, isSelected: true) {
                        selectedNationalities.remove(custom)
                    }
                    .elasticSpread(spread: spread)
                }
                
                // "Other" pill
                PillButton(text: "Other", isSelected: showNationalityOther) {
                    showNationalityOther.toggle()
                    if showNationalityOther { nationalityOtherFocused = true }
                }
                .elasticSpread(spread: spread)
            }
            
            if showNationalityOther {
                TextField("Type your background", text: $nationalityOtherText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Brand.textPrimary)
                    .tint(Brand.accent)
                    .focused($nationalityOtherFocused)
                    .padding(12)
                    .background(Brand.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.radiusMedium)
                            .stroke(Brand.accent, lineWidth: 1)
                    )
                    .onSubmit {
                        let trimmed = nationalityOtherText.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            selectedNationalities.insert(trimmed)
                            nationalityOtherText = ""
                        }
                    }
                    .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.25), value: showNationalityOther)
    }
    
    // MARK: Activities
    
    var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(
                "What You Like To Do",
                subtitle: "Select all that apply",
                isComplete: !selectedActivities.isEmpty
            )
            .elasticSpread(spread: spread)
            
            FlowLayoutView(spacing: 8) {
                ForEach(onboardingActivities, id: \.rawValue) { activity in
                    PillButton(
                        text: activity.rawValue,
                        isSelected: selectedActivities.contains(activity.rawValue)
                    ) {
                        toggleSet(&selectedActivities, value: activity.rawValue)
                    }
                    .elasticSpread(spread: spread)
                }
                
                // Custom entries as removable pills
                let predefined = Set(onboardingActivities.map(\.rawValue))
                ForEach(Array(selectedActivities.filter { !predefined.contains($0) }), id: \.self) { custom in
                    PillButton(text: custom, isSelected: true) {
                        selectedActivities.remove(custom)
                    }
                    .elasticSpread(spread: spread)
                }
                
                // "Other" pill
                PillButton(text: "Other", isSelected: showActivityOther) {
                    showActivityOther.toggle()
                    if showActivityOther { activityOtherFocused = true }
                }
                .elasticSpread(spread: spread)
            }
            
            if showActivityOther {
                TextField("Type your activity", text: $activityOtherText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Brand.textPrimary)
                    .tint(Brand.accent)
                    .focused($activityOtherFocused)
                    .padding(12)
                    .background(Brand.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.radiusMedium)
                            .stroke(Brand.accent, lineWidth: 1)
                    )
                    .onSubmit {
                        let trimmed = activityOtherText.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            selectedActivities.insert(trimmed)
                            activityOtherText = ""
                        }
                    }
                    .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.25), value: showActivityOther)
    }
    
    // MARK: Voice Tones
    
    var voiceToneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(
                "Your Vibe",
                subtitle: "Select one or more message styles",
                isComplete: !selectedTones.isEmpty
            )
            .elasticSpread(spread: spread)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(VoiceTone.allCases, id: \.self) { tone in
                    ToneButton(tone: tone, isSelected: selectedTones.contains(tone)) {
                        if selectedTones.contains(tone) {
                            if selectedTones.count > 1 { selectedTones.remove(tone) }
                        } else {
                            selectedTones.insert(tone)
                        }
                    }
                    .elasticSpread(spread: spread)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Emoji Style
    
    var emojiStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Emoji Style", isComplete: true)
                .elasticSpread(spread: spread)
            
            HStack(spacing: 10) {
                ForEach(EmojiStyle.allCases, id: \.self) { style in
                    EmojiStyleButton(style: style, isSelected: selectedEmojiStyle == style) {
                        selectedEmojiStyle = style
                    }
                    .elasticSpread(spread: spread)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: First Date Goal
    
    var firstDateGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(
                "Preferred First Date",
                subtitle: "Messages will subtly lead toward this",
                isComplete: selectedFirstDateGoal != nil
            )
            .elasticSpread(spread: spread)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FirstDateGoal.allCases, id: \.self) { goal in
                    ToneButton(text: goal.displayName, isSelected: selectedFirstDateGoal == goal) {
                        selectedFirstDateGoal = goal
                    }
                    .elasticSpread(spread: spread)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Cooking
    
    var cookingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $canCook) {
                Text("Do you cook?")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.textPrimary)
            }
            .tint(Brand.accent)
            .elasticSpread(spread: spread)
            
            if canCook {
                VStack(alignment: .leading, spacing: 14) {
                    // Cuisine types
                    Text("What do you cook?")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    
                    FlowLayoutView(spacing: 8) {
                        ForEach(cuisineOptions, id: \.self) { cuisine in
                            PillButton(text: cuisine, isSelected: selectedCuisines.contains(cuisine)) {
                                toggleSet(&selectedCuisines, value: cuisine)
                            }
                        }
                    }
                    
                    // Cooking level
                    Text("Cooking Level")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(CookingLevel.allCases, id: \.self) { level in
                            LevelButton(
                                text: level.displayName,
                                isSelected: selectedCookingLevel == level
                            ) {
                                selectedCookingLevel = level
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.3), value: canCook)
    }
    
    // MARK: Music
    
    var musicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $playsMusic) {
                Text("Play music?")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.textPrimary)
            }
            .tint(Brand.accent)
            .elasticSpread(spread: spread)
            
            if playsMusic {
                VStack(alignment: .leading, spacing: 14) {
                    // Instruments
                    Text("What do you play?")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    
                    FlowLayoutView(spacing: 8) {
                        ForEach(instrumentOptions, id: \.self) { instrument in
                            PillButton(text: instrument, isSelected: selectedInstruments.contains(instrument)) {
                                toggleSet(&selectedInstruments, value: instrument)
                            }
                        }
                    }
                    
                    // Instrument level
                    Text("Skill Level")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(InstrumentLevel.allCases, id: \.self) { level in
                            LevelButton(
                                text: level.displayName,
                                isSelected: selectedInstrumentLevel == level
                            ) {
                                selectedInstrumentLevel = level
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.3), value: playsMusic)
    }
    
    // MARK: Outdoor Activities
    
    var outdoorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(
                "Outdoor Activities",
                subtitle: "Select any that apply",
                isComplete: !selectedOutdoorActivities.isEmpty
            )
            .elasticSpread(spread: spread)
            
            FlowLayoutView(spacing: 8) {
                ForEach(outdoorOptions, id: \.self) { activity in
                    PillButton(
                        text: activity,
                        isSelected: selectedOutdoorActivities.contains(activity)
                    ) {
                        toggleSet(&selectedOutdoorActivities, value: activity)
                    }
                    .elasticSpread(spread: spread)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Local Spots
    
    var localSpotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(
                "Know any great local spots?",
                subtitle: "Share your favorite date spots"
            )
            .elasticSpread(spread: spread)
            
            // Added spots as removable pills
            if !localSpots.isEmpty {
                FlowLayoutView(spacing: 8) {
                    ForEach(Array(localSpots.enumerated()), id: \.offset) { index, spot in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            localSpots.remove(at: index)
                        } label: {
                            HStack(spacing: 4) {
                                Text(spot)
                                Image(systemName: "xmark")
                                    .font(.caption2.weight(.bold))
                            }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Brand.accent)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Input field
            HStack(spacing: 10) {
                TextField("e.g. That rooftop bar downtown", text: $newSpotText)
                    .textFieldStyle(.plain)
                    .focused($spotFieldFocused)
                    .foregroundStyle(Brand.textPrimary)
                    .tint(Brand.accent)
                    .padding(12)
                    .background(Brand.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.radiusMedium)
                            .stroke(Brand.border, lineWidth: 1)
                    )
                    .onSubmit { addLocalSpot() }
                
                Button(action: addLocalSpot) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Brand.accent)
                }
                .disabled(newSpotText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newSpotText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.35 : 1)
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.25), value: localSpots.count)
    }
    
    // MARK: Quality Counter
    
    var qualityCounterView: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(qualityColor)
                    .frame(width: 10, height: 10)
                
                Text("\(uniqueQualityCount) Unique Qualities")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(qualityColor)
            }
            
            Text(qualityMessage)
                .font(.caption)
                .foregroundStyle(qualityColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Brand.radiusMedium)
                .stroke(qualityColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.3), value: uniqueQualityCount)
    }
    
    // MARK: Sticky Bottom Button
    
    var stickyBottomButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Brand.background.opacity(0), Brand.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)
            .allowsHitTesting(false)
            
            VStack(spacing: 10) {
                if !isFormComplete {
                    Text("Enter your name to continue")
                        .font(.caption)
                        .foregroundStyle(Brand.textMuted)
                        .transition(.opacity)
                }
                
                Button(action: saveAndContinue) {
                    HStack {
                        Text("Start Using Keyboard")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.brandPrimary)
                .disabled(!isFormComplete)
                .opacity(isFormComplete ? 1 : 0.5)
                .scaleEffect(buttonReady ? 1.06 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: buttonReady)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
            .background(Brand.background)
            .animation(.easeInOut(duration: 0.3), value: isFormComplete)
        }
    }
}

// MARK: - Actions

private extension ProfileSetupView {
    
    func toggleSet<T: Hashable>(_ set: inout Set<T>, value: T) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
    
    func addLocalSpot() {
        let trimmed = newSpotText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        localSpots.append(trimmed)
        newSpotText = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func startEntranceAnimations() {
        let base: TimeInterval = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + base) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                headerVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.12) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                nameVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.24) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                formVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.38) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                buttonVisible = true
            }
        }
    }
    
    func restoreFromProfile() {
        name = profile.displayName
        if !profile.voiceTones.isEmpty {
            selectedTones = Set(profile.voiceTones)
        }
        selectedEmojiStyle = profile.emojiStyle
        selectedActivities = Set(profile.activities)
        selectedNationalities = Set(profile.nationalities)
        selectedFirstDateGoal = profile.firstDateGoal
        
        // Template-aligned fields
        canCook = profile.canCook ?? false
        selectedCookingLevel = profile.cookingLevel ?? .beginner
        selectedCuisines = Set(profile.cuisineTypes ?? [])
        playsMusic = profile.playsMusic ?? false
        selectedInstrumentLevel = profile.instrumentLevel ?? .learning
        selectedInstruments = Set(profile.instruments ?? [])
        selectedOutdoorActivities = Set(profile.outdoorActivities ?? [])
        localSpots = profile.localSpots ?? []
    }
    
    func saveToProfile() {
        profile.displayName = name.trimmingCharacters(in: .whitespaces)
        profile.voiceTone = Array(selectedTones).first ?? .playful
        profile.voiceTones = Array(selectedTones)
        profile.emojiStyle = selectedEmojiStyle
        profile.activities = Array(selectedActivities)
        profile.nationalities = Array(selectedNationalities)
        profile.firstDateGoal = selectedFirstDateGoal
        
        // Template-aligned fields
        profile.canCook = canCook
        profile.cookingLevel = canCook ? selectedCookingLevel : nil
        profile.cuisineTypes = canCook && !selectedCuisines.isEmpty ? Array(selectedCuisines) : nil
        profile.playsMusic = playsMusic
        profile.instruments = playsMusic && !selectedInstruments.isEmpty ? Array(selectedInstruments) : nil
        profile.instrumentLevel = playsMusic ? selectedInstrumentLevel : nil
        profile.outdoorActivities = selectedOutdoorActivities.isEmpty ? nil : Array(selectedOutdoorActivities)
        profile.localSpots = localSpots.isEmpty ? nil : localSpots
    }
    
    func saveAndContinue() {
        saveToProfile()
        onComplete()
    }
}

// MARK: - Sub-Components

struct ToneButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    init(tone: VoiceTone, isSelected: Bool, action: @escaping () -> Void) {
        self.text = tone.displayName
        self.isSelected = isSelected
        self.action = action
    }
    
    init(text: String, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Brand.accent : Brand.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Brand.accentLight : Brand.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusMedium)
                        .stroke(isSelected ? Brand.accent : Brand.border, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PillButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(isSelected ? .white : Brand.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? Brand.accent : Brand.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Brand.accent : Brand.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct LevelButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(isSelected ? Brand.accent : Brand.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? Brand.accentLight : Brand.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusSmall)
                        .stroke(isSelected ? Brand.accent : Brand.border, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct EmojiStyleButton: View {
    let style: EmojiStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(style.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Brand.accent : Brand.textPrimary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Brand.accentLight : Brand.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusMedium)
                        .stroke(isSelected ? Brand.accent : Brand.border, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        ProfileFlowLayout(spacing: spacing) {
            content()
        }
    }
}

struct ProfileFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x,
                             y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Elastic Scroll Spread

struct ScrollVelocityTracker: UIViewRepresentable {
    var onDelta: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let scrollView = view.parentScrollView() {
                context.coordinator.observe(scrollView)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDelta: onDelta)
    }
    
    class Coordinator: NSObject {
        let onDelta: (CGFloat) -> Void
        private var observation: NSKeyValueObservation?
        private var lastOffsetY: CGFloat = 0
        private var isFirst = true
        
        init(onDelta: @escaping (CGFloat) -> Void) {
            self.onDelta = onDelta
        }
        
        func observe(_ scrollView: UIScrollView) {
            lastOffsetY = scrollView.contentOffset.y
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                guard let self, let newOffset = change.newValue else { return }
                if self.isFirst {
                    self.isFirst = false
                    self.lastOffsetY = newOffset.y
                    return
                }
                let delta = newOffset.y - self.lastOffsetY
                self.lastOffsetY = newOffset.y
                DispatchQueue.main.async {
                    self.onDelta(delta)
                }
            }
        }
    }
}

private extension UIView {
    func parentScrollView() -> UIScrollView? {
        var current: UIView? = self.superview
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}

extension View {
    func elasticSpread(spread: CGFloat) -> some View {
        self.modifier(ElasticSpreadModifier(spread: spread))
    }
}

private struct ElasticSpreadModifier: ViewModifier {
    var spread: CGFloat
    
    func body(content: Content) -> some View {
        content.visualEffect { effect, proxy in
            let bounds = proxy.bounds(of: .scrollView) ?? .zero
            let elemCenter = proxy.size.height / 2
            let vpCenter = bounds.midY
            let normalized = bounds.height > 0
                ? (elemCenter - vpCenter) / (bounds.height / 2)
                : 0.0
            let clamped = min(max(normalized, -1.0), 1.0)
            return effect.offset(y: clamped * spread * 3.5)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupView(
        profile: .constant(UserProfile(displayName: "")),
        step: 1,
        onComplete: {}
    )
}
