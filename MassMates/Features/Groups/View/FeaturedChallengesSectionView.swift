import Navigation
import SwiftUI

private struct SeasonalInitiative: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let isSponsored: Bool
    let sponsorName: String?
}

struct FeaturedChallengesSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var joinedIds: Set<String>
    private let challenges: [FeaturedChallenge]
    private let showsBackButton: Bool
    private let onJoinChallenge: ((String) -> Void)?
    private let onOpenGroup: ((CommunityGroup) -> Void)?
    private let onBack: (() -> Void)?

    private let initiatives: [SeasonalInitiative] = [
        SeasonalInitiative(id: "chal-aparecida", title: "Novena de N. Sra. Aparecida", subtitle: "9 dias · começa 3 out", isSponsored: false, sponsorName: nil),
        SeasonalInitiative(id: "chal-quaresma", title: "Quaresma Arquidiocesana", subtitle: "40 dias · 1.240 inscritos", isSponsored: false, sponsorName: nil),
        SeasonalInitiative(id: "chal-rosario", title: "Rosário de Outubro", subtitle: "31 dias", isSponsored: true, sponsorName: "Patrocinado · Editora Ave")
    ]

    // MARK: - Init
    init(
        challenges: [FeaturedChallenge] = [],
        showsBackButton: Bool = true,
        onJoinChallenge: ((String) -> Void)? = nil,
        onOpenGroup: ((CommunityGroup) -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.challenges = challenges
        self.showsBackButton = showsBackButton
        self.onJoinChallenge = onJoinChallenge
        self.onOpenGroup = onOpenGroup
        self.onBack = onBack
        self._joinedIds = State(initialValue: Set(challenges.filter(\.isJoined).map(\.id)))
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsBackButton { backBar }
            headerSection
            initiativesList
            Spacer()
            footerCaption
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var backBar: some View {
        Button {
            if let onBack { onBack() } else { dismiss() }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.top, MassMatesSpacing.xs)
    }

    private var headerSection: some View {
        Text("Desafios Sazonais")
            .font(MassMatesFont.displayMobile)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .padding(.top, showsBackButton ? MassMatesSpacing.xs : 0)
            .padding(.bottom, MassMatesSpacing.lg)
    }

    private var initiativesList: some View {
        VStack(spacing: 0) {
            hairlineDivider
            ForEach(initiatives) { initiative in
                initiativeRow(initiative)
                hairlineDivider
            }
        }
    }

    private var hairlineDivider: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }

    private func initiativeRow(_ initiative: SeasonalInitiative) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(initiative.title)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineLimit(1)
                subtitleView(for: initiative)
            }
            Spacer()
            joinButton(for: initiative)
        }
        .frame(minHeight: 72)
    }

    @ViewBuilder
    private func subtitleView(for initiative: SeasonalInitiative) -> some View {
        if initiative.isSponsored, let sponsor = initiative.sponsorName {
            HStack(spacing: 4) {
                Text(initiative.subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                Text("·").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                Text(sponsor).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.sponsored)
            }
        } else {
            Text(initiative.subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func joinButton(for initiative: SeasonalInitiative) -> some View {
        let isJoined = joinedIds.contains(initiative.id)
        return Button {
            guard !isJoined else { return }
            joinedIds.insert(initiative.id)
            onJoinChallenge?(initiative.id)
        } label: {
            Text(isJoined ? "Inscrito" : "Participar")
                .font(MassMatesFont.callout)
                .fontWeight(.medium)
                .foregroundStyle(isJoined ? MassMatesPalette.textTertiary : theme.tint)
                .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget, alignment: .trailing)
        }
        .buttonStyle(.plain)
    }

    private var footerCaption: some View {
        Text("Desafios em destaque usam sua vaga sazonal.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.bottom, MassMatesSpacing.md)
    }
}

#Preview("Featured Challenges — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        FeaturedChallengesSectionView()
    }
}
