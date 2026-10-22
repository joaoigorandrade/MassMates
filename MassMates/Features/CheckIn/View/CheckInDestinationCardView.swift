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
            Text("COMPARTILHAR COM")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.6)

            cardContainer
        }
    }

    // MARK: - Subviews / Private Helpers
    private var cardContainer: some View {
        VStack(spacing: 0) {
            if isLockedToPrivateDiary {
                lockedPrivateRow
            } else {
                groupRowsSection
                Divider().overlay(MassMatesPalette.line)
                diaryToggleRow
            }
        }
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var groupRowsSection: some View {
        ForEach(availableGroups) { group in
            let isSelected = destinationMode == .selectedGroups && selectedGroupIds.contains(group.id)
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "person.3")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.tint)
                Text(group.name)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { _ in onToggleGroup(group.id) }
                ))
                .labelsHidden()
                .tint(theme.tint)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(height: 52)

            if group.id != availableGroups.last?.id {
                Divider().overlay(MassMatesPalette.line)
            }
        }
    }

    private var diaryToggleRow: some View {
        let isDiaryOnly = destinationMode == .privateDiaryOnly
        return HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "lock")
                .font(.system(size: 16))
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("Só no meu diário")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isDiaryOnly },
                set: { isOn in onSelectMode(isOn ? .privateDiaryOnly : .selectedGroups) }
            ))
            .labelsHidden()
            .tint(theme.tint)
        }
        .padding(.horizontal, MassMatesSpacing.md)
        .frame(height: 52)
    }

    private var lockedPrivateRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.tint)
                Text("Só no meu diário")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
                    .tint(theme.tint)
                    .disabled(true)
            }
            Text("Por sigilo sacramental, confissões são mantidas privadas.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .padding(.horizontal, MassMatesSpacing.md)
        .padding(.vertical, MassMatesSpacing.sm)
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
