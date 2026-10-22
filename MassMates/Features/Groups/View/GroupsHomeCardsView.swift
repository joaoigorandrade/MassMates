import SwiftUI

struct GroupsCapacityCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let capacity: GroupSlotCapacity
    private let onUnlockSlot: () -> Void

    // MARK: - Init
    init(capacity: GroupSlotCapacity, onUnlockSlot: @escaping () -> Void) {
        self.capacity = capacity
        self.onUnlockSlot = onUnlockSlot
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            statusIcon
            detailsText
            Spacer()
            actionButton
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minRowHeight)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(cardBorder)
    }

    // MARK: - Subviews / Private Helpers
    private var statusIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(capacity.hasRewardedSlotUnlocked ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .frame(width: 40, height: 40)
            Image(systemName: capacity.hasRewardedSlotUnlocked ? "checkmark.circle.fill" : "plus.circle")
                .font(.system(size: 18))
                .foregroundStyle(capacity.hasRewardedSlotUnlocked ? theme.tint : MassMatesPalette.textSecondary)
        }
    }

    private var detailsText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(capacity.hasRewardedSlotUnlocked ? "Vaga bônus ativa" : "4ª Vaga Pessoal (30 dias)")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(1)
            Text(capacity.hasRewardedSlotUnlocked ? "Participação em até 3 fraternidades" : "Apoie o projeto e expanda seu círculo")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if !capacity.hasRewardedSlotUnlocked {
            Button("Desbloquear", action: onUnlockSlot)
                .font(MassMatesFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Capsule())
                .buttonStyle(.plain)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.card)
            .stroke(MassMatesPalette.line, lineWidth: 1)
    }
}

#Preview("Groups Capacity Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupsCapacityCardView(
            capacity: LocalCommunityGroupsService.sampleSlotCapacity(),
            onUnlockSlot: {}
        )
        .padding()
    }
}
