import SwiftUI

enum SacredRiteKind: Sendable, Equatable {
    case nightlyExamen
    case confessionPreparation
    case holyMassGuide
}

struct SacredRiteRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.sharedCheckInEngine) private var checkInEngine
    private let kind: SacredRiteKind
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(kind: SacredRiteKind, season: LiturgicalColor) {
        self.kind = kind
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        content
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var content: some View {
        let engine = checkInEngine ?? LocalCheckInEngineService()
        switch kind {
        case .nightlyExamen:
            NightlyExamenModalView(
                viewModel: NightlyExamenViewModel(checkInEngine: engine)
            )
        case .confessionPreparation:
            ConfessionPreparationModalView(
                viewModel: ConfessionPrepViewModel(checkInEngine: engine)
            )
        case .holyMassGuide:
            HolyMassGuideModalView(
                viewModel: HolyMassGuideViewModel(checkInEngine: engine)
            )
        }
    }
}

struct SacredRitesTabRootHostView: View {
    // MARK: - Dependencies & State

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        SacredRitesHomeView()
    }

    // MARK: - Subviews / Private Helpers
}
