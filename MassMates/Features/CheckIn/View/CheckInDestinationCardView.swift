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
        isLockedToPrivateDiary: Bool,
        destinationMode: CheckInDestinationMode,
        availableGroups: [CommunityGroup],
        selectedGroupIds: Set<String>,
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
            Text("ENVIAR PARA")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)

            checklistContainer
        }
    }

    // MARK: - Subviews / Private Helpers
    private var checklistContainer: some View {
        VStack(spacing: 0) {
            if !isLockedToPrivateDiary {
                ForEach(availableGroups) { group in
                    groupRow(group)
                    Divider().overlay(MassMatesPalette.line)
                }
            }
            privateDiaryRow
        }
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private func groupRow(_ group: CommunityGroup) -> some View {
        let isSelected = destinationMode == .selectedGroups && selectedGroupIds.contains(group.id)
        return Button {
            onToggleGroup(group.id)
        } label: {
            HStack {
                Text(group.name)
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                selectionIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var privateDiaryRow: some View {
        let isSelected = isLockedToPrivateDiary || destinationMode == .privateDiaryOnly
        return Button {
            onSelectMode(.privateDiaryOnly)
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "lock")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("Somente no meu Diário")
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                selectionIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        if isSelected {
            Circle()
                .fill(theme.tint)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.onTint)
                )
        } else {
            Circle()
                .stroke(MassMatesPalette.line, lineWidth: 1.5)
                .frame(width: 20, height: 20)
        }
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
