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
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            collectiveGoalSection
            GuardianAngelCardView(
                state: guardianAngelState,
                onOptIn: onOptInGuardianAngel,
                onSendPrayerNudge: onSendGuardianAngelNudge,
                onRevealCycle: onRevealGuardianAngelCycle
            )
            memberConstancySection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var collectiveGoalSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Meta coletiva")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("\(Int(summary.collectiveProgressRatio * 100))%")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text("\(summary.collectiveGoalCurrent) / \(summary.collectiveGoalTarget) terços")
                .font(MassMatesFont.numeral)
                .foregroundStyle(MassMatesPalette.textPrimary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MassMatesPalette.line)
                        .frame(height: 6)
                    Capsule()
                        .fill(theme.tint)
                        .frame(width: proxy.size.width * summary.collectiveProgressRatio, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var memberConstancySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(scoringBadgeText)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.bottom, MassMatesSpacing.xs)
            ForEach(summary.orderedEntries) { entry in
                memberRow(entry)
            }
        }
    }

    private func memberRow(_ entry: GroupMemberScoreEntry) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Text(entry.memberInitials)
                .font(Font.system(size: 13, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 32, height: 32)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Circle())
                .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
            Text(entry.memberName)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Text(scoreText(for: entry))
                .font(Font.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .frame(minHeight: MassMatesLayout.minRowHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    private func scoreText(for entry: GroupMemberScoreEntry) -> String {
        switch summary.scoringMode {
        case .faithfulDays:
            "\(entry.faithfulDaysCount) dias"
        case .collectiveTreasure:
            "\(entry.collectiveContributionsCount) terços"
        case .customPoints:
            "\(entry.customPointsTotal) pts"
        }
    }

    private var scoringBadgeText: String {
        switch summary.scoringMode {
        case .faithfulDays: "Constância diária"
        case .collectiveTreasure: "Comunhão sem ranking"
        case .customPoints: "Pontuação por prática"
        }
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
        .padding()
    }
}
