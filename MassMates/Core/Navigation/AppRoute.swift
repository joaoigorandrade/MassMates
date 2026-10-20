import Navigation
import SwiftUI

enum AppRoute: ModalRoute {
    case dailyGospel(reading: DailyLiturgicalReading, season: LiturgicalColor)
    case prayerTimer(mode: PrayerTimerMode, season: LiturgicalColor)

    var presentationStyle: ModalPresentation {
        .sheet
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .dailyGospel(let reading, let season):
            DailyGospelRouteHostView(reading: reading, season: season)
        case .prayerTimer(let mode, let season):
            PrayerTimerRouteHostView(mode: mode, season: season)
        }
    }
}

extension EnvironmentValues {
    @Entry var onCompleteSpiritualPractice: @MainActor (SpiritualPractice) -> Void = { _ in }
}

private struct DailyGospelRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    private let reading: DailyLiturgicalReading
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(reading: DailyLiturgicalReading, season: LiturgicalColor) {
        self.reading = reading
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        DailyGospelModalView(
            viewModel: DailyGospelViewModel(reading: reading) {
                onCompletePractice(.dailyGospel)
            }
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
}

private struct PrayerTimerRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    private let mode: PrayerTimerMode
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(mode: PrayerTimerMode, season: LiturgicalColor) {
        self.mode = mode
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        PrayerTimerModalView(
            viewModel: PrayerTimerViewModel(
                initialMode: mode,
                onCompletePractice: { practice in
                    onCompletePractice(practice)
                }
            )
        )
        .environment(\.liturgicalTheme, Theme(season: season))
        .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
}
