import SwiftUI

struct OnboardingPaginationDotsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    Capsule()
                        .fill(idx == currentIndex ? theme.tint : MassMatesPalette.line)
                        .frame(width: idx == currentIndex ? 20 : 8, height: 8)
                        .frame(width: idx == currentIndex ? 32 : 24, height: MassMatesLayout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Página \(idx + 1) de \(count)")
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.75), value: currentIndex)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Passos da introdução")
    }

    // MARK: - Subviews / Private Helpers
}

struct OnboardingSacredHeroFrameView: View {
    // MARK: - Dependencies & State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing: Bool = false
    private let symbol: String

    // MARK: - Init
    init(symbol: String = "flame") {
        self.symbol = symbol
    }

    init(
        activeSymbol: String,
        badgeTitle: String = "",
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil
    ) {
        self.symbol = activeSymbol
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack {
            Circle()
                .fill(MassMatesPalette.surfaceMuted.opacity(0.6))
                .frame(width: 64, height: 64)
                .scaleEffect(isPulsing && !reduceMotion ? 1.06 : 1.0)
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .scaleEffect(isPulsing && !reduceMotion ? 1.04 : 1.0)
        }
        .frame(width: 64, height: 64)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Subviews / Private Helpers
}

struct OnboardingSlidePageView: View {
    // MARK: - Dependencies & State
    private let slide: OnboardingSlide

    // MARK: - Init
    init(slide: OnboardingSlide) {
        self.slide = slide
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            OnboardingSacredHeroFrameView(symbol: resolvedIcon)
            Spacer().frame(height: MassMatesSpacing.xl)
            textContent
            Spacer()
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Subviews / Private Helpers
    private var textContent: some View {
        VStack(spacing: MassMatesSpacing.md) {
            Text(resolvedTitle)
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.3)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(resolvedBody)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var resolvedTitle: String {
        switch slide.id {
        case "slide-consistency": "Constância Espiritual"
        case "slide-fraternities": "Fraternidade & Oração"
        case "slide-privacy": "Silêncio & Intimidade"
        default: slide.title
        }
    }

    private var resolvedBody: String {
        switch slide.id {
        case "slide-consistency": "Ritmo diário de oração conectado à liturgia viva da Igreja."
        case "slide-fraternities": "Rezar junto com sua paróquia ou pequeno grupo em comunhão."
        case "slide-privacy": "Privacidade sagrada e sigilo criptografado para confissão e diário pessoal."
        default: slide.bodyText
        }
    }

    private var resolvedIcon: String {
        switch slide.id {
        case "slide-consistency": "flame"
        case "slide-fraternities": "person.3.fill"
        case "slide-privacy": "lock.shield.fill"
        default: slide.systemImage.isEmpty ? "flame" : slide.systemImage
        }
    }
}

#Preview("Onboarding Slide Components — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let slide = OnboardingSlide(
            id: "slide-consistency",
            badgeTitle: "",
            title: "Constância Espiritual",
            bodyText: "Ritmo diário de oração conectado à liturgia viva da Igreja.",
            systemImage: "flame"
        )
        VStack(spacing: MassMatesSpacing.md) {
            OnboardingSacredHeroFrameView(symbol: slide.systemImage)
            OnboardingPaginationDotsView(count: 3, currentIndex: 0, onSelectIndex: { _ in })
            OnboardingSlidePageView(slide: slide)
        }
    }
}
