import SwiftUI

struct CheckInCelebrationCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let result: CheckInSubmissionResult
    private let activeStreakDays: Int
    private let onDone: () -> Void

    @State private var ringProgress: Double = 0.0
    @State private var showCheckBadge: Bool = false

    // MARK: - Init
    init(result: CheckInSubmissionResult, activeStreakDays: Int, onDone: @escaping () -> Void) {
        self.result = result
        self.activeStreakDays = activeStreakDays
        self.onDone = onDone
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            topBarRow
            Spacer()
            celebrationRing
            celebrationTitles
            if result.shouldShowPostCheckInSponsoredCard && !result.practice.isStrictlyPrivate {
                sponsoredCard
            }
            Spacer()
            doneButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.success, trigger: showCheckBadge)
        .task { await animateCelebration() }
    }

    // MARK: - Subviews / Private Helpers
    private var topBarRow: some View {
        HStack {
            Spacer()
            Button(action: onDone) {
                Image(systemName: "xmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
        }
    }

    private var celebrationRing: some View {
        ZStack {
            Circle().stroke(MassMatesPalette.line, lineWidth: MassMatesLayout.streakRingStroke)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(MassMatesPalette.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            ringCenterContent
            checkBadgeOverlay
        }
        .frame(width: 168, height: 168)
    }

    private var ringCenterContent: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 20)).foregroundStyle(theme.tint)
                    .symbolEffect(.bounce, value: showCheckBadge)
                Text("\(activeStreakDays)")
                    .font(.system(size: 46, weight: .medium, design: .rounded))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .contentTransition(.numericText())
            }
            Text("dias seguidos")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var checkBadgeOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Circle().fill(MassMatesPalette.success).frame(width: 28, height: 28)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white))
                    .scaleEffect(showCheckBadge ? 1.0 : (reduceMotion ? 1.0 : 0.001))
                    .opacity(showCheckBadge ? 1.0 : 0.0)
            }
            Spacer()
        }
        .offset(x: 4, y: -4)
    }

    private var celebrationTitles: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text(result.practice.isStrictlyPrivate ? "Amém. Seu registro foi guardado." : "Amém. Seu registro foi compartilhado.")
                .font(.system(size: 21, weight: .regular, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Text(result.celebrationMessage)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var sponsoredCard: some View {
        SponsoredNativeCardView(
            sponsorName: "Editora Minha Biblioteca Católica",
            headline: "Leitura espiritual para aprofundar sua oração diária",
            couponCode: "ORACAO10"
        )
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Concluir")
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.onTint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private func animateCelebration() async {
        guard !reduceMotion else {
            ringProgress = 1.0
            showCheckBadge = true
            return
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { ringProgress = 1.0 }
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { showCheckBadge = true }
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
                shouldShowPostCheckInSponsoredCard: false
            ),
            activeStreakDays: 13,
            onDone: {}
        )
    }
}
