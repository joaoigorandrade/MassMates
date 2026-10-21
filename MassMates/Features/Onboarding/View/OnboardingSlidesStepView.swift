import SwiftUI

struct OnboardingSlidesStepView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let slides: [OnboardingSlide]
    private let currentIndex: Int
    private let isOnFinalSlide: Bool
    private let onSelectIndex: (Int) -> Void
    private let onAdvance: () -> Void
    private let onSkip: () -> Void

    // MARK: - Init
    init(
        slides: [OnboardingSlide],
        currentIndex: Int,
        isOnFinalSlide: Bool,
        onSelectIndex: @escaping (Int) -> Void,
        onAdvance: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.slides = slides
        self.currentIndex = currentIndex
        self.isOnFinalSlide = isOnFinalSlide
        self.onSelectIndex = onSelectIndex
        self.onAdvance = onAdvance
        self.onSkip = onSkip
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            brandHeader
            OnboardingSacredHeroFrameView(
                activeSymbol: activeSlide.systemImage,
                onSwipeLeft: onAdvance,
                onSwipeRight: selectPreviousSlide
            )
            narrativeHeader
            valuePropositionStack
            slideIndicators
            bottomActionsSection
            footnoteAssurance
        }
    }

    // MARK: - Subviews / Private Helpers
    private var activeSlide: OnboardingSlide {
        guard slides.indices.contains(currentIndex) else {
            return slides[0]
        }
        return slides[currentIndex]
    }

    private var brandHeader: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "leaf.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                Text("MassMates")
                    .font(MassMatesFont.caption)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button(action: onSkip) {
                Text("Pular")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, MassMatesSpacing.xxs)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
    }

    private var narrativeHeader: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("Constância espiritual em fraternidade")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Text("Uma comunidade serena para cultivar a vida de oração diária, partilhar graças e caminhar em comunhão.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 320)
    }

    private var valuePropositionStack: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            ForEach(Array(slides.enumerated()), id: \.element.id) { idx, slide in
                OnboardingValuePropositionCardView(
                    slide: slide,
                    isSelected: idx == currentIndex,
                    action: { onSelectIndex(idx) }
                )
            }
        }
    }

    private var slideIndicators: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(Array(slides.enumerated()), id: \.element.id) { idx, _ in
                Button {
                    onSelectIndex(idx)
                } label: {
                    Capsule()
                        .fill(idx == currentIndex ? theme.tint : MassMatesPalette.line)
                        .frame(width: idx == currentIndex ? 28 : 8, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Slide \(idx + 1) de \(slides.count)")
            }
        }
    }

    private var bottomActionsSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: "Começar Minha Caminhada",
                systemImage: "arrow.right",
                action: onAdvance
            )
            Button(action: onSkip) {
                Text("Já possuo uma conta • Entrar")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
    }

    private var footnoteAssurance: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "checkmark.seal.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("Textos litúrgicos oficiais e espaço sem distrações.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private func selectPreviousSlide() {
        guard currentIndex > 0 else { return }
        onSelectIndex(currentIndex - 1)
    }
}

#Preview("Onboarding Slides — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let service = LocalOnboardingService()
        OnboardingSlidesStepView(
            slides: service.welcomeSlides(),
            currentIndex: 0,
            isOnFinalSlide: false,
            onSelectIndex: { _ in },
            onAdvance: {},
            onSkip: {}
        )
    }
}
