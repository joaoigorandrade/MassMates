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
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader
            ForEach(challenges) { challenge in
                challengeCard(for: challenge)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Desafios em destaque")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("1 vaga sazonal oficial gratuita além dos seus 2 grupos pessoais.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func challengeCard(for challenge: FeaturedChallenge) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                sponsorAndBadgeRow(for: challenge)
                Text(challenge.group.name)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(challenge.subtitle)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                progressBar(value: challenge.group.collectiveGoalProgress)
                actionRow(for: challenge)
            }
        }
    }

    private func sponsorAndBadgeRow(for challenge: FeaturedChallenge) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text(challenge.durationLabel)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            if let sponsor = challenge.group.sponsorName {
                Text("Patrocinado • \(sponsor)")
                    .font(MassMatesFont.caption)
                    .tracking(0.48)
                    .foregroundStyle(MassMatesPalette.sponsored)
            }
            Spacer()
        }
    }

    private func progressBar(value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MassMatesPalette.surfaceMuted)
                Capsule()
                    .fill(theme.tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: MassMatesLayout.progressBarHeight)
    }

    private func actionRow(for challenge: FeaturedChallenge) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            if let coupon = challenge.group.sponsorCoupon {
                Text("Cupom: \(coupon)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            if challenge.isJoined {
                MassMatesSecondaryButton(title: "Abrir desafio", systemImage: "arrow.right") {
                    onOpenGroup(challenge.group)
                }
                .frame(maxWidth: 180)
            } else {
                MassMatesPrimaryButton(title: "Participar", systemImage: "person.badge.plus") {
                    onJoinChallenge(challenge.id)
                }
                .frame(maxWidth: 180)
            }
        }
    }
}

#Preview("Featured Challenges — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        FeaturedChallengesSectionView(
            challenges: LocalCommunityGroupsService().featuredChallenges(),
            onJoinChallenge: { _ in },
            onOpenGroup: { _ in }
        )
    }
}
