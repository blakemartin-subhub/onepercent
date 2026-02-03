import SwiftUI
import SharedKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false
    @State private var showPrivacyInfo = false
    
    var body: some View {
        List {
            // Profile Section
            Section {
                if let profile = appState.userProfile {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Brand.gradient)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(profile.displayName.prefix(1).uppercased())
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.displayName)
                                .font(.headline)
                                .foregroundStyle(Brand.textPrimary)
                            
                            Text("\(profile.voiceTone.displayName) · \(profile.emojiStyle.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundStyle(Brand.textMuted)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showEditProfile = true }
                }
            } header: {
                Text("Profile")
            }
            
            // Keyboard Section
            Section {
                Button(action: openKeyboardSettings) {
                    HStack {
                        Label("Keyboard Settings", systemImage: "keyboard")
                            .foregroundStyle(Brand.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(Brand.textMuted)
                    }
                }
                
                HStack {
                    Label("Full Access", systemImage: "lock.open")
                        .foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Text(hasFullAccess ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .foregroundStyle(hasFullAccess ? Brand.success : Brand.textMuted)
                }
            } header: {
                Text("Keyboard")
            } footer: {
                Text("Full Access enables AI message generation directly from the keyboard.")
            }
            
            // Privacy Section
            Section {
                Button(action: { showPrivacyInfo = true }) {
                    HStack {
                        Label("Privacy Info", systemImage: "hand.raised")
                            .foregroundStyle(Brand.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Brand.textMuted)
                    }
                }
                
                Link(destination: URL(string: "https://onepercent.app/privacy")!) {
                    HStack {
                        Label("Privacy Policy", systemImage: "doc.text")
                            .foregroundStyle(Brand.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(Brand.textMuted)
                    }
                }
            } header: {
                Text("Privacy")
            }
            
            // Data Section
            Section {
                HStack {
                    Label("Matches", systemImage: "heart.fill")
                        .foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Text("\(appState.matches.count)")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }
                
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Delete All Data", systemImage: "trash")
                        .foregroundStyle(Brand.error)
                }
            } header: {
                Text("Data")
            } footer: {
                Text("This will permanently delete all matches, messages, and your profile.")
            }
            
            // About Section
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle")
                        .foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }
            } header: {
                Text("About")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .tint(Brand.accent)
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView()
            }
        }
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyInfoSheet()
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This action cannot be undone. All your matches, generated messages, and profile will be permanently deleted.")
        }
    }
    
    private var hasFullAccess: Bool {
        return UIPasteboard.general.hasStrings
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func deleteAllData() {
        MatchStore.shared.deleteAllData()
        appState.matches = []
        appState.userProfile = nil
        appState.hasCompletedOnboarding = false
        UserDefaults.appGroup.set(false, forKey: "hasCompletedOnboarding")
    }
}

struct PrivacyInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PrivacyItem(
                        icon: "photo.on.rectangle",
                        title: "Screenshots Stay on Device",
                        description: "Your dating profile screenshots are processed locally using on-device OCR. We never upload your images to any server."
                    )
                    
                    PrivacyItem(
                        icon: "text.quote",
                        title: "Text Processing",
                        description: "Only extracted text is sent to our servers for AI message generation. No images or personal identifiers are transmitted."
                    )
                    
                    PrivacyItem(
                        icon: "keyboard",
                        title: "No Keystroke Logging",
                        description: "Our keyboard never logs, stores, or transmits your keystrokes. We only insert messages you explicitly tap."
                    )
                    
                    PrivacyItem(
                        icon: "lock.shield",
                        title: "Encrypted Storage",
                        description: "All data stored on your device is encrypted using industry-standard AES-256 encryption."
                    )
                    
                    PrivacyItem(
                        icon: "trash",
                        title: "Full Data Control",
                        description: "Delete all your data at any time from Settings. We don't keep backups of your personal information."
                    )
                }
                .padding(20)
            }
            .background(Brand.background)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Brand.accent)
                }
            }
        }
    }
}

struct PrivacyItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Brand.accent)
                .frame(width: 44, height: 44)
                .background(Brand.accentLight)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusSmall))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
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
        Form {
            Section("Name") {
                TextField("Your name", text: $name)
            }
            
            Section("Voice & Tone") {
                Picker("Tone", selection: $selectedTone) {
                    ForEach(VoiceTone.allCases, id: \.self) { tone in
                        Text(tone.displayName).tag(tone)
                    }
                }
            }
            
            Section("Emoji Style") {
                Picker("Emojis", selection: $selectedEmojiStyle) {
                    ForEach(EmojiStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }
            
            Section("Content Boundaries") {
                ForEach(boundaries, id: \.self) { boundary in
                    Toggle(boundary, isOn: Binding(
                        get: { selectedBoundaries.contains(boundary) },
                        set: { isOn in
                            if isOn {
                                selectedBoundaries.insert(boundary)
                            } else {
                                selectedBoundaries.remove(boundary)
                            }
                        }
                    ))
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.accent)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveProfile() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            if let profile = appState.userProfile {
                name = profile.displayName
                selectedTone = profile.voiceTone
                selectedEmojiStyle = profile.emojiStyle
                selectedBoundaries = Set(profile.hardBoundaries)
            }
        }
    }
    
    private func saveProfile() {
        var profile = appState.userProfile ?? UserProfile(displayName: name)
        profile.displayName = name
        profile.voiceTone = selectedTone
        profile.emojiStyle = selectedEmojiStyle
        profile.hardBoundaries = Array(selectedBoundaries)
        profile.updatedAt = Date()
        
        appState.saveUserProfile(profile)
        dismiss()
    }
}

extension Bundle {
    var appVersion: String {
        let version = (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (infoDictionary?["CFBundleVersion"] as? String) ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
