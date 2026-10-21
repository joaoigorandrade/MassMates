import SwiftUI

struct OnboardingValuePropositionCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let slide: OnboardingSlide
    private let isSelected: Bool
    private let action: () -> Void

    // MARK: - Init
    init(
        slide: OnboardingSlide,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.slide = slide
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                iconBadge
                textContent
                Spacer(minLength: 0)
            }
            .padding(MassMatesSpacing.sm)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var iconBadge: some View {
        Image(systemName: slide.systemImage)
            .font(MassMatesFont.headline)
            .foregroundStyle(theme.tint)
            .frame(width: 40, height: 40)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(slide.title)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(slide.bodyText)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.card)
            .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
    }
}

struct OnboardingSacredHeroFrameView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let activeSymbol: String
    private let badgeTitle: String
    private let onSwipeLeft: () -> Void
    private let onSwipeRight: () -> Void

    // MARK: - Init
    init(
        activeSymbol: String,
        badgeTitle: String = "Tempo Comum • Fidelidade Diária",
        onSwipeLeft: @escaping () -> Void,
        onSwipeRight: @escaping () -> Void
    ) {
        self.activeSymbol = activeSymbol
        self.badgeTitle = badgeTitle
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack(alignment: .bottom) {
            sacredMotifCanvas
            ambientSeasonBadge
                .padding(.bottom, MassMatesSpacing.sm)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: 340, minHeight: 248, maxHeight: 248)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.sheet))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.sheet)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    handleSwipe(translationWidth: value.translation.width)
                }
        )
    }

    // MARK: - Subviews / Private Helpers
    private var sacredMotifCanvas: some View {
        ZStack {
            Circle()
                .fill(theme.tintSoft)
                .frame(width: 148, height: 148)
            VStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "cross.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                HStack(spacing: MassMatesSpacing.md) {
                    Image(systemName: "cup.and.saucer.fill")
                    Image(systemName: activeSymbol)
                    Image(systemName: "book.pages.fill")
                }
                .font(MassMatesFont.numeral)
                .foregroundStyle(theme.tint)
                Image(systemName: "circle.grid.cross.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var ambientSeasonBadge: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Circle()
                .fill(theme.tint)
                .frame(width: 8, height: 8)
            Text(badgeTitle)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(MassMatesPalette.surface.opacity(0.94))
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        .overlay(
            Capsule().stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private func handleSwipe(translationWidth: CGFloat) {
        if translationWidth < -24 {
            onSwipeLeft()
        } else if translationWidth > 24 {
            onSwipeRight()
        }
    }
}

#Preview("Onboarding Slide Components — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let slide = LocalOnboardingService().welcomeSlides()[0]
        VStack(spacing: MassMatesSpacing.sm) {
            OnboardingSacredHeroFrameView(activeSymbol: slide.systemImage, onSwipeLeft: {}, onSwipeRight: {})
            OnboardingValuePropositionCardView(slide: slide, isSelected: true, action: {})
        }
    }
}
