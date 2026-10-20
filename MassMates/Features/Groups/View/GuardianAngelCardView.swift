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
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                headerRow
                if let receivedMessage = state.anonymousNudgeStatusText {
                    receivedPrayerBanner(receivedMessage)
                }
                if state.isOptedIn {
                    assignedSoulSection
                } else {
                    optInSection
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack {
            Label("Anjo da Guarda Secreto", systemImage: "sparkles")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Text("\(state.cycleTitle) • \(theme.season.defaultSeasonName)")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
        }
    }

    private func receivedPrayerBanner(_ message: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "hands.sparkles")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
            Text(message)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var optInSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Receba secretamente um irmão do grupo para sustentar em oração diária durante este ciclo.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            MassMatesPrimaryButton(
                title: "Participar do Sorteio de Oração",
                systemImage: "hands.sparkles",
                action: onOptIn
            )
        }
    }

    private var assignedSoulSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack(spacing: MassMatesSpacing.sm) {
                Text(state.protectedSoulInitials)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .frame(width: 36, height: 36)
                    .background(theme.tintSoft)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alma confiada à sua oração: \(state.protectedSoulName)")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Orações enviadas no ciclo: \(state.prayersSentInCycle)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            Text("“\(state.protectedSoulIntention)”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
            actionButtons
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: state.hasPrayedForProtectedSoulToday
                    ? "Oração enviada hoje ao seu protegido"
                    : "Rezei pela minha alma protegida hoje",
                systemImage: state.hasPrayedForProtectedSoulToday ? "checkmark.circle" : "paperplane",
                action: onSendPrayerNudge
            )
            if !state.isCycleRevealed {
                MassMatesTextButton(
                    title: "Encerrar ciclo e revelar identidades",
                    action: onRevealCycle
                )
            }
        }
    }
}

#Preview("Guardian Angel Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GuardianAngelCardView(
            state: CommunitySampleData.initialGuardianAngelState(
                for: CommunitySampleData.parishFraternity
            ),
            onOptIn: {},
            onSendPrayerNudge: {},
            onRevealCycle: {}
        )
    }
}
