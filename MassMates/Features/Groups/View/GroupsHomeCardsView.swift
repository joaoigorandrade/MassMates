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
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                headerRow
                segmentedSlotsBar
                statusLabelsRow
                rewardedSlotBox
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "archivebox.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                Text("Capacidade de Comunhão")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Text(capacity.hasRewardedSlotUnlocked ? "3 DE 4 VAGAS" : "2 DE 3 VAGAS")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(theme.tintSoft)
                .clipShape(Capsule())
        }
    }

    private var segmentedSlotsBar: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Capsule().fill(theme.tint).frame(height: MassMatesLayout.progressBarHeight)
            Capsule().fill(theme.tint).frame(height: MassMatesLayout.progressBarHeight)
            Capsule()
                .fill(capacity.hasRewardedSlotUnlocked ? theme.tint : MassMatesPalette.surfaceMuted)
                .frame(height: MassMatesLayout.progressBarHeight)
        }
    }

    private var statusLabelsRow: some View {
        HStack {
            Text("2 Grupos Pessoais ativos")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Text("1 Desafio Aberto")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var rewardedSlotBox: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "rosette")
                .font(MassMatesFont.callout)
                .foregroundStyle(Theme(season: .white).tint)
                .frame(width: 32, height: 32)
                .background(Theme(season: .white).tintSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("4º Grupo por 30 dias")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Apoie o projeto e expanda seu círculo")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button("Desbloquear", action: onUnlockSlot)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(MassMatesPalette.surface)
                .clipShape(Capsule())
                .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }
}

#Preview("Groups Capacity Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupsCapacityCardView(
            capacity: LocalCommunityGroupsService().slotCapacity(),
            onUnlockSlot: {}
        )
        .padding()
    }
}
