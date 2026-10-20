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
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            brandHeader
            slideCard
            slideIndicators
            actionButtons
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
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("MassMates • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Vida de Oração em Fraternidade")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            if !isOnFinalSlide {
                MassMatesTextButton(title: "Pular", action: onSkip)
            }
        }
    }

    private var slideCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                HStack(spacing: MassMatesSpacing.xs) {
                    Image(systemName: activeSlide.systemImage)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(theme.tint)
                    Text(activeSlide.badgeTitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))

                Text(activeSlide.title)
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(activeSlide.bodyText)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
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
                        .frame(width: idx == currentIndex ? 28 : 10, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Slide \(idx + 1)")
            }
        }
    }

    private var actionButtons: some View {
        MassMatesPrimaryButton(
            title: isOnFinalSlide ? "Começar minha caminhada" : "Próximo",
            systemImage: isOnFinalSlide ? "arrow.right.circle.fill" : "chevron.right",
            action: onAdvance
        )
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
