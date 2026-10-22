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
            checklistStack
        }
        .sensoryFeedback(.impact(weight: .light), trigger: progress.completedCount)
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack(alignment: .center) {
            Text("Regra de Vida")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            presetMenuBadge
        }
        .padding(.bottom, MassMatesSpacing.xxs)
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
            HStack(spacing: MassMatesSpacing.xs) {
                Text("\(progress.completedCount) de \(progress.totalCount)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                progressRing
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Regra de vida: \(progress.completedCount) de \(progress.totalCount) concluídas")
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(MassMatesPalette.line, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress.ruleCompletionRatio)
                .stroke(
                    theme.tint,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 20, height: 20)
    }

    private var checklistStack: some View {
        VStack(spacing: 0) {
            hairlineDivider
            ForEach(progress.items) { item in
                practiceRow(item)
                hairlineDivider
            }
        }
    }

    private func practiceRow(_ item: RuleOfLifeItem) -> some View {
        Button {
            onTogglePractice(item.practice)
        } label: {
            HStack {
                Text(practiceTitle(for: item.practice))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                if item.practice.isStrictlyPrivate {
                    Image(systemName: "lock.fill")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                checkmarkCircle(isCompleted: item.isCompleted)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(practiceTitle(for: item.practice)), \(item.isCompleted ? "concluído" : "não concluído")")
        .accessibilityAddTraits(item.isCompleted ? [.isSelected] : [])
    }

    @ViewBuilder
    private func checkmarkCircle(isCompleted: Bool) -> some View {
        if isCompleted {
            ZStack {
                Circle()
                    .fill(theme.tint)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.onTint)
            }
            .frame(width: 20, height: 20)
        } else {
            Circle()
                .stroke(MassMatesPalette.line, lineWidth: 1)
                .frame(width: 20, height: 20)
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private func practiceTitle(for practice: SpiritualPractice) -> String {
        switch practice {
        case .dailyGospel: "Evangelho do Dia"
        default: practice.title
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
