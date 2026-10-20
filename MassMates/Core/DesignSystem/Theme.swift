import SwiftUI
import UIKit

enum LiturgicalColor: String, CaseIterable, Sendable, Equatable, Codable, Identifiable {
    case green
    case purple
    case white
    case red
    case rose

    var id: String { rawValue }

    var defaultSeasonName: String {
        switch self {
        case .green: "Tempo Comum"
        case .purple: "Quaresma e Advento"
        case .white: "Tempo Pascal e Solenidades"
        case .red: "Pentecostes e Mártires"
        case .rose: "Domingo da Alegria"
        }
    }
}

struct RGBAColor: Sendable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let hex: UInt32

    init(hex: UInt32) {
        self.hex = hex
        self.red = Double((hex >> 16) & 0xFF) / 255.0
        self.green = Double((hex >> 8) & 0xFF) / 255.0
        self.blue = Double(hex & 0xFF) / 255.0
    }

    var relativeLuminance: Double {
        let r = Self.linearize(red)
        let g = Self.linearize(green)
        let b = Self.linearize(blue)
        return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    }

    func contrastRatio(with other: RGBAColor) -> Double {
        let l1 = max(relativeLuminance, other.relativeLuminance)
        let l2 = min(relativeLuminance, other.relativeLuminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }

    private static func linearize(_ channel: Double) -> Double {
        channel <= 0.04045 ? (channel / 12.92) : pow((channel + 0.055) / 1.055, 2.4)
    }

    static func dynamicColor(light: RGBAColor, dark: RGBAColor) -> Color {
        Color(uiColor: UIColor { traits in
            let chosen = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: chosen.red, green: chosen.green, blue: chosen.blue, alpha: 1.0)
        })
    }
}

enum MassMatesPalette {
    static let bgLight = RGBAColor(hex: 0xFAF8F5)
    static let bgDark = RGBAColor(hex: 0x121110)
    static let surfaceLight = RGBAColor(hex: 0xFFFFFF)
    static let surfaceDark = RGBAColor(hex: 0x1B1A18)
    static let surfaceMutedLight = RGBAColor(hex: 0xF2EFEA)
    static let surfaceMutedDark = RGBAColor(hex: 0x242220)
    static let lineLight = RGBAColor(hex: 0xE7E3DC)
    static let lineDark = RGBAColor(hex: 0x33302C)
    static let textPrimaryLight = RGBAColor(hex: 0x1C1B19)
    static let textPrimaryDark = RGBAColor(hex: 0xF3F0EA)
    static let textSecondaryLight = RGBAColor(hex: 0x6B665E)
    static let textSecondaryDark = RGBAColor(hex: 0xA9A39A)
    static let textTertiaryLight = RGBAColor(hex: 0x9A948A)
    static let textTertiaryDark = RGBAColor(hex: 0x7A746B)
    static let onTintLight = RGBAColor(hex: 0xFFFFFF)
    static let onTintDark = RGBAColor(hex: 0x121110)

    static let bg = RGBAColor.dynamicColor(light: bgLight, dark: bgDark)
    static let surface = RGBAColor.dynamicColor(light: surfaceLight, dark: surfaceDark)
    static let surfaceMuted = RGBAColor.dynamicColor(light: surfaceMutedLight, dark: surfaceMutedDark)
    static let line = RGBAColor.dynamicColor(light: lineLight, dark: lineDark)
    static let textPrimary = RGBAColor.dynamicColor(light: textPrimaryLight, dark: textPrimaryDark)
    static let textSecondary = RGBAColor.dynamicColor(light: textSecondaryLight, dark: textSecondaryDark)
    static let textTertiary = RGBAColor.dynamicColor(light: textTertiaryLight, dark: textTertiaryDark)
    static let onTint = RGBAColor.dynamicColor(light: onTintLight, dark: onTintDark)

    static let success = RGBAColor.dynamicColor(light: RGBAColor(hex: 0x3F7D58), dark: RGBAColor(hex: 0x7CC096))
    static let warning = RGBAColor.dynamicColor(light: RGBAColor(hex: 0xB7791F), dark: RGBAColor(hex: 0xE3B25A))
    static let danger = RGBAColor.dynamicColor(light: RGBAColor(hex: 0xB3382E), dark: RGBAColor(hex: 0xE5857D))
    static let sponsored = RGBAColor.dynamicColor(light: RGBAColor(hex: 0x6B665E), dark: RGBAColor(hex: 0xA9A39A))

    static func tintRGBA(for season: LiturgicalColor, isDark: Bool) -> RGBAColor {
        switch (season, isDark) {
        case (.green, false): RGBAColor(hex: 0x4C7A5B)
        case (.green, true): RGBAColor(hex: 0x7FB08E)
        case (.purple, false): RGBAColor(hex: 0x6A4C8C)
        case (.purple, true): RGBAColor(hex: 0xB49AD6)
        case (.white, false): RGBAColor(hex: 0x7D6632)
        case (.white, true): RGBAColor(hex: 0xD2B976)
        case (.red, false): RGBAColor(hex: 0xA33F43)
        case (.red, true): RGBAColor(hex: 0xE08A8D)
        case (.rose, false): RGBAColor(hex: 0x9E4760)
        case (.rose, true): RGBAColor(hex: 0xE7A0B3)
        }
    }

    static func tintSoftRGBA(for season: LiturgicalColor, isDark: Bool) -> RGBAColor {
        switch (season, isDark) {
        case (.green, false): RGBAColor(hex: 0xE9F1EB)
        case (.green, true): RGBAColor(hex: 0x1C2A20)
        case (.purple, false): RGBAColor(hex: 0xEFEAF4)
        case (.purple, true): RGBAColor(hex: 0x262034)
        case (.white, false): RGBAColor(hex: 0xF4EFE2)
        case (.white, true): RGBAColor(hex: 0x2C2719)
        case (.red, false): RGBAColor(hex: 0xF5E9E9)
        case (.red, true): RGBAColor(hex: 0x321D1E)
        case (.rose, false): RGBAColor(hex: 0xF7ECEF)
        case (.rose, true): RGBAColor(hex: 0x331F26)
        }
    }
}

struct Theme: Sendable, Equatable {
    let season: LiturgicalColor

    var tint: Color {
        RGBAColor.dynamicColor(
            light: MassMatesPalette.tintRGBA(for: season, isDark: false),
            dark: MassMatesPalette.tintRGBA(for: season, isDark: true)
        )
    }

    var tintSoft: Color {
        RGBAColor.dynamicColor(
            light: MassMatesPalette.tintSoftRGBA(for: season, isDark: false),
            dark: MassMatesPalette.tintSoftRGBA(for: season, isDark: true)
        )
    }

    var onTint: Color {
        MassMatesPalette.onTint
    }
}

extension EnvironmentValues {
    @Entry var liturgicalTheme: Theme = Theme(season: .green)
}
