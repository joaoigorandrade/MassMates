import SwiftUI

enum SacredRiteKind: Sendable, Equatable {
    case nightlyExamen
    case confessionPreparation
    case holyMassGuide
}

@MainActor private final class HostBox<T> {
    var value: T?
}

struct SacredRiteRouteHostView: View {
    @Environment(\.sharedCheckInEngine) private var checkInEngine
    @State private var nightlyExamenBox = HostBox<NightlyExamenViewModel>()
    @State private var confessionPrepBox = HostBox<ConfessionPrepViewModel>()
    @State private var holyMassGuideBox = HostBox<HolyMassGuideViewModel>()
    private let kind: SacredRiteKind
    private let season: LiturgicalColor

    init(kind: SacredRiteKind, season: LiturgicalColor) {
        self.kind = kind
        self.season = season
    }

    var body: some View {
        content
            .environment(\.liturgicalTheme, Theme(season: season))
            .presentationCornerRadius(MassMatesRadius.sheet)
    }

    @ViewBuilder
    private var content: some View {
        let engine = checkInEngine ?? LocalCheckInEngineService()
        switch kind {
        case .nightlyExamen:
            NightlyExamenModalView(viewModel: resolveNightlyExamen(engine: engine))
        case .confessionPreparation:
            ConfessionPreparationModalView(viewModel: resolveConfessionPrep(engine: engine))
        case .holyMassGuide:
            HolyMassGuideModalView(viewModel: resolveHolyMassGuide(engine: engine))
        }
    }

    private func resolveNightlyExamen(engine: any CheckInSubmitting) -> NightlyExamenViewModel {
        if let vm = nightlyExamenBox.value { return vm }
        let vm = NightlyExamenViewModel(checkInEngine: engine)
        nightlyExamenBox.value = vm
        return vm
    }

    private func resolveConfessionPrep(engine: any CheckInSubmitting) -> ConfessionPrepViewModel {
        if let vm = confessionPrepBox.value { return vm }
        let vm = ConfessionPrepViewModel(checkInEngine: engine)
        confessionPrepBox.value = vm
        return vm
    }

    private func resolveHolyMassGuide(engine: any CheckInSubmitting) -> HolyMassGuideViewModel {
        if let vm = holyMassGuideBox.value { return vm }
        let vm = HolyMassGuideViewModel(checkInEngine: engine)
        holyMassGuideBox.value = vm
        return vm
    }
}

struct SacredRitesTabRootHostView: View {
    init() {}

    var body: some View {
        SacredRitesHomeView()
    }
}
