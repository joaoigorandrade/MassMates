import SwiftUI

struct CheckInPracticeTileView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let practice: SpiritualPractice
    let isSelected: Bool
    let onSelect: () -> Void

    // MARK: - Init
    init(practice: SpiritualPractice, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.practice = practice
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.practice == rhs.practice && lhs.isSelected == rhs.isSelected
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: practice.checkInIconName)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                        .symbolEffect(.bounce, value: isSelected)
                    Spacer()
                    if isSelected {
                        Circle().fill(theme.tint).frame(width: 8, height: 8)
                    } else if practice == .confession {
                        Text("PRIVADO").font(.system(size: 10, weight: .semibold)).foregroundStyle(MassMatesPalette.textTertiary)
                    }
                }
                Text(practice.checkInChipTitle)
                    .font(MassMatesFont.callout.weight(.medium))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineLimit(1)
            }
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(isSelected ? theme.tintSoft.opacity(0.4) : MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.button)
                    .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Rectangle())
            .scaleEffect(isSelected && !reduceMotion ? 1.02 : 1.0)
            .animation(reduceMotion ? .none : .snappy(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
