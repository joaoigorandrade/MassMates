import SwiftUI

struct RuleOfLifeRowView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    let item: DailyRuleChecklistItem
    let onToggle: () -> Void

    // MARK: - Init
    init(item: DailyRuleChecklistItem, onToggle: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: MassMatesSpacing.sm) {
                circularToggle
                Text(item.title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                trailingLabel
            }
            .frame(height: MassMatesLayout.minRowHeight).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(item.isCompleted ? "concluído" : "pendente")")
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var circularToggle: some View {
        if item.isCompleted {
            ZStack {
                Circle().fill(theme.tint)
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(theme.onTint)
            }.frame(width: 24, height: 24)
        } else {
            Circle().stroke(MassMatesPalette.textTertiary, lineWidth: 1).frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    private var trailingLabel: some View {
        if item.isCompleted {
            Text("Feito").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        } else if let schedule = item.schedule, !schedule.isEmpty {
            Text(schedule).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textTertiary)
        }
    }
}
