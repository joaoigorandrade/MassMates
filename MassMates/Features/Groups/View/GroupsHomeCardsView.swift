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
            Text(title)
                .font(MassMatesFont.callout)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
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
        challenges: [FeaturedChallenge],
        onBack: @escaping () -> Void,
        onJoinChallenge: @escaping (String) -> Void = { _ in },
        onOpenGroup: @escaping (CommunityGroup) -> Void = { _ in }
    ) {
        self.challenges = challenges
        self.onBack = onBack
        self.onJoinChallenge = onJoinChallenge
        self.onOpenGroup = onOpenGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            captionLabel
            challengesList
            Spacer()
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: 36, height: 36, alignment: .leading)
            }
            .buttonStyle(.plain)
            Text("Desafios Sazonais").font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
        }
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private var captionLabel: some View {
        Text("TEMPO LITÚRGICO · INICIATIVAS")
            .font(MassMatesFont.caption).fontWeight(.semibold)
            .foregroundStyle(MassMatesPalette.textSecondary).tracking(0.8)
            .padding(.bottom, MassMatesSpacing.sm)
    }

    private var challengesList: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            ForEach(Array(challenges.prefix(3))) { challenge in
                challengeRow(challenge: challenge)
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            }
        }
    }

    private func challengeRow(challenge: FeaturedChallenge) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MassMatesSpacing.xs) {
                    Text(challenge.group.name).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary).lineLimit(1)
                    if challenge.group.sponsorName != nil {
                        Text("Patrocinado")
                            .font(.system(size: 9, weight: .semibold)).foregroundStyle(MassMatesPalette.textSecondary)
                            .padding(.horizontal, 4).padding(.vertical, 1).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: 3))
                    }
                }
                Text("\(challenge.durationLabel) · \(challenge.group.memberCount) membros")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            actionButton(for: challenge)
        }
        .frame(height: 64)
    }

    private func actionButton(for challenge: FeaturedChallenge) -> some View {
        Button {
            challenge.isJoined ? onOpenGroup(challenge.group) : onJoinChallenge(challenge.id)
        } label: {
            Text(challenge.isJoined ? "Ver" : "Participar")
                .font(MassMatesFont.caption).fontWeight(.semibold)
                .foregroundStyle(challenge.isJoined ? MassMatesPalette.textPrimary : theme.onTint)
                .padding(.horizontal, MassMatesSpacing.sm).padding(.vertical, MassMatesSpacing.xs)
                .background(challenge.isJoined ? MassMatesPalette.surfaceMuted : theme.tint)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct GroupsCapacityCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let capacity: GroupSlotCapacity
    private let onUnlockSlot: () -> Void

    // MARK: - Init
    init(capacity: GroupSlotCapacity, onUnlockSlot: @escaping () -> Void = {}) {
        self.capacity = capacity
        self.onUnlockSlot = onUnlockSlot
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack {
            Text("\(capacity.personalGroupCount) de \(capacity.maxAllowedPersonalGroups) vagas")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            if !capacity.hasRewardedSlotUnlocked {
                Button("Desbloquear", action: onUnlockSlot)
                    .font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
        }
    }
}

#Preview("Groups Home Cards — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupsBottomActionsView(onEnterCode: {}, onCreateGroup: {})
            .padding()
    }
}
