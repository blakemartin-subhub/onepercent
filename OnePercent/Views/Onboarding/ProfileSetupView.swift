import SwiftUI
import UIKit
import SharedKit

struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let step: Int
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var selectedTones: Set<VoiceTone> = [.playful]
    @State private var selectedEmojiStyle: EmojiStyle = .light
    @State private var selectedBoundaries: Set<String> = []
    @State private var selectedActivities: Set<String> = []
    @State private var selectedNationalities: Set<String> = []
    @State private var selectedFirstDateGoal: FirstDateGoal? = nil
    
    // Entrance animation states
    @State private var headerVisible = false
    @State private var nameVisible = false
    @State private var formVisible = false
    @State private var buttonVisible = false
    @State private var buttonReady = false
    
    // Elastic scroll spread
    @State private var spread: CGFloat = 0
    @State private var decayTask: Task<Void, Never>?
    
    private let boundaries = [
        "No sexual content",
        "No negging or put-downs",
        "No manipulation tactics",
        "Keep it respectful",
        "No mentioning AI"
    ]
    
    // MARK: - Validation
    
    private var isNameComplete: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isBackgroundComplete: Bool { !selectedNationalities.isEmpty }
    private var isVibeComplete: Bool { !selectedTones.isEmpty }
    private var isActivitiesComplete: Bool { !selectedActivities.isEmpty }
    private var isFirstDateComplete: Bool { selectedFirstDateGoal != nil }
    private var isEmojiComplete: Bool { true } // always has a default selection
    private var isBoundariesComplete: Bool { !selectedBoundaries.isEmpty }
    
    private var isFormComplete: Bool {
        isNameComplete && isBackgroundComplete && isVibeComplete &&
        isActivitiesComplete && isFirstDateComplete && isEmojiComplete && isBoundariesComplete
    }
    
    private var sectionsRemaining: Int {
        [isNameComplete, isBackgroundComplete, isVibeComplete,
         isActivitiesComplete, isFirstDateComplete, isEmojiComplete,
         isBoundariesComplete].filter { !$0 }.count
    }
    
    // MARK: - Section Header Helper
    
    @ViewBuilder
    private func sectionTitle(_ title: String, isComplete: Bool) -> some View {
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
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
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
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : 30)
                    
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        sectionTitle("Your First Name", isComplete: isNameComplete)
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
                    .opacity(nameVisible ? 1 : 0)
                    .offset(y: nameVisible ? 0 : 30)
                    
                    // Form sections
                    Group {
                    // Nationality
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            sectionTitle("Your Background", isComplete: isBackgroundComplete)
                            
                            Text("Select all that apply - helps personalize messages")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .elasticSpread(spread: spread)
                        
                        FlowLayoutView(spacing: 8) {
                            ForEach(Nationality.allCases, id: \.rawValue) { nationality in
                                PillButton(
                                    text: nationality.rawValue,
                                    isSelected: selectedNationalities.contains(nationality.rawValue)
                                ) {
                                    if selectedNationalities.contains(nationality.rawValue) {
                                        selectedNationalities.remove(nationality.rawValue)
                                    } else {
                                        selectedNationalities.insert(nationality.rawValue)
                                    }
                                }
                                .elasticSpread(spread: spread)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Voice/Tone
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            sectionTitle("Your Vibe", isComplete: isVibeComplete)
                            
                            Text("Select one or more message styles")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .elasticSpread(spread: spread)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(VoiceTone.allCases, id: \.self) { tone in
                                ToneButton(
                                    tone: tone,
                                    isSelected: selectedTones.contains(tone)
                                ) {
                                    if selectedTones.contains(tone) {
                                        if selectedTones.count > 1 {
                                            selectedTones.remove(tone)
                                        }
                                    } else {
                                        selectedTones.insert(tone)
                                    }
                                }
                                .elasticSpread(spread: spread)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Activities
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            sectionTitle("What You Like To Do", isComplete: isActivitiesComplete)
                            
                            Text("Select all that apply")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .elasticSpread(spread: spread)
                        
                        FlowLayoutView(spacing: 8) {
                            ForEach(Activity.allCases, id: \.rawValue) { activity in
                                PillButton(
                                    text: activity.rawValue,
                                    isSelected: selectedActivities.contains(activity.rawValue)
                                ) {
                                    if selectedActivities.contains(activity.rawValue) {
                                        selectedActivities.remove(activity.rawValue)
                                    } else {
                                        selectedActivities.insert(activity.rawValue)
                                    }
                                }
                                .elasticSpread(spread: spread)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // First Date Goal
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            sectionTitle("Preferred First Date", isComplete: isFirstDateComplete)
                            
                            Text("Messages will subtly lead toward this")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .elasticSpread(spread: spread)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(FirstDateGoal.allCases, id: \.self) { goal in
                                ToneButton(
                                    text: goal.displayName,
                                    isSelected: selectedFirstDateGoal == goal
                                ) {
                                    selectedFirstDateGoal = goal
                                }
                                .elasticSpread(spread: spread)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Emoji Style
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Emoji Style", isComplete: isEmojiComplete)
                            .elasticSpread(spread: spread)
                        
                        HStack(spacing: 10) {
                            ForEach(EmojiStyle.allCases, id: \.self) { style in
                                EmojiStyleButton(
                                    style: style,
                                    isSelected: selectedEmojiStyle == style
                                ) {
                                    selectedEmojiStyle = style
                                }
                                .elasticSpread(spread: spread)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Boundaries
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            sectionTitle("Content Boundaries", isComplete: isBoundariesComplete)
                            
                            Text("Messages will never include:")
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .elasticSpread(spread: spread)
                        
                        VStack(spacing: 8) {
                            ForEach(boundaries, id: \.self) { boundary in
                                ProfileBoundaryRow(
                                    text: boundary,
                                    isSelected: selectedBoundaries.contains(boundary)
                                ) {
                                    if selectedBoundaries.contains(boundary) {
                                        selectedBoundaries.remove(boundary)
                                    } else {
                                        selectedBoundaries.insert(boundary)
                                    }
                                }
                                .elasticSpread(spread: spread)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    }
                    .opacity(formVisible ? 1 : 0)
                    .offset(y: formVisible ? 0 : 30)
                }
                .padding(.bottom, 120)
                .background(
                    ScrollVelocityTracker { delta in
                        // Ignore tiny jitters or huge layout jumps
                        guard abs(delta) > 0.3 && abs(delta) < 80 else { return }
                        
                        // Target spread from current scroll speed
                        let target = min(abs(delta) * 0.8, 18)
                        
                        // Lerp toward target — no animation, just smooth interpolation each frame
                        // This eliminates choppiness from spring animations fighting each other
                        spread += (target - spread) * 0.25
                        
                        // Elastic spring-back when scrolling stops
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
            
            // MARK: - Sticky Bottom Button
            VStack(spacing: 0) {
                // Gradient fade above button
                LinearGradient(
                    colors: [Brand.background.opacity(0), Brand.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
                .allowsHitTesting(false)
                
                VStack(spacing: 10) {
                    if !isFormComplete {
                        Text("Complete \(sectionsRemaining) more section\(sectionsRemaining == 1 ? "" : "s") to continue")
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
            .opacity(buttonVisible ? 1 : 0)
            .offset(y: buttonVisible ? 0 : 30)
        }
        .background(Brand.background.ignoresSafeArea())
        .onAppear {
            restoreFromProfile()
            // Only animate on appear if this is already the active step (e.g., in preview)
            if step == 2 {
                startEntranceAnimations()
            }
        }
        .onDisappear {
            saveToProfile()
        }
        .onChange(of: step) { _, newValue in
            if newValue == 2 {
                // Reset without animation to ensure clean slate
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
        // Section completion haptics
        .onChange(of: isNameComplete) { _, complete in
            if complete { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        .onChange(of: isBackgroundComplete) { _, complete in
            if complete { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        .onChange(of: isActivitiesComplete) { _, complete in
            if complete { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        .onChange(of: isFirstDateComplete) { _, complete in
            if complete { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        .onChange(of: isBoundariesComplete) { _, complete in
            if complete { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        // Form complete celebration
        .onChange(of: isFormComplete) { _, isComplete in
            if isComplete {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    buttonReady = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        buttonReady = false
                    }
                }
            }
        }
    }
    
    // MARK: - Animations
    
    private func startEntranceAnimations() {
        // Use separate asyncAfter calls to guarantee each animation runs in its own
        // execution context, preventing the TabView's .animation(.easeInOut) from interfering
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

    private func restoreFromProfile() {
        name = profile.displayName
        if !profile.voiceTones.isEmpty {
            selectedTones = Set(profile.voiceTones)
        }
        selectedEmojiStyle = profile.emojiStyle
        selectedBoundaries = Set(profile.hardBoundaries)
        selectedActivities = Set(profile.activities)
        selectedNationalities = Set(profile.nationalities)
        selectedFirstDateGoal = profile.firstDateGoal
    }
    
    private func saveToProfile() {
        profile.displayName = name.trimmingCharacters(in: .whitespaces)
        profile.voiceTone = Array(selectedTones).first ?? .playful
        profile.voiceTones = Array(selectedTones)
        profile.hardBoundaries = Array(selectedBoundaries)
        profile.emojiStyle = selectedEmojiStyle
        profile.activities = Array(selectedActivities)
        profile.nationalities = Array(selectedNationalities)
        profile.firstDateGoal = selectedFirstDateGoal
    }
    
    private func saveAndContinue() {
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : Brand.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Brand.accent : Brand.backgroundSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Brand.accent : Brand.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

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
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
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

struct ProfileBoundaryRow: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Brand.accent : Brand.textMuted)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textPrimary)
                
                Spacer()
            }
            .padding(14)
            .background(Brand.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Elastic Scroll Spread

/// Tracks UIScrollView contentOffset via KVO — fires every frame during scroll.
struct ScrollVelocityTracker: UIViewRepresentable {
    var onDelta: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        // Find parent UIScrollView after view is inserted into hierarchy
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
                // Skip the first callback (initial value)
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
    /// Elastic spread: items push apart from viewport center when scrolling, spring back when stopped.
    /// Uses .visualEffect for per-element position-based offset — no manual index needed.
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

#Preview {
    ProfileSetupView(
        profile: .constant(UserProfile(displayName: "")),
        step: 2,
        onComplete: {}
    )
}
