import Navigation
import SwiftUI

struct TodayDashboardView: View {
    // MARK: - Dependencies & State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: TodayDashboardViewModel
    private let onOpenRuleOfLife: (() -> Void)?

    // MARK: - Init
    init(
        viewModel: TodayDashboardViewModel = TodayDashboardViewModel(),
        onOpenRuleOfLife: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenRuleOfLife = onOpenRuleOfLife
    }

    // MARK: - Body / Public API
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading: loadingContent
            case .loaded(let data): loadedContent(data)
            case .error: errorContent
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .environment(\.liturgicalTheme, viewModel.currentTheme)
        .environment(\.onCompleteSpiritualPractice) { practice in
            viewModel.markPracticeCompleted(practice)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: viewModel.currentTheme.season)
        .task {
            if case .idle = viewModel.viewState { viewModel.loadDashboard() }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var loadingContent: some View {
        ProgressView().tint(viewModel.currentTheme.tint).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorContent: some View {
        VStack(spacing: MassMatesSpacing.md) {
            Text("Recomece hoje, com leveza.").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            MassMatesSecondaryButton(title: "Atualizar") { viewModel.loadDashboard() }
        }
        .padding(MassMatesLayout.screenMargin)
    }

    private func loadedContent(_ data: TodayDashboardData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MassMatesSpacing.md) {
                TodayHeaderView(
                    seasonTitle: data.activeSeasonTitle,
                    saintOrFeast: data.liturgicalDay.saintOrFeast,
                    streakDays: data.progress.activeStreakDays,
                    onSelectSeason: { season in viewModel.selectSeasonColor(season) },
                    onOpenStreak: { triggerRuleOfLife(season: data.activeSeasonColor) }
                )
                .equatable()
                .padding(.top, MassMatesSpacing.xs)

                centralRuleOfLifeSection(data: data)
                    .padding(.vertical, MassMatesSpacing.xs)

                DevotionalQuickCardsView(
                    reading: data.liturgicalDay.reading,
                    onOpenGospel: { navigator?.present(.dailyGospel(reading: data.liturgicalDay.reading, season: data.activeSeasonColor)) },
                    onOpenTimer: { mode in navigator?.present(.prayerTimer(mode: mode, season: data.activeSeasonColor)) }
                )
                .equatable()

                quietSponsoredBanner
            }
            .padding(.bottom, MassMatesSpacing.xl)
        }
    }

    private func centralRuleOfLifeSection(data: TodayDashboardData) -> some View {
        VStack(spacing: MassMatesSpacing.md) {
            Button {
                triggerRuleOfLife(season: data.activeSeasonColor)
            } label: {
                ruleOfLifeRing(data: data)
            }
            .buttonStyle(MassMatesPressableButtonStyle())
            .accessibilityLabel("Regra de Vida: \(data.progress.completedCount) de \(data.progress.totalCount) concluídas")

            Button {
                triggerRuleOfLife(season: data.activeSeasonColor)
            } label: {
                HStack(spacing: 4) {
                    Text("Ver regra").font(MassMatesFont.callout).fontWeight(.medium)
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(viewModel.currentTheme.tint)
                .padding(.vertical, 4)
                .padding(.horizontal, MassMatesSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(MassMatesPressableButtonStyle())
        }
    }

    private func ruleOfLifeRing(data: TodayDashboardData) -> some View {
        ZStack {
            Circle().stroke(MassMatesPalette.line, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: max(0.01, data.progress.ruleCompletionRatio))
                .stroke(viewModel.currentTheme.tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85), value: data.progress.ruleCompletionRatio)
            VStack(spacing: 2) {
                Text("\(data.progress.completedCount)/\(data.progress.totalCount)")
                    .font(MassMatesFont.numeral)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .contentTransition(.numericText())
                Text("Regra de Vida").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(width: 172, height: 172)
    }

    private func triggerRuleOfLife(season: LiturgicalColor) {
        if let onOpenRuleOfLife {
            onOpenRuleOfLife()
        } else {
            navigator?.present(.ruleOfLife(season: season))
        }
    }

    private var quietSponsoredBanner: some View {
        Button {
            guard let url = URL(string: "https://www.edicoescnbb.com.br") else { return }
            openURL(url)
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Text("PATROCINADO").font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(MassMatesPalette.textTertiary)
                Text("·").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.line)
                Text("Edições CNBB · Bíblia Sagrada Edição Pastoral")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary).lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(MassMatesPalette.textTertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .contentShape(Rectangle())
        }
        .buttonStyle(MassMatesPressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patrocinado: Edições CNBB, Bíblia Sagrada Edição Pastoral. Abrir site")
    }
}

#Preview("Today Dashboard — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        let vm = TodayDashboardViewModel()
        let _ = vm.selectSeasonColor(season)
        TodayDashboardView(viewModel: vm)
    }
}
