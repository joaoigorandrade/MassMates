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
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("DESTINO DA PUBLICAÇÃO")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .tracking(0.5)
                if isLockedToPrivateDiary {
                    lockedPrivateDestinationCard
                } else {
                    selectableDestinationContent
                }
            }
            streakSoftConfirmationRow
        }
    }

    // MARK: - Subviews / Private Helpers
    private var streakSoftConfirmationRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            ZStack {
                Circle().stroke(MassMatesPalette.line, lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(theme.tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(activeStreakDays)d")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            .frame(width: 36, height: 36)
            Text("Mais um dia em oração. Sua chama e regra de vida serão atualizadas sem expor detalhes deste sacramento.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var lockedPrivateDestinationCard: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "lock.fill")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 32, height: 32)
                .background(MassMatesPalette.surface)
                .clipShape(.circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Apenas no Meu Diário Espiritual (Privado)")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Grupos públicos desabilitados para esta prática.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var selectableDestinationContent: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                destinationModeButtons
                if destinationMode == .selectedGroups {
                    ForEach(availableGroups) { group in
                        groupDestinationRow(group)
                    }
                }
            }
        }
    }

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
