import SwiftUI

struct ContinuousFraternitiesSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let groups: [CommunityGroup]
    private let onSelectGroup: (CommunityGroup) -> Void
    private let onDiscoverChallenges: () -> Void

    // MARK: - Init
    init(
        groups: [CommunityGroup],
        onSelectGroup: @escaping (CommunityGroup) -> Void,
        onDiscoverChallenges: @escaping () -> Void
    ) {
        self.groups = groups
        self.onSelectGroup = onSelectGroup
        self.onDiscoverChallenges = onDiscoverChallenges
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            hairlineDivider
            activeGroupsList
            discoveryRow
            hairlineDivider
        }
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var activeGroupsList: some View {
        let display = groups.prefix(3)
        if display.isEmpty {
            emptyGroupRow
            hairlineDivider
        } else {
            ForEach(display) { group in
                ContinuousFraternityRowView(group: group) {
                    onSelectGroup(group)
                }
                hairlineDivider
            }
        }
    }

    private var emptyGroupRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "person.2")
                .font(.system(size: 16))
                .foregroundStyle(MassMatesPalette.textTertiary)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Nenhuma fraternidade ativa")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Crie ou entre em um grupo abaixo")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
        }
        .frame(height: 64)
    }

    private var discoveryRow: some View {
        Button(action: onDiscoverChallenges) {
            HStack {
                Text("Descobrir desafios sazonais →")
                    .font(MassMatesFont.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.tint)
                Spacer()
            }
            .frame(height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var hairlineDivider: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }
}

private struct ContinuousFraternityRowView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    let group: CommunityGroup
    let onSelect: () -> Void

    nonisolated static func == (lhs: ContinuousFraternityRowView, rhs: ContinuousFraternityRowView) -> Bool {
        lhs.group == rhs.group
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: MassMatesSpacing.sm) {
                groupAvatar
                groupContent
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .frame(height: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var groupAvatar: some View {
        ZStack {
            Circle().fill(MassMatesPalette.surfaceMuted).frame(width: 36, height: 36)
            Image(systemName: symbolForGroup).font(.system(size: 16)).foregroundStyle(theme.tint)
        }
    }

    private var groupContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: MassMatesSpacing.xs) {
                Text(group.name).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary).lineLimit(1)
                if group.type == .challenge {
                    Text("Destaque").font(.system(size: 10, weight: .bold)).foregroundStyle(theme.tint)
                        .padding(.horizontal, 4).padding(.vertical, 1).background(theme.tintSoft).clipShape(.rect(cornerRadius: 3))
                }
            }
            Text("\(group.memberCount) membros · \(statusText)").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary).lineLimit(1)
        }
    }

    private var symbolForGroup: String {
        if group.id.contains("fatima") || group.name.contains("Fátima") { return "sparkles" }
        if group.id.contains("miguel") || group.name.contains("Miguel") { return "shield.fill" }
        return "person.2.fill"
    }

    private var statusText: String {
        if group.id == "frat-sao-jose" { return "Rezei hoje" }
        switch group.scoringMode {
        case .faithfulDays: return "Contínuo"
        case .collectiveTreasure: return "3 em oração"
        case .customPoints: return "Pontos"
        }
    }
}

#Preview("Continuous Fraternities — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ContinuousFraternitiesSectionView(
            groups: [
                CommunitySampleData.parishFraternity,
                CommunitySampleData.directoryGroups[0]
            ],
            onSelectGroup: { _ in },
            onDiscoverChallenges: {}
        )
    }
}
