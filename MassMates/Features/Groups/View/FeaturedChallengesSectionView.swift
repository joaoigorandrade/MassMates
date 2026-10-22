import SwiftUI

struct FeaturedChallengesSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let challenges: [FeaturedChallenge]
    private let onJoinChallenge: (String) -> Void
    private let onOpenGroup: (CommunityGroup) -> Void

    // MARK: - Init
    init(
        challenges: [FeaturedChallenge],
        onJoinChallenge: @escaping (String) -> Void,
        onOpenGroup: @escaping (CommunityGroup) -> Void
    ) {
        self.challenges = challenges
        self.onJoinChallenge = onJoinChallenge
        self.onOpenGroup = onOpenGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            sectionHeader
            challengesList
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Desafios")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
        }
        .padding(.bottom, MassMatesSpacing.xxs)
    }

    private var challengesList: some View {
        VStack(spacing: 0) {
            hairlineDivider
            ForEach(Array(challenges.prefix(2).enumerated()), id: \.element.id) { index, challenge in
                challengeRow(challenge: challenge)
                if index < min(challenges.count, 2) - 1 {
                    hairlineDivider
                }
            }
            hairlineDivider
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private func challengeRow(challenge: FeaturedChallenge) -> some View {
        Button {
            if challenge.isJoined {
                onOpenGroup(challenge.group)
            } else {
                onJoinChallenge(challenge.id)
            }
        } label: {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                challengeHeader(challenge: challenge)
                MassMatesProgressBar(progress: challenge.group.collectiveGoalProgress)
                challengeFooter(challenge: challenge)
            }
            .padding(.vertical, MassMatesSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func challengeHeader(challenge: FeaturedChallenge) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(challenge.group.name)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(challenge.durationLabel.isEmpty ? "Dia 12 de 40" : challenge.durationLabel)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func challengeFooter(challenge: FeaturedChallenge) -> some View {
        HStack {
            Text("\(challenge.group.memberCount) participantes")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Text(challenge.isJoined ? "Ver Desafio" : "Participar")
                .font(MassMatesFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.tint)
        }
    }
}

#Preview("Featured Challenges — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        FeaturedChallengesSectionView(
            challenges: LocalCommunityGroupsService.sampleFeaturedChallenges(),
            onJoinChallenge: { _ in },
            onOpenGroup: { _ in }
        )
    }
}
