import SwiftUI

struct CheckInDestinationCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let isLockedToPrivateDiary: Bool
    private let destinationMode: CheckInDestinationMode
    private let availableGroups: [CommunityGroup]
    private let selectedGroupIds: Set<String>
    private let activeStreakDays: Int
    private let onSelectMode: (CheckInDestinationMode) -> Void
    private let onToggleGroup: (String) -> Void

    // MARK: - Init
    init(
        isLockedToPrivateDiary: Bool, destinationMode: CheckInDestinationMode,
        availableGroups: [CommunityGroup], selectedGroupIds: Set<String>,
        activeStreakDays: Int = 14,
        onSelectMode: @escaping (CheckInDestinationMode) -> Void,
        onToggleGroup: @escaping (String) -> Void
    ) {
        self.isLockedToPrivateDiary = isLockedToPrivateDiary
        self.destinationMode = destinationMode
        self.availableGroups = availableGroups
        self.selectedGroupIds = selectedGroupIds
        self.activeStreakDays = activeStreakDays
        self.onSelectMode = onSelectMode
        self.onToggleGroup = onToggleGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            headerSection
            if !isLockedToPrivateDiary { modeSegmentedControl }
            cardContainer
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        Text("COMPARTILHAR COM")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .tracking(0.6)
    }

    private var modeSegmentedControl: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            modeButton(title: "Grupos", icon: "person.2", isSelected: destinationMode == .selectedGroups) {
                onSelectMode(.selectedGroups)
            }
            modeButton(title: "Pessoal", icon: "lock", isSelected: destinationMode == .privateDiaryOnly) {
                onSelectMode(.privateDiaryOnly)
            }
        }
    }

    private func modeButton(
        title: String, icon: String, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(MassMatesFont.callout).fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
            .background(isSelected ? theme.tintSoft.opacity(0.4) : MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.button).stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: isSelected ? 1.5 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var cardContainer: some View {
        VStack(spacing: 0) {
            if isLockedToPrivateDiary {
                lockedPrivateRow
            } else if destinationMode == .privateDiaryOnly {
                privateDiaryRow
            } else {
                groupRowsSection
            }
        }
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    @ViewBuilder
    private var groupRowsSection: some View {
        if availableGroups.isEmpty {
            emptyGroupsRow
        } else {
            ForEach(availableGroups) { group in
                let isSelected = selectedGroupIds.contains(group.id)
                Button { onToggleGroup(group.id) } label: {
                    HStack(spacing: MassMatesSpacing.sm) {
                        Image(systemName: "person.3").font(.system(size: 16)).foregroundStyle(theme.tint)
                        Text(group.name).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Toggle("", isOn: Binding(get: { isSelected }, set: { _ in onToggleGroup(group.id) }))
                            .labelsHidden().tint(theme.tint).allowsHitTesting(false)
                    }
                    .padding(.horizontal, MassMatesSpacing.md)
                    .padding(.vertical, MassMatesSpacing.xs)
                    .frame(minHeight: MassMatesLayout.minRowHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if group.id != availableGroups.last?.id {
                    Divider().overlay(MassMatesPalette.line)
                }
            }
        }
    }

    private var emptyGroupsRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "info.circle").foregroundStyle(MassMatesPalette.textSecondary)
            Text("Nenhum grupo ativo. O registro será pessoal.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privateDiaryRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "lock.shield.fill").font(.system(size: 16)).foregroundStyle(theme.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Salvo apenas no seu diário").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Visível unicamente para você com total sigilo.").font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 18)).foregroundStyle(theme.tint)
        }
        .padding(MassMatesSpacing.md)
        .frame(minHeight: MassMatesLayout.minRowHeight)
    }

    private var lockedPrivateRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "lock.shield.fill").font(.system(size: 16)).foregroundStyle(theme.tint)
                Text("Só no meu diário").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: "lock.fill").font(.system(size: 14)).foregroundStyle(MassMatesPalette.textTertiary)
            }
            Text("Por sigilo sacramental, confissões são mantidas privadas.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MassMatesSpacing.md)
        .padding(.vertical, MassMatesSpacing.sm)
        .frame(minHeight: MassMatesLayout.minRowHeight, alignment: .leading)
    }
}

#Preview("Check-In Destination Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CheckInDestinationCardView(
            isLockedToPrivateDiary: false,
            destinationMode: .selectedGroups,
            availableGroups: [CommunitySampleData.parishFraternity],
            selectedGroupIds: ["frat-sao-jose"],
            onSelectMode: { _ in },
            onToggleGroup: { _ in }
        )
    }
}
