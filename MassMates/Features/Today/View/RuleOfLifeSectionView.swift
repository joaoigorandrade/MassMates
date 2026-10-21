import SwiftUI

struct RuleOfLifeSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let progress: TodayProgressSummary
    private let onSelectPreset: (RuleOfLifePreset) -> Void
    private let onTogglePractice: (SpiritualPractice) -> Void

    // MARK: - Init
    init(
        progress: TodayProgressSummary,
        onSelectPreset: @escaping (RuleOfLifePreset) -> Void,
        onTogglePractice: @escaping (SpiritualPractice) -> Void
    ) {
        self.progress = progress
        self.onSelectPreset = onSelectPreset
        self.onTogglePractice = onTogglePractice
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader
            MassMatesProgressBar(progress: progress.ruleCompletionRatio)
                .padding(.bottom, MassMatesSpacing.xxs)
            checklistStack
        }
        .sensoryFeedback(.impact(weight: .light), trigger: progress.completedCount)
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Regra de Vida")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Constância nas pequenas virtudes")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            presetMenuBadge
        }
    }

    private var presetMenuBadge: some View {
        Menu {
            ForEach(RuleOfLifePreset.allCases) { preset in
                Button {
                    onSelectPreset(preset)
                } label: {
                    if progress.selectedPreset == preset {
                        Label(preset.title, systemImage: "checkmark")
                    } else {
                        Text(preset.title)
                    }
                }
            }
        } label: {
            Text("\(progress.completedCount) de \(progress.totalCount) concluídas")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
        }
    }

    private var checklistStack: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            ForEach(progress.items) { item in
                practiceRow(item)
            }
        }
    }

    private func practiceRow(_ item: RuleOfLifeItem) -> some View {
        Button {
            onTogglePractice(item.practice)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                leadingStatusCircle(for: item)
                VStack(alignment: .leading, spacing: 2) {
                    practiceTitleRow(item)
                    Text(item.practice.subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(
                            item.isCompleted ? MassMatesPalette.textTertiary : MassMatesPalette.textSecondary
                        )
                        .lineLimit(1)
                }
                Spacer(minLength: MassMatesSpacing.xs)
                Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(item.isCompleted ? theme.tint : MassMatesPalette.line)
            }
            .padding(MassMatesSpacing.sm)
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: MassMatesRadius.card)
                    .stroke(MassMatesPalette.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func leadingStatusCircle(for item: RuleOfLifeItem) -> some View {
        ZStack {
            Circle()
                .fill(item.isCompleted ? theme.tint : MassMatesPalette.surfaceMuted)
                .frame(width: 28, height: 28)
            Image(systemName: item.isCompleted ? "checkmark" : item.practice.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(item.isCompleted ? theme.onTint : MassMatesPalette.textTertiary)
        }
    }

    private func practiceTitleRow(_ item: RuleOfLifeItem) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Text(item.practice.title)
                .font(MassMatesFont.headline)
                .strikethrough(item.isCompleted, color: MassMatesPalette.textSecondary)
                .foregroundStyle(
                    item.isCompleted ? MassMatesPalette.textSecondary : MassMatesPalette.textPrimary
                )
                .lineLimit(1)
            if item.practice.isStrictlyPrivate {
                Image(systemName: "lock.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .accessibilityLabel("Privado no dispositivo")
            }
        }
    }
}

#Preview("Rule of Life Section — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        RuleOfLifeSectionView(
            progress: LocalRuleOfLifeService(initialCompleted: [.dailyGospel]).loadTodayProgress(),
            onSelectPreset: { _ in },
            onTogglePractice: { _ in }
        )
    }
}
