import SwiftUI
import UIKit
import SharedKit

/// Simplified profile setup: name + vibe + emoji style. One screen, 30 seconds.
struct QuickSetupView: View {
    @Binding var profile: UserProfile
    let step: Int
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var selectedTones: Set<VoiceTone> = [.playful]
    @State private var selectedEmojiStyle: EmojiStyle = .light
    
    // Entrance animation states
    @State private var headerVisible = false
    @State private var nameVisible = false
    @State private var vibeVisible = false
    @State private var emojiVisible = false
    @State private var buttonVisible = false
    
    private var isFormComplete: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedTones.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                        
                        Text("Quick Setup")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Just the basics so AI sounds like you")
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : 30)
                    
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
                    .opacity(nameVisible ? 1 : 0)
                    .offset(y: nameVisible ? 0 : 30)
                    
                    // Vibe
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Vibe")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.textPrimary)
                            
                            Text("Pick 1-3 message styles")
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
                    .opacity(vibeVisible ? 1 : 0)
                    .offset(y: vibeVisible ? 0 : 30)
                    
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
                    .opacity(emojiVisible ? 1 : 0)
                    .offset(y: emojiVisible ? 0 : 30)
                }
                .padding(.bottom, 120)
            }
            
            // Sticky bottom button
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Brand.background.opacity(0), Brand.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
                .allowsHitTesting(false)
                
                Button(action: saveAndContinue) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.brandPrimary)
                .disabled(!isFormComplete)
                .opacity(isFormComplete ? 1 : 0.5)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .background(Brand.background)
            }
            .opacity(buttonVisible ? 1 : 0)
            .offset(y: buttonVisible ? 0 : 30)
        }
        .background(Brand.background.ignoresSafeArea())
        .onAppear {
            restoreFromProfile()
            if step == 1 {
                startEntranceAnimations()
            }
        }
        .onChange(of: step) { _, newValue in
            if newValue == 1 {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    headerVisible = false
                    nameVisible = false
                    vibeVisible = false
                    emojiVisible = false
                    buttonVisible = false
                }
                startEntranceAnimations()
            }
        }
        .onChange(of: isFormComplete) { _, isComplete in
            if isComplete {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    // MARK: - Animations
    
    private func startEntranceAnimations() {
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
                vibeVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.36) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
                emojiVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + base + 0.48) {
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
    }
    
    private func saveToProfile() {
        profile.displayName = name.trimmingCharacters(in: .whitespaces)
        profile.voiceTone = Array(selectedTones).first ?? .playful
        profile.voiceTones = Array(selectedTones)
        profile.emojiStyle = selectedEmojiStyle
    }
    
    private func saveAndContinue() {
        saveToProfile()
        onComplete()
    }
}

#Preview {
    QuickSetupView(
        profile: .constant(UserProfile(displayName: "")),
        step: 1,
        onComplete: {}
    )
}
