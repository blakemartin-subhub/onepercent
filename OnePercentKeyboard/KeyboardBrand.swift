import SwiftUI

/// OnePercent Brand Colors for Keyboard Extension
/// Synced with main app's design system - bold black/white with indigo accent
enum KeyboardBrand {
    // MARK: - Primary Colors (Indigo)

    /// Muted indigo accent (indigo-500)
    static let accent = Color(hex: "6366F1")

    /// Lighter accent for backgrounds (indigo-50)
    static let accentLight = Color(hex: "EEF2FF")

    // MARK: - Text Colors

    static let textPrimary = Color(hex: "0A0A0A")   // neutral-950
    static let textSecondary = Color(hex: "737373")  // neutral-500
    static let textMuted = Color(hex: "A3A3A3")      // neutral-400

    // MARK: - Background Colors

    static let background = Color.white
    static let backgroundSecondary = Color(hex: "FAFAFA") // neutral-50
    static let card = Color.white
    static let border = Color(hex: "E5E5E5")         // neutral-200

    // MARK: - Keyboard Specific (iOS keyboard dark style)

    static let keyboardBackground = Color(hex: "1C1C1E")
    static let keyboardCard = Color(hex: "2C2C2E")
    static let keyboardTextPrimary = Color.white
    static let keyboardTextSecondary = Color(hex: "8E8E93")
    static let keyboardAccent = Color(hex: "818CF8") // indigo-400 for dark bg

    // MARK: - Semantic Colors

    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // MARK: - Corner Radii

    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
}

// Color hex extension for keyboard (needed since SharedKit doesn't include this)
fileprivate extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
