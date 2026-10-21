import SwiftUI

struct GroupIdentityBannerView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let group: CommunityGroup
    private let inviteCode: String
    private let selectedSubTab: GroupDetailSubTab
    private let onSelectSubTab: (GroupDetailSubTab) -> Void
    private let onToggleModeration: () -> Void

    // MARK: - Init
    init(
        group: CommunityGroup,
        inviteCode: String,
        selectedSubTab: GroupDetailSubTab,
        onSelectSubTab: @escaping (GroupDetailSubTab) -> Void,
        onToggleModeration: @escaping () -> Void
    ) {
        self.group = group
        self.inviteCode = inviteCode
        self.selectedSubTab = selectedSubTab
        self.onSelectSubTab = onSelectSubTab
        self.onToggleModeration = onToggleModeration
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            metadataRow
            Text(group.name)
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Homens e Mulheres de Oração reunidos no silêncio diário")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            subTabsBar
        }
    }

    // MARK: - Subviews / Private Helpers
    private var metadataRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            metadataPill {
                Circle().fill(theme.tint).frame(width: 6, height: 6)
                Text(group.type.title)
            }
            metadataPill {
                Image(systemName: "person.2")
                Text("\(group.memberCount) membros")
            }
            Spacer(minLength: 0)
            Menu {
                Text("Convite: \(inviteCode)")
                Button("Moderação & Segurança", systemImage: "shield.lefthalf.filled", action: onToggleModeration)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .accessibilityLabel("Mais opções do grupo")
        }
    }

    private func metadataPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) { content() }
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .padding(.horizontal, MassMatesSpacing.sm)
            .padding(.vertical, MassMatesSpacing.xxs)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
    }

    private var subTabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(GroupDetailSubTab.allCases) { tab in subTabCapsule(tab) }
            }
            .padding(.vertical, MassMatesSpacing.xxs)
        }
    }

    private func subTabCapsule(_ tab: GroupDetailSubTab) -> some View {
        let isSelected = selectedSubTab == tab
        return Button { onSelectSubTab(tab) } label: {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: tab.systemImage)
                Text(tab.title)
                if tab == .intentions {
                    Circle().fill(MassMatesPalette.warning).frame(width: 6, height: 6)
                }
            }
            .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
            .foregroundStyle(isSelected ? MassMatesPalette.surface : MassMatesPalette.textSecondary)
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(minHeight: 40)
            .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Group Identity Banner — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupIdentityBannerView(
            group: CommunitySampleData.parishFraternity,
            inviteCode: "482913",
            selectedSubTab: .progress,
            onSelectSubTab: { _ in },
            onToggleModeration: {}
        )
        .padding()
    }
}
