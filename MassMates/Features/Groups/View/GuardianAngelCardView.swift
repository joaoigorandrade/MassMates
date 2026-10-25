import SwiftUI
import UIKit

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
        VStack(spacing: MassMatesSpacing.lg) {
            if state.isOptedIn {
                optedInContent
            } else {
                optInContent
            }
        }
        .padding(MassMatesSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    // MARK: - Subviews / Private Helpers
    private var optedInContent: some View {
        VStack(spacing: MassMatesSpacing.md) {
            headerRow(title: "Seu Protegido Espiritual")
            soulNameView(name: state.protectedSoulName)
            intentionsSection(intention: state.protectedSoulIntention)
            disclosureFootnote
            actionButton(
                title: state.hasPrayedForProtectedSoulToday ? "Oração entregue ✓" : "Rezei pelo meu protegido",
                isCompleted: state.hasPrayedForProtectedSoulToday,
                action: handleSendPrayerNudge
            )
            reassuranceText
            if let nudge = state.anonymousNudgeStatusText {
                nudgeStatusView(nudge)
            }
        }
    }

    private var optInContent: some View {
        VStack(spacing: MassMatesSpacing.md) {
            headerRow(title: "Anjo da Guarda Secreto")
            soulNameView(name: "Corrente de Oração")
            Text("Receba secretamente um irmão do grupo para sustentar em oração diária.")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            disclosureFootnote
            actionButton(title: "Participar do Sorteio", isCompleted: false, action: handleOptIn)
        }
    }

    private func headerRow(title: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "wing")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.tint)
            Text(title)
                .font(MassMatesFont.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func soulNameView(name: String) -> some View {
        Text(name)
            .font(.system(size: 24, weight: .semibold, design: .serif))
            .foregroundStyle(MassMatesPalette.textPrimary)
            .multilineTextAlignment(.center)
    }

    private func intentionsSection(intention: String) -> some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("INTENÇÕES")
                .font(MassMatesFont.caption)
                .fontWeight(.medium)
                .tracking(0.8)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("“\(intention)”")
                .font(MassMatesFont.scriptureEmphasis)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
        }
    }

    private var disclosureFootnote: some View {
        Button(action: onRevealCycle) {
            Text(state.isCycleRevealed ? "Ciclo revelado: \(state.revealedGuardianAngelName)" : "Identidades reveladas ao término do ciclo no domingo")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func actionButton(title: String, isCompleted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MassMatesFont.headline)
                .foregroundStyle(isCompleted ? MassMatesPalette.textSecondary : theme.onTint)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                .background(isCompleted ? MassMatesPalette.surfaceMuted : theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                .contentShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
    }

    private var reassuranceText: some View {
        Text(state.hasPrayedForProtectedSoulToday ? "Aviso anônimo entregue com serenidade." : "Ela receberá um aviso anônimo.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .multilineTextAlignment(.center)
    }

    private func nudgeStatusView(_ text: String) -> some View {
        Text(text)
            .font(MassMatesFont.caption)
            .foregroundStyle(theme.tint)
            .multilineTextAlignment(.center)
            .padding(.top, MassMatesSpacing.xxs)
    }

    private func handleSendPrayerNudge() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onSendPrayerNudge()
    }

    private func handleOptIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onOptIn()
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
