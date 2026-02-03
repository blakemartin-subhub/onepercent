import SwiftUI
import SharedKit

struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var selectedTones: Set<VoiceTone> = [.playful]
    @State private var selectedEmojiStyle: EmojiStyle = .light
    @State private var selectedBoundaries: Set<String> = []
    
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
                        .padding(16)
                        .background(Brand.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.radiusMedium)
                                .stroke(Brand.border, lineWidth: 1)
                        )
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
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
                            BoundaryRow(
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
            emojiStyle: selectedEmojiStyle
        )
        onComplete()
    }
}

struct ToneButton: View {
    let tone: VoiceTone
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(tone.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? Brand.accent : Brand.textPrimary)
                
                Text(tone.description)
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
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

struct BoundaryRow: View {
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
