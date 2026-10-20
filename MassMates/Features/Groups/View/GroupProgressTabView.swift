import SwiftUI

struct GroupProgressTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let summary: GroupScoringSummary
    private let guardianAngelState: GuardianAngelState
    private let onOptInGuardianAngel: () -> Void
    private let onSendGuardianAngelNudge: () -> Void
    private let onRevealGuardianAngelCycle: () -> Void

    // MARK: - Init
    init(
        summary: GroupScoringSummary,
        guardianAngelState: GuardianAngelState,
        onOptInGuardianAngel: @escaping () -> Void,
        onSendGuardianAngelNudge: @escaping () -> Void,
        onRevealGuardianAngelCycle: @escaping () -> Void
    ) {
        self.summary = summary
        self.guardianAngelState = guardianAngelState
        self.onOptInGuardianAngel = onOptInGuardianAngel
        self.onSendGuardianAngelNudge = onSendGuardianAngelNudge
        self.onRevealGuardianAngelCycle = onRevealGuardianAngelCycle
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            collectiveGoalCard
            GuardianAngelCardView(
                state: guardianAngelState,
                onOptIn: onOptInGuardianAngel,
                onSendPrayerNudge: onSendGuardianAngelNudge,
                onRevealCycle: onRevealGuardianAngelCycle
            )
            scoringModeSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var collectiveGoalCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                        Text("Meta Comunitária • \(theme.season.defaultSeasonName)")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(theme.tint)
                        Text(summary.collectiveGoalTitle)
                            .font(MassMatesFont.headline)
                            .foregroundStyle(MassMatesPalette.textPrimary)
                    }
                    Spacer()
                    Text("\(summary.collectiveGoalCurrent)/\(summary.collectiveGoalTarget)")
                        .font(MassMatesFont.numeral)
                        .foregroundStyle(theme.tint)
                }
                MassMatesProgressBar(progress: summary.collectiveProgressRatio)
            }
        }
    }

    private var scoringModeSection: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    Text(summary.scoringMode.title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text(scoringBadgeText)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                Text(summary.scoringMode.descriptionText)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                if summary.scoringMode == .customPoints {
                    customPointsLegendRow
                }
                ForEach(summary.orderedEntries) { entry in
                    memberScoreRow(entry)
                }
            }
        }
    }

    private var scoringBadgeText: String {
        switch summary.scoringMode {
        case .faithfulDays: "1 pt / dia ativo"
        case .collectiveTreasure: "Comunhão sem ranking"
        case .customPoints: "Pontuação por prática"
        }
    }

    private var customPointsLegendRow: some View {
        Text("Santa Missa 30 pts • Adoração/Jejum 25 pts • Terço/Oração 20 pts • Evangelho 10 pts")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .padding(MassMatesSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private func memberScoreRow(_ entry: GroupMemberScoreEntry) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Text(entry.memberInitials)
                .font(MassMatesFont.caption)
                .foregroundStyle(entry.isCurrentUser ? theme.onTint : theme.tint)
                .frame(width: 34, height: 34)
                .background(entry.isCurrentUser ? theme.tint : theme.tintSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.memberName)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(entry.hasRecordedPracticeToday ? "Mais um dia em oração" : "Em caminhada fraterna")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Text(entry.formattedScoreLabel(for: summary.scoringMode))
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.tint)
        }
        .frame(minHeight: MassMatesLayout.minTapTarget)
    }
}

#Preview("Group Progress Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupProgressTabView(
            summary: CommunitySampleData.initialScoringSummary(
                for: CommunitySampleData.parishFraternity
            ),
            guardianAngelState: CommunitySampleData.initialGuardianAngelState(
                for: CommunitySampleData.parishFraternity
            ),
            onOptInGuardianAngel: {},
            onSendGuardianAngelNudge: {},
            onRevealGuardianAngelCycle: {}
        )
    }
}
