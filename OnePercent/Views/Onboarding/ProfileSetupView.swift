import SwiftUI
import SharedKit

struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var selectedTone: VoiceTone = .playful
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
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.pink)
                    
                    Text("Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Help us personalize your messages")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your First Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                
                // Voice/Tone
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Vibe")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("How do you want your messages to sound?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(VoiceTone.allCases, id: \.self) { tone in
                            ToneButton(
                                tone: tone,
                                isSelected: selectedTone == tone
                            ) {
                                selectedTone = tone
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Emoji Style
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emoji Style")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
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
                .padding(.horizontal, 24)
                
                // Boundaries
                VStack(alignment: .leading, spacing: 12) {
                    Text("Content Boundaries")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Messages will never include:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
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
                .padding(.horizontal, 24)
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Complete Setup")
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
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
            }
        }
    }
    
    private func saveAndContinue() {
        profile = UserProfile(
            displayName: name.trimmingCharacters(in: .whitespaces),
            voiceTone: selectedTone,
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(tone.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.pink.opacity(0.15) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
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
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.pink.opacity(0.15) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
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
                    .foregroundStyle(isSelected ? .pink : .secondary)
                
                Text(text)
                    .font(.subheadline)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
