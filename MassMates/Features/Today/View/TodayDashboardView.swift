import Navigation
import SwiftUI

struct TodayDashboardView: View {
    // MARK: - Dependencies & State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: TodayDashboardViewModel

    // MARK: - Init
    init(viewModel: TodayDashboardViewModel = TodayDashboardViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                loadingContent
            case .loaded(let data):
                loadedContent(data)
            case .error:
                errorContent
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .environment(\.liturgicalTheme, viewModel.currentTheme)
        .environment(\.onCompleteSpiritualPractice) { practice in
            viewModel.markPracticeCompleted(practice)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.4),
            value: viewModel.currentTheme.season
        )
        .task {
            if case .idle = viewModel.viewState {
                viewModel.loadDashboard()
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var loadingContent: some View {
        VStack {
            ProgressView()
                .tint(viewModel.currentTheme.tint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorContent: some View {
        VStack(spacing: MassMatesSpacing.md) {
            Text("Recomece hoje, com leveza.")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            MassMatesSecondaryButton(title: "Atualizar") {
                viewModel.loadDashboard()
            }
        }
        .padding(MassMatesLayout.screenMargin)
    }

    private func loadedContent(_ data: TodayDashboardData) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                    TodayHeaderView(
                        seasonTitle: data.activeSeasonTitle,
                        saintOrFeast: data.liturgicalDay.saintOrFeast,
                        progress: data.progress,
                        onSelectSeason: { season in
                            viewModel.selectSeasonColor(season)
                        },
                        onOpenOnboarding: {
                            navigator?.present(.onboarding(season: data.activeSeasonColor))
                        }
                    )
                    VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                        DevotionalQuickCardsView(
                            reading: data.liturgicalDay.reading,
                            onOpenGospel: {
                                navigator?.present(
                                    .dailyGospel(
                                        reading: data.liturgicalDay.reading,
                                        season: data.activeSeasonColor
                                    )
                                )
                            },
                            onOpenTimer: { mode in
                                navigator?.present(
                                    .prayerTimer(
                                        mode: mode,
                                        season: data.activeSeasonColor
                                    )
                                )
                            }
                        )
                        RuleOfLifeSectionView(
                            progress: data.progress,
                            onSelectPreset: { preset in
                                viewModel.selectPreset(preset)
                            },
                            onTogglePractice: { practice in
                                viewModel.togglePractice(practice)
                            }
                        )
                    }
                    .padding(.horizontal, MassMatesLayout.screenMargin)
                    .padding(.bottom, MassMatesSpacing.xl)
                }
            }
            SponsoredBannerView()
        }
    }
}

#Preview("Today Dashboard — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        let vm = TodayDashboardViewModel()
        let _ = vm.selectSeasonColor(season)
        TodayDashboardView(viewModel: vm)
    }
}
