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
        VStack(spacing: 0) {
            topSection
            Spacer(minLength: MassMatesSpacing.xl)
            bottomSection
        }
        .frame(maxWidth: .infinity, minHeight: 520)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }

    // MARK: - Subviews / Private Helpers
    private var activeSlide: OnboardingSlide {
        guard slides.indices.contains(currentIndex) else {
            return slides.first ?? OnboardingSlide(
                id: "default",
                badgeTitle: "",
                title: "Constância espiritual em comunidade",
                bodyText: "Uma comunidade serena para cultivar a vida de oração diária e caminhar em comunhão.",
                systemImage: "flame"
            )
        }
        return slides[currentIndex]
    }

    private var topSection: some View {
        VStack(spacing: MassMatesSpacing.xl) {
            OnboardingSacredHeroFrameView(
                activeSymbol: activeSlide.systemImage,
                onSwipeLeft: onAdvance,
                onSwipeRight: selectPreviousSlide
            )
            typographyContent
        }
        .padding(.top, MassMatesSpacing.xl)
    }

    private var typographyContent: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            Text(activeSlide.title)
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.3)
            Text(activeSlide.bodyText)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(.horizontal, MassMatesSpacing.xxs)
    }

    private var bottomSection: some View {
        VStack(spacing: MassMatesSpacing.xl) {
            OnboardingPaginationDotsView(
                count: slides.count,
                currentIndex: currentIndex,
                onSelectIndex: onSelectIndex
            )
            actionsSection
        }
        .padding(.bottom, MassMatesSpacing.md)
    }

    private var actionsSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: "Continuar",
                action: onAdvance
            )
            Button(action: onSkip) {
                Text("Pular")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                if value.translation.width < -24 {
                    onAdvance()
                } else if value.translation.width > 24 {
                    selectPreviousSlide()
                }
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
