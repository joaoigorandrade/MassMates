import SwiftUI

struct CheckInDestinationCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let isLockedToPrivateDiary: Bool
    private let destinationMode: CheckInDestinationMode
    private let availableGroups: [CommunityGroup]
    private let selectedGroupIds: Set<String>
    private let onSelectMode: (CheckInDestinationMode) -> Void
    private let onToggleGroup: (String) -> Void

    // MARK: - Init
    init(
        isLockedToPrivateDiary: Bool,
        destinationMode: CheckInDestinationMode,
        availableGroups: [CommunityGroup],
        selectedGroupIds: Set<String>,
        onSelectMode: @escaping (CheckInDestinationMode) -> Void,
        onToggleGroup: @escaping (String) -> Void
    ) {
        self.isLockedToPrivateDiary = isLockedToPrivateDiary
        self.destinationMode = destinationMode
        self.availableGroups = availableGroups
        self.selectedGroupIds = selectedGroupIds
        self.onSelectMode = onSelectMode
        self.onToggleGroup = onToggleGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Destino do Check-In")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                if isLockedToPrivateDiary {
                    Label("A Confissão é bloqueada para “Apenas no Meu Diário Privado” e nunca é publicada em grupos.", systemImage: "lock.shield")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(theme.tint)
                } else {
                    destinationModeButtons
                    if destinationMode == .selectedGroups {
                        ForEach(availableGroups) { group in
                            groupDestinationRow(group)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var destinationModeButtons: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(CheckInDestinationMode.allCases) { mode in
                let isSelected = destinationMode == mode
                Button {
                    onSelectMode(mode)
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                        .padding(.horizontal, MassMatesSpacing.xs)
                        .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                        .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func groupDestinationRow(_ group: CommunityGroup) -> some View {
        let isSelected = selectedGroupIds.contains(group.id)
        return Button {
            onToggleGroup(group.id)
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                Text(group.name)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(group.sharingRequirement.badgeText)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
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
