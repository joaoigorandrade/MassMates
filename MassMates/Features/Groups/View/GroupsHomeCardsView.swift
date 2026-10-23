import SwiftUI

struct GroupsBottomActionsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let onEnterCode: () -> Void
    private let onCreateGroup: () -> Void

    // MARK: - Init
    init(onEnterCode: @escaping () -> Void, onCreateGroup: @escaping () -> Void) {
        self.onEnterCode = onEnterCode
        self.onCreateGroup = onCreateGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack(spacing: 0) {
            actionButton(title: "Entrar com código", color: MassMatesPalette.textSecondary, action: onEnterCode)
            Rectangle().fill(MassMatesPalette.line).frame(width: 1, height: 22)
            actionButton(title: "Criar grupo", color: theme.tint, action: onCreateGroup)
        }
        .frame(height: 48)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    // MARK: - Subviews / Private Helpers
    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(MassMatesFont.callout).fontWeight(.medium).foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DiscoverChallengesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let challenges: [FeaturedChallenge]
    private let onBack: () -> Void
    private let onJoinChallenge: (String) -> Void
    private let onOpenGroup: (CommunityGroup) -> Void

    // MARK: - Init
    init(
        challenges: [FeaturedChallenge], onBack: @escaping () -> Void,
        onJoinChallenge: @escaping (String) -> Void = { _ in }, onOpenGroup: @escaping (CommunityGroup) -> Void = { _ in }
    ) {
        self.challenges = Array(challenges.prefix(3))
        self.onBack = onBack
        self.onJoinChallenge = onJoinChallenge
        self.onOpenGroup = onOpenGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            Text("Desafios Sazonais").font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            captionLabel
            challengesList
            Spacer()
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    Text("Voltar aos meus grupos").font(MassMatesFont.callout)
                }
                .foregroundStyle(theme.tint)
                .frame(minHeight: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voltar aos meus grupos")
            Spacer()
        }
        .padding(.bottom, MassMatesSpacing.xxs)
    }

    private var captionLabel: some View {
        Text("TEMPO LITÚRGICO · INICIATIVAS").font(MassMatesFont.caption).fontWeight(.semibold)
            .foregroundStyle(MassMatesPalette.textSecondary).tracking(0.8).padding(.bottom, MassMatesSpacing.sm)
    }

    private var challengesList: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            ForEach(challenges) { challenge in
                DiscoverChallengeRowView(
                    challenge: challenge,
                    onJoin: { onJoinChallenge(challenge.id) },
                    onOpen: { onOpenGroup(challenge.group) }
                )
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            }
        }
    }
}

struct DiscoverChallengeRowView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let challenge: FeaturedChallenge
    private let onJoin: () -> Void
    private let onOpen: () -> Void

    // MARK: - Init
    init(challenge: FeaturedChallenge, onJoin: @escaping () -> Void, onOpen: @escaping () -> Void) {
        self.challenge = challenge
        self.onJoin = onJoin
        self.onOpen = onOpen
    }

    nonisolated static func == (lhs: DiscoverChallengeRowView, rhs: DiscoverChallengeRowView) -> Bool {
        lhs.challenge == rhs.challenge
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: MassMatesSpacing.xs) {
                        Text(challenge.group.name).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary).lineLimit(1)
                        if challenge.group.sponsorName != nil {
                            Text("Patrocinado").font(.system(size: 9, weight: .semibold)).foregroundStyle(MassMatesPalette.textSecondary)
                                .padding(.horizontal, 4).padding(.vertical, 1).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: 3))
                        }
                    }
                    Text("\(challenge.durationLabel) · \(challenge.group.memberCount) membros")
                        .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: challenge.isJoined ? onOpen : onJoin) {
                Text(challenge.isJoined ? "Ver" : "Entrar no desafio").font(MassMatesFont.caption).fontWeight(.semibold)
                    .foregroundStyle(challenge.isJoined ? MassMatesPalette.textPrimary : theme.onTint)
                    .padding(.horizontal, MassMatesSpacing.sm).padding(.vertical, MassMatesSpacing.xs)
                    .background(challenge.isJoined ? MassMatesPalette.surfaceMuted : theme.tint).clipShape(Capsule())
            }
            .buttonStyle(.plain).accessibilityLabel(challenge.isJoined ? "Ver desafio" : "Entrar no desafio")
        }
        .frame(height: 64)
    }

    // MARK: - Subviews / Private Helpers
}

struct GroupsCapacityCardView: View {
    @Environment(\.liturgicalTheme) private var theme
    let capacity: GroupSlotCapacity
    var onUnlockSlot: () -> Void = {}

    var body: some View {
        HStack {
            Text("\(capacity.personalGroupCount) de \(capacity.maxAllowedPersonalGroups) vagas")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            if !capacity.hasRewardedSlotUnlocked {
                Button("Desbloquear", action: onUnlockSlot).font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
        }
    }
}

#Preview("Groups Home Cards — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupsBottomActionsView(onEnterCode: {}, onCreateGroup: {}).padding()
    }
}
