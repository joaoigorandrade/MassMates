import SwiftUI

struct GroupIdentityBannerView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let group: CommunityGroup
    private let scoringMode: GroupScoringMode
    private let selectedSubTab: GroupDetailSubTab
    private let onSelectSubTab: (GroupDetailSubTab) -> Void

    // MARK: - Init
    init(
        group: CommunityGroup,
        scoringMode: GroupScoringMode,
        selectedSubTab: GroupDetailSubTab,
        onSelectSubTab: @escaping (GroupDetailSubTab) -> Void
    ) {
        self.group = group
        self.scoringMode = scoringMode
        self.selectedSubTab = selectedSubTab
        self.onSelectSubTab = onSelectSubTab
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            headerSection
            subTabsBar
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(group.name)
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("\(group.memberCount) membros · \(scoringBadgeText)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var scoringBadgeText: String {
        switch scoringMode {
        case .faithfulDays: "Dias Fiéis"
        case .collectiveTreasure: "Tesouro Coletivo"
        case .customPoints: "Pontos por Prática"
        }
    }

    private var subTabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.lg) {
                ForEach(GroupDetailSubTab.allCases) { tab in
                    tabButton(tab)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    private func tabButton(_ tab: GroupDetailSubTab) -> some View {
        let isSelected = selectedSubTab == tab
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                onSelectSubTab(tab)
            }
        } label: {
            VStack(spacing: MassMatesSpacing.xs) {
                Text(tab.title)
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                    .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                Rectangle()
                    .fill(isSelected ? theme.tint : Color.clear)
                    .frame(height: 2)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Group Identity Banner — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupIdentityBannerView(
            group: CommunitySampleData.parishFraternity,
            scoringMode: .faithfulDays,
            selectedSubTab: .progress,
            onSelectSubTab: { _ in }
        )
        .padding()
    }
}
