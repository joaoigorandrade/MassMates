import SwiftUI

struct OnboardingPaginationDotsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let count: Int
    private let currentIndex: Int
    private let onSelectIndex: (Int) -> Void

    // MARK: - Init
    init(count: Int, currentIndex: Int, onSelectIndex: @escaping (Int) -> Void) {
        self.count = count
        self.currentIndex = currentIndex
        self.onSelectIndex = onSelectIndex
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(0..<count, id: \.self) { idx in
                Button {
                    onSelectIndex(idx)
                } label: {
                    Circle()
                        .fill(idx == currentIndex ? theme.tint : MassMatesPalette.line)
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Página \(idx + 1) de \(count)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Passos da introdução")
    }

    // MARK: - Subviews / Private Helpers
}

struct OnboardingSacredHeroFrameView: View {
    // MARK: - Dependencies & State
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
        ZStack {
            Image(systemName: resolvedSymbol)
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(width: 64, height: 64)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .accessibilityLabel(badgeTitle)
    }

    // MARK: - Subviews / Private Helpers
    private var resolvedSymbol: String {
        if activeSymbol == "calendar" { return "flame" }
        return activeSymbol.isEmpty ? "flame" : activeSymbol
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                if value.translation.width < -24 {
                    onSwipeLeft()
                } else if value.translation.width > 24 {
                    onSwipeRight()
                }
            }
    }
}

struct OnboardingValuePropositionCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let slide: OnboardingSlide
    private let isSelected: Bool
    private let action: () -> Void

    // MARK: - Init
    init(slide: OnboardingSlide, isSelected: Bool, action: @escaping () -> Void) {
        self.slide = slide
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: slide.systemImage)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                    Text(slide.title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(slide.bodyText)
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(MassMatesSpacing.sm)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.card)
                    .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Onboarding Slide Components — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let slide = LocalOnboardingService().welcomeSlides()[0]
        VStack(spacing: MassMatesSpacing.md) {
            OnboardingSacredHeroFrameView(activeSymbol: slide.systemImage, onSwipeLeft: {}, onSwipeRight: {})
            OnboardingPaginationDotsView(count: 3, currentIndex: 0, onSelectIndex: { _ in })
            OnboardingValuePropositionCardView(slide: slide, isSelected: true, action: {})
        }
    }
}
