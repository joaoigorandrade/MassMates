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
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            headerRow
            if state.isOptedIn {
                assignedSoulSection
                actionButtonSection
            } else {
                optInSection
            }
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "shield.lefthalf.filled")
                .font(MassMatesFont.title)
                .foregroundStyle(theme.tint)
                .frame(width: 40, height: 40)
                .background(MassMatesPalette.surface)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Text("ANJO DA GUARDA SECRETO")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Circle().fill(theme.tint).frame(width: 4, height: 4)
                    Text("Ciclo de 7 dias")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Text("Seu Protegido da Semana")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer(minLength: 0)
            Text("Dia 4/7")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(MassMatesPalette.surface)
                .clipShape(Capsule())
        }
    }

    private var assignedSoulSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Text("Você está intercedendo em segredo por")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text(state.protectedSoulName)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            personalIntentionBox
            if state.isCycleRevealed, let revealed = state.anonymousNudgeStatusText {
                Text(revealed)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
        }
    }

    private var personalIntentionBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "bookmark.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(Theme(season: .white).tint)
                Text("INTENÇÃO PESSOAL")
                    .font(MassMatesFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(Theme(season: .white).tint)
            }
            Text("“\(state.protectedSoulIntention)”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface.opacity(0.85))
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var actionButtonSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Button(action: onSendPrayerNudge) {
                Label(
                    state.hasPrayedForProtectedSoulToday
                        ? "Oração enviada com carinho ✓"
                        : "Rezei por meu protegido hoje",
                    systemImage: "hands.sparkles.fill"
                )
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.onTint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                .background(state.hasPrayedForProtectedSoulToday ? MassMatesPalette.success : theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
            Text("As identidades serão reveladas no domingo fraterno ao fim do ciclo.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var optInSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Receba secretamente um irmão do grupo para sustentar em oração diária durante este ciclo.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            MassMatesPrimaryButton(
                title: "Participar do Sorteio de Oração",
                systemImage: "hands.sparkles.fill",
                action: onOptIn
            )
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
    }
}
