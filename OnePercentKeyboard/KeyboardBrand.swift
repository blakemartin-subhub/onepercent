import SwiftUI

/// OnePercent Brand Colors for Keyboard Extension
enum KeyboardBrand {
    // MARK: - Primary Colors
    
    /// Soft indigo-purple - comforting, trustworthy
    static let accent = Color(hex: "6366F1")
    
    /// Lighter accent for backgrounds
    static let accentLight = Color(hex: "E0E7FF")
    
    /// Gradient for special elements
    static let gradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Horizontal gradient for buttons
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "7C3AED")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Text Colors
    
    static let textPrimary = Color(hex: "0F172A")
    static let textSecondary = Color(hex: "64748B")
    static let textMuted = Color(hex: "94A3B8")
    
    // MARK: - Background Colors
    
    static let background = Color.white
    static let backgroundSecondary = Color(hex: "F8FAFC")
    static let card = Color.white
    static let border = Color(hex: "E2E8F0")
    
    // MARK: - Keyboard specific (dark mode for keyboard)
    static let keyboardBackground = Color(hex: "1C1C1E")
    static let keyboardCard = Color(hex: "2C2C2E")
    static let keyboardTextPrimary = Color.white
    static let keyboardTextSecondary = Color(hex: "8E8E93")
    
    // MARK: - Semantic Colors
    
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    
    // MARK: - Corner Radii
    
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
}

// Color hex extension for keyboard
extension Color {
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
