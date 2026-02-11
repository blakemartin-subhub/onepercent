import SwiftUI
import SharedKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false
    @State private var showPrivacyInfo = false
    @State private var serverURL: String = BackendConfig.shared.baseURL
    @State private var serverStatus: ServerStatus = .unknown
    @State private var showDebugResponse = false
    @State private var debugResponse = ""
    @State private var showBackendInfo = false
    @State private var backendInfo: BackendInfo?
    @State private var backendInfoError: String?
    
    enum ServerStatus {
        case unknown, checking, reachable, unreachable
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Card
                if let profile = appState.userProfile {
                    ProfileCard(profile: profile) {
                        showEditProfile = true
                    }
                }
                
                // Keyboard Section
                SettingsSection(title: "Keyboard") {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "keyboard.fill",
                            iconColor: Brand.accent,
                            title: "Keyboard Settings",
                            trailing: .external
                        ) {
                            openKeyboardSettings()
                        }
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        SettingsRow(
                            icon: "checkmark.shield.fill",
                            iconColor: hasFullAccess ? Brand.success : Brand.textMuted,
                            title: "Full Access",
                            trailing: .status(hasFullAccess ? "Enabled" : "Disabled", isPositive: hasFullAccess)
                        )
                    }
                    
                    Text("Full Access enables AI message generation directly from the keyboard.")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                // Server Section (Development)
                SettingsSection(title: "Server") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Brand.accent)
                                .frame(width: 28, height: 28)
                            
                            TextField("http://192.168.1.5:3002", text: $serverURL)
                                .font(.body)
                                .foregroundStyle(Brand.textPrimary)
                                .tint(Brand.accent)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .onSubmit { saveServerURL() }
                            
                            // Status indicator
                            Group {
                                switch serverStatus {
                                case .unknown:
                                    Circle()
                                        .fill(Brand.textMuted)
                                        .frame(width: 10, height: 10)
                                case .checking:
                                    ProgressView()
                                        .scaleEffect(0.7)
                                case .reachable:
                                    Circle()
                                        .fill(Brand.success)
                                        .frame(width: 10, height: 10)
                                case .unreachable:
                                    Circle()
                                        .fill(Brand.error)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Save + Test button
                        HStack(spacing: 8) {
                            Button(action: { saveServerURL() }) {
                                Text("Save")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Brand.accent)
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: { testConnection() }) {
                                Text("Test Connection")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Brand.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Brand.accentLight)
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: { debugParseEndpoint() }) {
                                Text("Debug Parse API")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: { fetchBackendInfo() }) {
                                Text("Backend Info")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        
                        // Backend Info Display
                        if let info = backendInfo {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.purple)
                                    Text("Backend Configuration")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Brand.textPrimary)
                                }
                                
                                if let model = info.model {
                                    HStack {
                                        Text("Model:")
                                            .font(.caption2)
                                            .foregroundStyle(Brand.textSecondary)
                                        Text(model)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Brand.accent)
                                    }
                                }
                                
                                if let version = info.version {
                                    HStack {
                                        Text("Version:")
                                            .font(.caption2)
                                            .foregroundStyle(Brand.textSecondary)
                                        Text(version)
                                            .font(.caption2)
                                            .foregroundStyle(Brand.textPrimary)
                                    }
                                }
                                
                                if let env = info.environment {
                                    HStack {
                                        Text("Environment:")
                                            .font(.caption2)
                                            .foregroundStyle(Brand.textSecondary)
                                        Text(env)
                                            .font(.caption2)
                                            .foregroundStyle(Brand.textPrimary)
                                    }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                        
                        if let error = backendInfoError {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(Brand.textSecondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                    }
                    
                    Text("Your Mac's local IP + port. The keyboard extension reads this to reach the backend. Run `ipconfig getifaddr en0` in Terminal to find your IP.")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                }
                
                // Privacy Section
                SettingsSection(title: "Privacy") {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            iconColor: Brand.accent,
                            title: "How We Protect Your Data",
                            trailing: .chevron
                        ) {
                            showPrivacyInfo = true
                        }
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: Brand.accent,
                            title: "Privacy Policy",
                            trailing: .external
                        ) {
                            if let url = URL(string: "https://onepercent.app/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                
                // Data Section
                SettingsSection(title: "Your Data") {
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: Brand.error,
                            title: "Delete All Data",
                            titleColor: Brand.error,
                            trailing: .none
                        ) {
                            showDeleteConfirmation = true
                        }
                    }
                }
                
                // Version
                Text("Version \(Bundle.main.appVersion)")
                    .font(.caption)
                    .foregroundStyle(Brand.textMuted)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView()
            }
        }
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyInfoSheet()
        }
        .sheet(isPresented: $showDebugResponse) {
            NavigationStack {
                ScrollView {
                    Text(debugResponse)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("Server Response")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showDebugResponse = false }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            UIPasteboard.general.string = debugResponse
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
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
    
    private func saveServerURL() {
        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        BackendConfig.shared.baseURL = trimmed
        print("[Settings] Backend URL saved: \(trimmed)")
        testConnection()
    }
    
    private func testConnection() {
        serverStatus = .checking
        let urlString = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            guard let url = URL(string: urlString + "/health") else {
                await MainActor.run { serverStatus = .unreachable }
                return
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    await MainActor.run { serverStatus = .reachable }
                } else {
                    await MainActor.run { serverStatus = .unreachable }
                }
            } catch {
                print("[Settings] Connection test failed: \(error.localizedDescription)")
                await MainActor.run { serverStatus = .unreachable }
            }
        }
    }
    
    private func debugParseEndpoint() {
        debugResponse = "⏳ Loading..."
        showDebugResponse = true
        
        Task {
            do {
                let response = try await APIClient.shared.debugParseProfile(ocrText: "Test profile: John, 25, likes hiking")
                await MainActor.run {
                    debugResponse = response
                }
            } catch {
                await MainActor.run {
                    debugResponse = "❌ Error calling debug endpoint:\n\n\(error.localizedDescription)\n\nFull error:\n\(error)"
                }
            }
        }
    }
    
    private func fetchBackendInfo() {
        backendInfoError = nil
        backendInfo = nil
        
        Task {
            do {
                let info = try await APIClient.shared.getBackendInfo()
                await MainActor.run {
                    backendInfo = info
                    print("[Settings] ✅ Backend Info - Model: \(info.model ?? "unknown"), Version: \(info.version ?? "unknown")")
                }
            } catch {
                await MainActor.run {
                    backendInfoError = "Failed to fetch backend info. Make sure your backend has an /info endpoint that returns {\"model\": \"gpt-4o\", \"version\": \"1.0.0\", \"environment\": \"development\"}"
                    print("[Settings] ❌ Backend Info Error: \(error.localizedDescription)")
                }
            }
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

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Brand.accent)
                        .frame(width: 64, height: 64)
                    
                    Text(profile.displayName.prefix(1).uppercased())
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                    
                    HStack(spacing: 6) {
                        let toneText = profile.voiceTones.isEmpty 
                            ? profile.voiceTone.displayName 
                            : profile.voiceTones.map { $0.displayName }.joined(separator: ", ")
                        Label(toneText, systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                        
                        Text("·")
                            .foregroundStyle(Brand.textMuted)
                        
                        Text(profile.emojiStyle.displayName)
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.accent)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusMedium)
                    .fill(Brand.card)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textMuted)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusMedium)
                    .fill(Brand.card)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Settings Row

