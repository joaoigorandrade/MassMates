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
        VStack(spacing: 0) {
            topAppBar(data: data)
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                    TodayHeaderView(
                        seasonTitle: data.activeSeasonTitle,
                        saintOrFeast: data.liturgicalDay.saintOrFeast,
                        feastRankLabel: data.liturgicalDay.feastRankLabel,
                        weekdayAndWeekLabel: data.liturgicalDay.weekdayAndWeekLabel,
                        saintQuote: data.liturgicalDay.saintQuote,
                        progress: data.progress,
                        onSelectSeason: { season in viewModel.selectSeasonColor(season) },
                        onOpenOnboarding: { navigator?.present(.onboarding(season: data.activeSeasonColor)) },
                        onOpenHistory: { navigator?.present(.spiritualDiary(season: data.activeSeasonColor)) }
                    )
                    mainSectionsStack(data)
                }
                .padding(.top, MassMatesSpacing.md)
                .padding(.bottom, MassMatesSpacing.xxl)
            }
        }
    }

    private func mainSectionsStack(_ data: TodayDashboardData) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            RuleOfLifeSectionView(
                progress: data.progress,
                onSelectPreset: { preset in viewModel.selectPreset(preset) },
                onTogglePractice: { practice in viewModel.togglePractice(practice) }
            )
            DevotionalQuickCardsView(
                reading: data.liturgicalDay.reading,
                onOpenGospel: { navigator?.present(.dailyGospel(reading: data.liturgicalDay.reading, season: data.activeSeasonColor)) },
                onOpenTimer: { mode in navigator?.present(.prayerTimer(mode: mode, season: data.activeSeasonColor)) }
            )
            editorialReflectionCard
            SponsoredNativeCardView(
                sponsorName: "Edições CNBB",
                headline: "Edições CNBB — Bíblia Sagrada Edição Pastoral"
            )
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
    }

    private func topAppBar(data: TodayDashboardData) -> some View {
        HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
            seasonAndDateColumn(data: data)
            Spacer()
            streakAndProfileRow(data: data)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.vertical, MassMatesSpacing.sm)
        .background(MassMatesPalette.bg)
        .overlay(alignment: .bottom) { Rectangle().fill(MassMatesPalette.line).frame(height: 1) }
    }

    private func seasonAndDateColumn(data: TodayDashboardData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            seasonSelectorMenu(activeTitle: data.activeSeasonTitle)
            Text(data.liturgicalDay.weekdayAndWeekLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(1)
        }
    }

    private func streakAndProfileRow(data: TodayDashboardData) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 15)).foregroundStyle(viewModel.currentTheme.tint)
                Text("\(data.progress.activeStreakDays)").font(.system(size: 14, weight: .semibold)).foregroundStyle(MassMatesPalette.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(data.progress.activeStreakDays) dias em oração")
            Button {
                navigator?.present(.onboarding(season: data.activeSeasonColor))
            } label: {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 26)).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Perfil e configurações")
        }
    }

    private func seasonSelectorMenu(activeTitle: String) -> some View {
        Menu {
            ForEach(LiturgicalColor.allCases) { season in
                Button(season.defaultSeasonName) { viewModel.selectSeasonColor(season) }
            }
        } label: {
            HStack(spacing: 5) {
                Circle().fill(viewModel.currentTheme.tint).frame(width: 6, height: 6)
                Text(activeTitle.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(0.6).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private var editorialReflectionCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("REFLEXÃO DO DIA").font(.system(size: 11, weight: .semibold)).tracking(0.8).foregroundStyle(MassMatesPalette.textSecondary)
            Text("“Não percas de vista teu ponto de partida; conserva o que tens, faze o que fazes.”")
                .font(MassMatesFont.scripture).foregroundStyle(MassMatesPalette.textPrimary).fixedSize(horizontal: false, vertical: true)
            Text("— Carta de Santa Clara a Santa Inês").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.top, MassMatesSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(MassMatesPalette.line).frame(height: 1) }
    }
}

#Preview("Today Dashboard — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        let vm = TodayDashboardViewModel()
        let _ = vm.selectSeasonColor(season)
        TodayDashboardView(viewModel: vm)
    }
}
