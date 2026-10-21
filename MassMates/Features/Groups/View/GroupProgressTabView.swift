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
            GuardianAngelCardView(
                state: guardianAngelState,
                onOptIn: onOptInGuardianAngel,
                onSendPrayerNudge: onSendGuardianAngelNudge,
                onRevealCycle: onRevealGuardianAngelCycle
            )
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                    collectiveTreasureHeader
                    collectiveProgressBlock
                    Rectangle().fill(MassMatesPalette.line).frame(height: 1)
                    scoringModeSection
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var collectiveTreasureHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("TESOURO COLETIVO").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                Text(summary.collectiveGoalTitle)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Image(systemName: "rosette")
                .foregroundStyle(theme.tint)
                .frame(width: 36, height: 36)
                .background(theme.tintSoft)
                .clipShape(Circle())
        }
    }

    private var collectiveProgressBlock: some View {
        let remaining = max(summary.collectiveGoalTarget - summary.collectiveGoalCurrent, 0)
        return VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(summary.collectiveGoalCurrent)").font(MassMatesFont.numeral).foregroundStyle(theme.tint)
                Text("/ \(summary.collectiveGoalTarget)").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("\(Int(summary.collectiveProgressRatio * 100))% atingido")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            MassMatesProgressBar(progress: summary.collectiveProgressRatio)
            Label("Faltam \(remaining) para consagrar nosso compromisso comunitário.", systemImage: "person.2.wave.2")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var scoringModeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Label("Dias Fiéis na Caminhada", systemImage: "leaf")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(scoringBadgeText).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            if summary.scoringMode == .customPoints {
                customPointsLegendRow
            }
            ForEach(summary.orderedEntries) { entry in
                memberScoreRow(entry)
            }
        }
    }

    private var scoringBadgeText: String {
        switch summary.scoringMode {
        case .faithfulDays: "Constância diária"
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
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(MassMatesFont.caption)
                Text(entry.formattedScoreLabel(for: summary.scoringMode))
                    .font(MassMatesFont.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(theme.tint)
            .padding(.horizontal, MassMatesSpacing.xs)
            .padding(.vertical, 4)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
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