enum SettingsTrailing {
    case chevron
    case external
    case value(String)
    case status(String, isPositive: Bool)
    case none
}

struct SettingsRow: View {
    let icon: String
    var iconColor: Color = Brand.accent
    let title: String
    var titleColor: Color = Brand.textPrimary
    var trailing: SettingsTrailing = .chevron
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                
                // Title
                Text(title)
                    .font(.body)
                    .foregroundStyle(titleColor)
                
                Spacer()
                
                // Trailing
                trailingView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
    
    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textMuted)
        case .external:
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textMuted)
        case .value(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(Brand.textSecondary)
        case .status(let text, let isPositive):
            HStack(spacing: 6) {
                Circle()
                    .fill(isPositive ? Brand.success : Brand.textMuted)
                    .frame(width: 8, height: 8)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(isPositive ? Brand.success : Brand.textMuted)
            }
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Privacy Info Sheet

struct PrivacyInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Brand.accentLight)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Brand.accent)
                        }
                        
                        Text("Your Privacy Matters")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
                        
                        Text("Here's how we keep your data safe")
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    VStack(spacing: 16) {
                        PrivacyCard(
                            icon: "photo.on.rectangle.angled",
                            title: "Screenshots Stay Local",
                            description: "Your dating profile screenshots are processed on-device. We never upload your images."
                        )
                        
                        PrivacyCard(
                            icon: "text.bubble",
                            title: "Minimal Data Sent",
                            description: "Only extracted text goes to our servers for AI generation. No images or personal IDs."
                        )
                        
                        PrivacyCard(
                            icon: "keyboard",
                            title: "No Keystroke Logging",
                            description: "Our keyboard never logs or transmits your keystrokes. We only insert messages you tap."
                        )
                        
                        PrivacyCard(
                            icon: "lock.fill",
                            title: "Encrypted Storage",
                            description: "All local data is encrypted with industry-standard AES-256 encryption."
                        )
                        
                        PrivacyCard(
                            icon: "trash.fill",
                            title: "Full Control",
                            description: "Delete all your data anytime from Settings. We don't keep backups."
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Brand.accent)
                }
            }
        }
    }
}

