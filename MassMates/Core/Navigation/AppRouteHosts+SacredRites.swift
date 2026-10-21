import SwiftUI

enum SacredRiteKind: Sendable, Equatable {
    case nightlyExamen
    case confessionPreparation
    case holyMassGuide
}

struct SacredRiteRouteHostView: View {
    // MARK: - Dependencies & State
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
        switch kind {
        case .nightlyExamen: NightlyExamenModalView()
        case .confessionPreparation: ConfessionPreparationModalView()
        case .holyMassGuide: HolyMassGuideModalView()
        }
    }
}
