import SwiftUI

struct CheckInCelebrationCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let result: CheckInSubmissionResult
    private let activeStreakDays: Int
    private let onDone: () -> Void

    // MARK: - Init
    init(
        result: CheckInSubmissionResult,
        activeStreakDays: Int,
        onDone: @escaping () -> Void
    ) {
        self.result = result
        self.activeStreakDays = activeStreakDays
        self.onDone = onDone
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            celebrationCard
            if result.shouldShowPostCheckInSponsoredCard && !result.practice.isStrictlyPrivate {
                SponsoredNativeCardView(
                    sponsorName: "Editora Minha Biblioteca Católica",
                    headline: "Leitura espiritual para aprofundar sua oração diária",
                    bodyText: "Clássicos dos santos selecionados para sustentar sua caminhada espiritual.",
                    couponCode: "ORACAO10"
                )
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var celebrationCard: some View {
        VStack(spacing: MassMatesSpacing.md) {
            StreakRingView(streakDays: activeStreakDays, progress: 1.0)
            celebrationTitles
            doneButton
        }
        .padding(MassMatesSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var celebrationTitles: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text(result.practice.title)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)

            Text(result.celebrationMessage)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Concluir em paz")
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.onTint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Check-In Celebration — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CheckInCelebrationCardView(
            result: CheckInSubmissionResult(
                practice: .rosary,
                sharedGroupIds: ["frat-sao-jose"],
                savedToPrivateDiary: true,
                celebrationMessage: "Mais um dia em oração • Partilhado em 1 grupo.",
                shouldShowPostCheckInSponsoredCard: true
            ),
            activeStreakDays: 15,
            onDone: {}
        )
    }
}