struct PrivacyCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(Brand.accent)
                .frame(width: 40, height: 40)
                .background(Brand.accentLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Brand.radiusMedium)
                .fill(Brand.card)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var name = ""
    @State private var selectedTones: Set<VoiceTone> = [.playful]
    @State private var selectedEmojiStyle: EmojiStyle = .light
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Brand.accent)
                        .frame(width: 80, height: 80)
                    
                    Text(name.prefix(1).uppercased())
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 20)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.textSecondary)
                    
                    TextField("Your name", text: $name)
                        .font(.body)
                        .foregroundStyle(Brand.textPrimary)
                        .tint(Brand.accent)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.radiusMedium)
                                .fill(Brand.card)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                        )
                }
                .padding(.horizontal, 20)
                
                // Voice Tone (multi-select)
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Vibe")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textSecondary)
                        
                        Text("Pick 1-3 message styles")
                            .font(.caption)
                            .foregroundStyle(Brand.textMuted)
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(VoiceTone.allCases, id: \.self) { tone in
                                ToneChip(
                                    title: tone.displayName,
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
                        .padding(.horizontal, 20)
                    }
                }
                
                // Emoji Style
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emoji Style")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.textSecondary)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 10) {
                        ForEach(EmojiStyle.allCases, id: \.self) { style in
                            ToneChip(
                                title: style.displayName,
                                isSelected: selectedEmojiStyle == style
                            ) {
                                selectedEmojiStyle = style
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Brand.textSecondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveProfile() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Brand.accent)
            }
        }
        .onAppear {
            if let profile = appState.userProfile {
                name = profile.displayName
                if !profile.voiceTones.isEmpty {
                    selectedTones = Set(profile.voiceTones)
                } else {
                    selectedTones = [profile.voiceTone]
                }
                selectedEmojiStyle = profile.emojiStyle
            }
        }
    }
    
    private func saveProfile() {
        var profile = appState.userProfile ?? UserProfile(displayName: name)
        profile.displayName = name
        profile.voiceTone = Array(selectedTones).first ?? .playful
        profile.voiceTones = Array(selectedTones)
        profile.emojiStyle = selectedEmojiStyle
        profile.updatedAt = Date()
        
        appState.saveUserProfile(profile)
        dismiss()
    }
}

struct ToneChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : Brand.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AnyShapeStyle(Brand.accent) : AnyShapeStyle(Brand.card))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct BoundaryRow: View {
    let title: String
    let isEnabled: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(Brand.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onChange($0) }
            ))
            .tint(Brand.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Bundle Extension

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
