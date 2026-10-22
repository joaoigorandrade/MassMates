import SwiftUI

enum MassMatesFont {
    static let display = Font.system(size: 34, weight: .semibold, design: .serif)
    static let displayMobile = Font.system(size: 28, weight: .semibold, design: .serif)
    static let title = Font.system(size: 24, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let scripture = Font.system(size: 19, weight: .regular, design: .serif)
    static let scriptureEmphasis = Font.system(size: 19, weight: .regular, design: .serif).italic()
    static let callout = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let numeral = Font.system(size: 28, weight: .medium, design: .rounded)
    static let timerNumeral = Font.system(size: 56, weight: .medium, design: .rounded)

    static func customScripture(size: CGFloat, italic: Bool = false) -> Font {
        let base = Font.system(size: size, weight: .regular, design: .serif)
        return italic ? base.italic() : base
    }
}

enum MassMatesSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum MassMatesRadius {
    static let photo: CGFloat = 12
    static let button: CGFloat = 14
    static let card: CGFloat = 16
    static let sheet: CGFloat = 24
    static let chip: CGFloat = 999
}

enum MassMatesLayout {
    static let screenMargin: CGFloat = 20
    static let readingMargin: CGFloat = 24
    static let readingMaxWidth: CGFloat = 560
    static let minRowHeight: CGFloat = 56
    static let minTapTarget: CGFloat = 44
    static let progressBarHeight: CGFloat = 8
    static let primaryButtonHeight: CGFloat = 52
    static let streakRingStroke: CGFloat = 2.5
    static let timerRingStroke: CGFloat = 4
}
