import SwiftUI

struct GroupProgressTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @State private var isShowingGuardianAngelDetails: Bool = false
    private let summary: GroupScoringSummary
    private let guardianAngelState: GuardianAngelState
    private let onOptInGuardianAngel: () -> Void
    private let onSendGuardianAngelNudge: () -> Void
    private let onRevealGuardianAngelCycle: () -> Void
    private let onOpenGuardianAngel: (() -> Void)?

    // MARK: - Init
    init(
        summary: GroupScoringSummary,
        guardianAngelState: GuardianAngelState,
        onOptInGuardianAngel: @escaping () -> Void,
        onSendGuardianAngelNudge: @escaping () -> Void,
        onRevealGuardianAngelCycle: @escaping () -> Void,
        onOpenGuardianAngel: (() -> Void)? = nil
    ) {
        self.summary = summary
        self.guardianAngelState = guardianAngelState
        self.onOptInGuardianAngel = onOptInGuardianAngel
        self.onSendGuardianAngelNudge = onSendGuardianAngelNudge
        self.onRevealGuardianAngelCycle = onRevealGuardianAngelCycle
        self.onOpenGuardianAngel = onOpenGuardianAngel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            collectiveGoalSection
            guardianAngelSummaryRow
            memberConstancySection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var collectiveGoalSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Text("META DO MÊS").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("\(Int(summary.collectiveProgressRatio * 100))%")
                    .font(MassMatesFont.caption).fontWeight(.medium).foregroundStyle(MassMatesPalette.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: MassMatesSpacing.xxs) {
                Text("\(summary.collectiveGoalCurrent)").font(MassMatesFont.numeral).foregroundStyle(MassMatesPalette.textPrimary)
                Text("/ \(summary.collectiveGoalTarget) \(unitLabel)").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            }
            progressBar
        }
    }

    private var unitLabel: String {
        summary.collectiveGoalTitle.isEmpty ? "Terços" : summary.collectiveGoalTitle
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(MassMatesPalette.line).frame(height: 6)
                Capsule().fill(theme.tint)
                    .frame(width: max(proxy.size.width * summary.collectiveProgressRatio, 0), height: 6)
                    .animation(.snappy(duration: 0.4), value: summary.collectiveProgressRatio)
            }
        }
        .frame(height: 6)
    }

    private var guardianAngelSummaryRow: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            guardianAngelButton
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            if isShowingGuardianAngelDetails {
                GuardianAngelCardView(
                    state: guardianAngelState,
                    onOptIn: onOptInGuardianAngel,
                    onSendPrayerNudge: onSendGuardianAngelNudge,
                    onRevealCycle: onRevealGuardianAngelCycle
                )
                .padding(.top, MassMatesSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var guardianAngelButton: some View {
        Button {
            if let onOpenGuardianAngel { onOpenGuardianAngel() } else {
                withAnimation(.snappy(duration: 0.25)) { isShowingGuardianAngelDetails.toggle() }
            }
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "wing").font(.system(size: 18)).foregroundStyle(MassMatesPalette.textSecondary)
                Text("Seu Anjo da Guarda").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .rotationEffect(.degrees(isShowingGuardianAngelDetails ? 90 : 0))
            }
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Seu Anjo da Guarda")
    }

    private var memberConstancySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CONSTÂNCIA")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.bottom, MassMatesSpacing.xs)
            ForEach(topMembers) { entry in
                memberRow(entry)
            }
        }
    }

    private var topMembers: [GroupMemberScoreEntry] {
        Array(summary.orderedEntries.prefix(5))
    }

    private func memberRow(_ entry: GroupMemberScoreEntry) -> some View {
        let isUser = entry.isCurrentUser
        return VStack(spacing: 0) {
            HStack(spacing: MassMatesSpacing.sm) {
                avatarView(for: entry)
                Text(isUser ? "Você" : entry.memberName)
                    .font(MassMatesFont.body).fontWeight(isUser ? .semibold : .regular)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(scoreText(for: entry))
                    .font(.system(size: 15, weight: isUser ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(isUser ? theme.tint : MassMatesPalette.textSecondary)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            if entry.id != topMembers.last?.id {
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            }
        }
    }

    private func avatarView(for entry: GroupMemberScoreEntry) -> some View {
        let isUser = entry.isCurrentUser
        return Text(entry.memberInitials)
            .font(.system(size: 13, weight: isUser ? .semibold : .medium))
            .foregroundStyle(isUser ? theme.tint : MassMatesPalette.textSecondary)
            .frame(width: 32, height: 32)
            .background(isUser ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(Circle())
    }

    private func scoreText(for entry: GroupMemberScoreEntry) -> String {
        switch summary.scoringMode {
        case .faithfulDays: "\(entry.faithfulDaysCount) \(entry.faithfulDaysCount == 1 ? "dia fiel" : "dias fiéis")"
        case .collectiveTreasure: "\(entry.collectiveContributionsCount) terços"
        case .customPoints: "\(entry.customPointsTotal) pts"
        }
    }
}

#Preview("Group Progress Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupProgressTabView(
            summary: CommunitySampleData.initialScoringSummary(for: CommunitySampleData.parishFraternity),
            guardianAngelState: CommunitySampleData.initialGuardianAngelState(for: CommunitySampleData.parishFraternity),
            onOptInGuardianAngel: {}, onSendGuardianAngelNudge: {}, onRevealGuardianAngelCycle: {}
        )
        .padding()
    }
}
