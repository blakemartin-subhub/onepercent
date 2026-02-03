import SwiftUI

/// OnePercent Brand Colors and Styles
/// Inspired by clean, modern dating app aesthetics
enum Brand {
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
    
    /// Primary text - serious, readable black
    static let textPrimary = Color(hex: "0F172A")
    
    /// Secondary text
    static let textSecondary = Color(hex: "64748B")
    
    /// Muted text
    static let textMuted = Color(hex: "94A3B8")
    
    // MARK: - Background Colors
    
    /// Pure white background
    static let background = Color.white
    
    /// Light gray background for sections
    static let backgroundSecondary = Color(hex: "F8FAFC")
    
    /// Card background
    static let card = Color.white
    
    /// Subtle border color
    static let border = Color(hex: "E2E8F0")
    
    // MARK: - Semantic Colors
    
    /// Success green
    static let success = Color(hex: "10B981")
    
    /// Warning orange
    static let warning = Color(hex: "F59E0B")
    
    /// Error red
    static let error = Color(hex: "EF4444")
    
    // MARK: - Corner Radii
    
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXLarge: CGFloat = 20
    
    // MARK: - Shadows
    
    static func cardShadow() -> some View {
        Color.black.opacity(0.04)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

// MARK: - Brand Button Styles

struct BrandPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct BrandSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Brand.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.accentLight)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == BrandPrimaryButton {
    static var brandPrimary: BrandPrimaryButton { BrandPrimaryButton() }
}

extension ButtonStyle where Self == BrandSecondaryButton {
    static var brandSecondary: BrandSecondaryButton { BrandSecondaryButton() }
}
