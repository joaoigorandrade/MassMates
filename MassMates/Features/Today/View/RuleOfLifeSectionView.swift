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
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                sectionHeader
                progressBar
                presetSelectorRow
                checklistStack
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: progress.completedCount)
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Minha Regra de Vida")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("\(progress.completedCount) de \(progress.totalCount) práticas concluídas hoje")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MassMatesPalette.surfaceMuted)
                Capsule()
                    .fill(theme.tint)
                    .frame(width: proxy.size.width * progress.ruleCompletionRatio)
            }
        }
        .frame(height: MassMatesLayout.progressBarHeight)
    }

    private var presetSelectorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(RuleOfLifePreset.allCases) { preset in
                    presetChip(preset)
                }
            }
        }
    }

    private func presetChip(_ preset: RuleOfLifePreset) -> some View {
        let isSelected = progress.selectedPreset == preset
        return Button {
            onSelectPreset(preset)
        } label: {
            Text(preset.title)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay {
                    Capsule()
                        .stroke(isSelected ? theme.tint : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
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
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(MassMatesFont.title)
                    .foregroundStyle(item.isCompleted ? MassMatesPalette.success : MassMatesPalette.textSecondary)
                Image(systemName: item.practice.systemImage)
                    .foregroundStyle(item.isCompleted ? theme.tint : MassMatesPalette.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    practiceTitleRow(item.practice)
                    Text(item.practice.subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .background(item.isCompleted ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private func practiceTitleRow(_ practice: SpiritualPractice) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Text(practice.title)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
            if practice.isStrictlyPrivate {
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
