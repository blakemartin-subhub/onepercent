import SwiftUI

/// OnePercent Brand Colors and Styles
/// Bold black/white aesthetic with muted indigo accent (Tailwind indigo scale)
/// See DESIGN.md for full design language documentation
enum Brand {
    // MARK: - Adaptive Colors (Light/Dark Mode)

    /// Primary accent - muted indigo (blue-purple)
    static let accent = Color("BrandAccent", bundle: nil)

    /// Light accent background
    static let accentLight = Color("BrandAccentLight", bundle: nil)

    /// Primary text color
    static let textPrimary = Color("BrandTextPrimary", bundle: nil)

    /// Secondary text color
    static let textSecondary = Color("BrandTextSecondary", bundle: nil)

    /// Muted text color
    static let textMuted = Color("BrandTextMuted", bundle: nil)

    /// Main background
    static let background = Color("BrandBackground", bundle: nil)

    /// Secondary background for sections/cards
    static let backgroundSecondary = Color("BrandBackgroundSecondary", bundle: nil)

    /// Card surface color
    static let card = Color("BrandCard", bundle: nil)

    /// Border/divider color
    static let border = Color("BrandBorder", bundle: nil)

    // MARK: - Fallback Colors (Used if Color Assets not found)

    enum Light {
        static let accent = Color(hex: "6366F1")       // indigo-500
        static let accentLight = Color(hex: "EEF2FF")   // indigo-50
        static let textPrimary = Color(hex: "0A0A0A")   // neutral-950
        static let textSecondary = Color(hex: "737373")  // neutral-500
        static let textMuted = Color(hex: "A3A3A3")      // neutral-400
        static let background = Color.white              // white
        static let backgroundSecondary = Color(hex: "FAFAFA") // neutral-50
        static let card = Color.white                    // white
        static let border = Color(hex: "E5E5E5")        // neutral-200
    }

    enum Dark {
        static let accent = Color(hex: "818CF8")         // indigo-400
        static let accentLight = Color(hex: "1E1B4B")    // indigo-950
        static let textPrimary = Color(hex: "FAFAFA")    // neutral-50
        static let textSecondary = Color(hex: "A3A3A3")  // neutral-400
        static let textMuted = Color(hex: "737373")      // neutral-500
        static let background = Color(hex: "0A0A0A")     // neutral-950
        static let backgroundSecondary = Color(hex: "171717") // neutral-900
        static let card = Color(hex: "171717")           // neutral-900
        static let border = Color(hex: "262626")         // neutral-800
    }

    // MARK: - Semantic Colors (Same in both modes)

    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // MARK: - Corner Radii

    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXLarge: CGFloat = 20

    // MARK: - Animation Constants

    enum Anim {
        static let entrance: Double = 0.5
        static let micro: Double = 0.25
        static let stagger: Double = 0.08

        /// Standard easeOut for entrances
        static func easeOut(duration: Double = entrance) -> Animation {
            .easeOut(duration: duration)
        }

        /// Staggered entrance animation
        static func staggered(index: Int, base: Double = entrance) -> Animation {
            .easeOut(duration: base).delay(Double(index) * stagger)
        }
    }

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

// MARK: - Adaptive Color Helper

/// View modifier to get adaptive brand colors
struct AdaptiveBrandColors: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
    }

    var accent: Color { colorScheme == .dark ? Brand.Dark.accent : Brand.Light.accent }
    var accentLight: Color { colorScheme == .dark ? Brand.Dark.accentLight : Brand.Light.accentLight }
    var textPrimary: Color { colorScheme == .dark ? Brand.Dark.textPrimary : Brand.Light.textPrimary }
    var background: Color { colorScheme == .dark ? Brand.Dark.background : Brand.Light.background }
}

// MARK: - Brand Button Styles

struct BrandPrimaryButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    /// Bold near-black for light mode, light for dark mode
    private var buttonColor: Color {
        colorScheme == .dark ? Color(hex: "FAFAFA") : Color(hex: "0A0A0A")
    }

    private var textColor: Color {
        colorScheme == .dark ? Color(hex: "0A0A0A") : .white
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct BrandSecondaryButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? Brand.Dark.accent : Brand.Light.accent
    }

    private var bgColor: Color {
        colorScheme == .dark ? Brand.Dark.accentLight : Brand.Light.accentLight
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.medium))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusMedium))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandPrimaryButton {
    static var brandPrimary: BrandPrimaryButton { BrandPrimaryButton() }
}

extension ButtonStyle where Self == BrandSecondaryButton {
    static var brandSecondary: BrandSecondaryButton { BrandSecondaryButton() }
}
