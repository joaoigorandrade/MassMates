import SwiftUI

struct ReactionPillButton: View, Equatable {
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let title: String
    private let systemImage: String
    private let count: Int
    private let isActive: Bool
    private let action: () -> Void

    init(
        title: String,
        systemImage: String,
        count: Int,
        isActive: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.count = count
        self.isActive = isActive
        self.action = action
    }

    nonisolated static func == (lhs: ReactionPillButton, rhs: ReactionPillButton) -> Bool {
        lhs.title == rhs.title &&
        lhs.systemImage == rhs.systemImage &&
        lhs.count == rhs.count &&
        lhs.isActive == rhs.isActive
    }

    var body: some View {
        Button(action: action) {
            pillContent
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(isActive ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay(borderOverlay)
                .scaleEffect(isActive && !reduceMotion ? 1.04 : 1.0)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.65),
                    value: isActive
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isActive)
        .accessibilityLabel("\(title), \(count)")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var pillContent: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(isActive ? theme.tint : MassMatesPalette.textSecondary)
                .symbolEffect(.bounce, value: reduceMotion ? false : isActive)
            Text(title)
                .font(MassMatesFont.caption)
                .foregroundStyle(isActive ? theme.tint : MassMatesPalette.textPrimary)
            if count > 0 {
                Text("\(count)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(isActive ? theme.tint : MassMatesPalette.textSecondary)
                    .contentTransition(.numericText())
            }
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.chip)
            .stroke(isActive ? theme.tint : MassMatesPalette.line, lineWidth: 1)
    }
}

#Preview("Reaction Pill Button — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HStack(spacing: MassMatesSpacing.xs) {
            ReactionPillButton(
                title: "Amém",
                systemImage: "hands.sparkles",
                count: 12,
                isActive: true
            ) {}
            ReactionPillButton(
                title: "Unidos em oração",
                systemImage: "heart",
                count: 5,
                isActive: false
            ) {}
        }
    }
}
