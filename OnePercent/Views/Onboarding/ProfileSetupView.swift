import SwiftUI
import SharedKit

struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var selectedTones: Set<VoiceTone> = [.playful]
    @State private var selectedEmojiStyle: EmojiStyle = .light
    @State private var selectedBoundaries: Set<String> = []
    @State private var selectedActivities: Set<String> = []
    @State private var selectedNationalities: Set<String> = []
    @State private var selectedFirstDateGoal: FirstDateGoal? = nil
    
    private let boundaries = [
        "No sexual content",
        "No negging or put-downs",
        "No manipulation tactics",
        "Keep it respectful",
        "No mentioning AI"
    ]
    
    var body: some View {
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
                    
                    Text("Your Profile")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                    
                    Text("Help the AI write messages\nthat sound like you")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your First Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.textPrimary)
                    
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
                }
                .padding(.horizontal, 20)
                
                // Nationality
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Background")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Select all that apply - helps personalize messages")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Voice/Tone
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Vibe")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Select one or more message styles")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Activities
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What You Like To Do")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Select all that apply")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // First Date Goal
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preferred First Date")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Messages will subtly lead toward this")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(FirstDateGoal.allCases, id: \.self) { goal in
                            ToneButton(
                                text: goal.displayName,
                                isSelected: selectedFirstDateGoal == goal
                            ) {
                                selectedFirstDateGoal = goal
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Emoji Style
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emoji Style")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.textPrimary)
                    
                    HStack(spacing: 10) {
                        ForEach(EmojiStyle.allCases, id: \.self) { style in
                            EmojiStyleButton(
                                style: style,
                                isSelected: selectedEmojiStyle == style
                            ) {
                                selectedEmojiStyle = style
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Boundaries
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Content Boundaries")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Messages will never include:")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Continue Button
                Button(action: saveAndContinue) {
                    HStack {
                        Text("Start Using Keyboard")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.brandPrimary)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
            }
        }
        .background(Brand.background)
    }
    
    private func saveAndContinue() {
        let tonesArray = Array(selectedTones)
        profile = UserProfile(
            displayName: name.trimmingCharacters(in: .whitespaces),
            voiceTone: tonesArray.first ?? .playful,
            voiceTones: tonesArray,
            hardBoundaries: Array(selectedBoundaries),
            emojiStyle: selectedEmojiStyle,
            activities: Array(selectedActivities),
            nationalities: Array(selectedNationalities),
            firstDateGoal: selectedFirstDateGoal
        )
        onComplete()
    }
}

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
        Button(action: action) {
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
        Button(action: action) {
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
        Button(action: action) {
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
        Button(action: action) {
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

#Preview {
    ProfileSetupView(
        profile: .constant(UserProfile(displayName: "")),
        onComplete: {}
    )
}
