import SwiftUI

struct OnboardingSlidesStepView: View, Equatable {
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

    nonisolated static func == (lhs: OnboardingSlidesStepView, rhs: OnboardingSlidesStepView) -> Bool {
        lhs.currentIndex == rhs.currentIndex &&
        lhs.isOnFinalSlide == rhs.isOnFinalSlide &&
        lhs.slides == rhs.slides
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            pagedSlidesView
            bottomSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private var pagedSlidesView: some View {
        TabView(selection: selectionBinding) {
            ForEach(resolvedSlides) { slide in
                OnboardingSlidePageView(slide: slide)
                    .tag(slide.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(minHeight: 380, maxHeight: 460)
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }

    private var bottomSection: some View {
        VStack(spacing: MassMatesSpacing.xl) {
            OnboardingPaginationDotsView(
                count: resolvedSlides.count,
                currentIndex: currentIndex,
                onSelectIndex: onSelectIndex
            )
            actionsSection
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.bottom, MassMatesSpacing.md)
    }

    private var actionsSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: isOnFinalSlide ? "Começar" : "Continuar",
                action: onAdvance
            )
            skipButton
        }
    }

    private var skipButton: some View {
        Button(action: onSkip) {
            Text("Pular")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .opacity(isOnFinalSlide ? 0 : 1)
        .disabled(isOnFinalSlide)
    }

    private var selectionBinding: Binding<String> {
        Binding(
            get: {
                guard resolvedSlides.indices.contains(currentIndex) else { return resolvedSlides.first?.id ?? "" }
                return resolvedSlides[currentIndex].id
            },
            set: { newId in
                if let newIndex = resolvedSlides.firstIndex(where: { $0.id == newId }), newIndex != currentIndex {
                    onSelectIndex(newIndex)
                }
            }
        )
    }

    private var resolvedSlides: [OnboardingSlide] {
        slides.isEmpty ? Self.defaultSlides : slides
    }

    private static let defaultSlides: [OnboardingSlide] = [
        OnboardingSlide(
            id: "slide-consistency",
            badgeTitle: "Tempo Comum • Fidelidade Diária",
            title: "Constância Espiritual",
            bodyText: "Ritmo diário de oração conectado à liturgia viva da Igreja.",
            systemImage: "flame"
        ),
        OnboardingSlide(
            id: "slide-fraternities",
            badgeTitle: "Comunhão • Intercessão Mútua",
            title: "Fraternidade & Oração",
            bodyText: "Rezar junto com sua paróquia ou pequeno grupo em comunhão.",
            systemImage: "person.3.fill"
        ),
        OnboardingSlide(
            id: "slide-privacy",
            badgeTitle: "Criptografia Local • Paz Interior",
            title: "Silêncio & Intimidade",
            bodyText: "Privacidade sagrada e sigilo criptografado para confissão e diário pessoal.",
            systemImage: "lock.shield.fill"
        )
    ]
}

#Preview("Onboarding Slides — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingSlidesStepView(
            slides: [],
            currentIndex: 0,
            isOnFinalSlide: false,
            onSelectIndex: { _ in },
            onAdvance: {},
            onSkip: {}
        )
    }
}
