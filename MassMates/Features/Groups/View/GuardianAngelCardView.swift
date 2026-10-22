import SwiftUI

struct GuardianAngelCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let state: GuardianAngelState
    private let onOptIn: () -> Void
    private let onSendPrayerNudge: () -> Void
    private let onRevealCycle: () -> Void

    // MARK: - Init
    init(
        state: GuardianAngelState,
        onOptIn: @escaping () -> Void,
        onSendPrayerNudge: @escaping () -> Void,
        onRevealCycle: @escaping () -> Void
    ) {
        self.state = state
        self.onOptIn = onOptIn
        self.onSendPrayerNudge = onSendPrayerNudge
        self.onRevealCycle = onRevealCycle
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            if state.isOptedIn {
                optedInContent
            } else {
                optInContent
            }
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    // MARK: - Subviews / Private Helpers
    private var optedInContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Você protege")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text(state.protectedSoulName)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Em intenção secreta nesta semana")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                if let nudge = state.anonymousNudgeStatusText {
                    Text(nudge)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                        .padding(.top, 2)
                }
            }
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
            HStack {
                Spacer()
                Button(action: onSendPrayerNudge) {
                    Text(state.hasPrayedForProtectedSoulToday ? "Oração entregue ✓" : "Rezei por esta alma")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(state.hasPrayedForProtectedSoulToday ? MassMatesPalette.textSecondary : theme.tint)
                        .frame(minHeight: MassMatesLayout.minTapTarget)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var optInContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Anjo da Guarda Secreto")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("Corrente de Oração Secreta")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Receba secretamente um irmão do grupo para sustentar em oração diária.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
            HStack {
                Spacer()
                Button(action: onOptIn) {
                    Text("Participar do Sorteio")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(theme.tint)
                        .frame(minHeight: MassMatesLayout.minTapTarget)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Guardian Angel Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GuardianAngelCardView(
            state: CommunitySampleData.initialGuardianAngelState(for: CommunitySampleData.parishFraternity),
            onOptIn: {},
            onSendPrayerNudge: {},
            onRevealCycle: {}
        )
        .padding()
    }
}
