import SwiftUI

struct ContinuousFraternitiesSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let groups: [CommunityGroup]
    private let capacity: GroupSlotCapacity?
    private let onSelectGroup: (CommunityGroup) -> Void

    // MARK: - Init
    init(
        groups: [CommunityGroup],
        capacity: GroupSlotCapacity? = nil,
        onSelectGroup: @escaping (CommunityGroup) -> Void
    ) {
        self.groups = groups
        self.capacity = capacity
        self.onSelectGroup = onSelectGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            sectionHeader
            fraternitiesList
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Fraternidades")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            headerCapacityLabel
        }
        .padding(.bottom, MassMatesSpacing.xxs)
    }

    @ViewBuilder
    private var headerCapacityLabel: some View {
        if let capacity {
            Text("\(capacity.personalGroupCount) de \(capacity.maxAllowedPersonalGroups) vagas")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        } else {
            Text("\(groups.count) ativas")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var fraternitiesList: some View {
        VStack(spacing: 0) {
            hairlineDivider
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                groupRow(group: group)
                if index < groups.count - 1 {
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

    private func groupRow(group: CommunityGroup) -> some View {
        Button {
            onSelectGroup(group)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                groupAvatar(for: group)
                groupInfo(group: group)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .padding(.vertical, MassMatesSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func groupAvatar(for group: CommunityGroup) -> some View {
        ZStack {
            Circle()
                .fill(MassMatesPalette.surfaceMuted)
                .frame(width: 36, height: 36)
            Image(systemName: symbolForGroup(group))
                .font(.system(size: 16))
                .foregroundStyle(theme.tint)
        }
    }

    private func groupInfo(group: CommunityGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(group.name)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(1)
            Text("\(group.memberCount) irmãos · \(statusText(for: group))")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(1)
            if let window = group.challengeWindowLabel {
                Text(window)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private func symbolForGroup(_ group: CommunityGroup) -> String {
        if group.id.contains("fatima") || group.name.contains("Fátima") {
            return "sparkles"
        }
        if group.id.contains("miguel") || group.name.contains("Miguel") {
            return "shield.fill"
        }
        return "person.2.fill"
    }

    private func statusText(for group: CommunityGroup) -> String {
        if group.id == "frat-sao-jose" {
            return "Rezei hoje"
        }
        switch group.scoringMode {
        case .faithfulDays:
            return "Dias Fiéis"
        case .collectiveTreasure:
            return "3 em oração"
        case .customPoints:
            return "Pontos por Prática"
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
            capacity: LocalCommunityGroupsService.sampleSlotCapacity(),
            onSelectGroup: { _ in }
        )
    }
}
