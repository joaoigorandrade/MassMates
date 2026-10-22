import SwiftUI

struct GroupIdentityBannerView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasCopiedInviteCode: Bool = false
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
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(2)
            metadataRow
        }
    }

    private var metadataRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("\(group.memberCount) membros · \(scoringBadgeText)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            if group.isCurrentUserAdmin && !group.inviteCode.isEmpty {
                adminInvitePill
            }
        }
    }

    private var adminInvitePill: some View {
        Button {
            UIPasteboard.general.string = group.inviteCode
            hasCopiedInviteCode = true
        } label: {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: hasCopiedInviteCode ? "checkmark" : "key.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .symbolEffect(.bounce, value: hasCopiedInviteCode)
                Text(hasCopiedInviteCode ? "Copiado" : group.inviteCode)
                    .font(MassMatesFont.caption)
            }
            .foregroundStyle(theme.tint)
            .padding(.horizontal, MassMatesSpacing.xs)
            .padding(.vertical, 3)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .overlay(
                Capsule().stroke(theme.tint.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: hasCopiedInviteCode)
        .accessibilityLabel("Código de convite: \(group.inviteCode)")
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
        .animation(reduceMotion ? .none : .snappy(duration: 0.2), value: selectedSubTab)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    private func tabButton(_ tab: GroupDetailSubTab) -> some View {
        let isSelected = selectedSubTab == tab
        return Button {
            withAnimation(reduceMotion ? .none : .snappy(duration: 0.2)) {
                onSelectSubTab(tab)
            }
        } label: {
            VStack(spacing: MassMatesSpacing.xs) {
                Text(tabTitle(tab))
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

    private func tabTitle(_ tab: GroupDetailSubTab) -> String {
        tab == .feed ? "Mural" : tab.title
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
