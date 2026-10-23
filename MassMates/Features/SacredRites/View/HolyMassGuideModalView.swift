import Navigation
import SwiftUI

struct HolyMassGuideModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: HolyMassGuideViewModel

    // MARK: - Init
    init(viewModel: HolyMassGuideViewModel = HolyMassGuideViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            viewportContent
            dockedBottomNavigation
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack {
                closeButton
                Spacer()
                liturgicalSectionCaption
                Spacer()
                silentModeButton
            }
            segmentedProgressBar
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.sm)
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private var closeButton: some View {
        Button {
            if let navigator { navigator.dismiss() } else { dismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var liturgicalSectionCaption: some View {
        Text("\(viewModel.selectedSection.title.uppercased()) · \(viewModel.currentSectionIndex + 1) DE \(HolyMassRiteSection.allCases.count)")
            .font(MassMatesFont.caption).tracking(0.8).fontWeight(.medium).foregroundStyle(MassMatesPalette.textSecondary)
    }

    private var silentModeButton: some View {
        Button { viewModel.toggleSilentMode() } label: {
            Image(systemName: viewModel.isSilentModeActive ? "bell.slash" : "bell")
                .font(.system(size: 15))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .symbolEffect(.bounce, value: viewModel.isSilentModeActive)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var segmentedProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(HolyMassRiteSection.allCases) { section in
                Capsule()
                    .fill(isSectionPassed(section) ? theme.tint : MassMatesPalette.line)
                    .frame(height: 3)
            }
        }
    }

    private func isSectionPassed(_ section: HolyMassRiteSection) -> Bool {
        (HolyMassRiteSection.allCases.firstIndex(of: section) ?? 0) <= viewModel.currentSectionIndex
    }

    private var viewportContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                selectedRiteContent
                if viewModel.selectedSection == .communionAndFinalRites {
                    HolyMassCheckInCardView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, MassMatesLayout.readingMargin)
            .padding(.top, MassMatesSpacing.md)
            .padding(.bottom, MassMatesSpacing.xl)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var selectedRiteContent: some View {
        Group {
            switch viewModel.selectedSection {
            case .initialRites: HolyMassInitialRitesView()
            case .liturgyOfTheWord: HolyMassWordRitesView()
            case .eucharisticLiturgy: HolyMassEucharisticAndFinalRitesView()
            case .communionAndFinalRites: HolyMassCommunionAndFinalRitesView()
            }
        }
        .id(viewModel.selectedSection)
        .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
        .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: viewModel.selectedSection)
    }

    private var dockedBottomNavigation: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack(spacing: 6) {
                ForEach(HolyMassRiteSection.allCases) { section in
                    Circle()
                        .fill(section == viewModel.selectedSection ? theme.tint : MassMatesPalette.line)
                        .frame(width: 6, height: 6)
                }
            }
            HStack {
                previousRiteButton
                Spacer()
                nextRiteButton
            }
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.xs).padding(.bottom, MassMatesSpacing.md)
        .background(MassMatesPalette.bg)
    }

    private var previousRiteButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { viewModel.goToPreviousSection() }
        } label: {
            Text("← Anterior")
                .font(MassMatesFont.headline).fontWeight(.regular).foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canGoToPreviousSection)
        .opacity(viewModel.canGoToPreviousSection ? 1.0 : 0.3)
    }

    private var nextRiteButton: some View {
        Button {
            if viewModel.canGoToNextSection {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { viewModel.goToNextSection() }
            } else {
                viewModel.celebrateMassCheckIn()
                onCompletePractice(.holyMass)
            }
        } label: {
            Text(viewModel.canGoToNextSection ? "Próximo →" : viewModel.registerMassButtonTitle)
                .font(MassMatesFont.headline).foregroundStyle(theme.onTint)
                .id(viewModel.canGoToNextSection)
                .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
                .padding(.horizontal, MassMatesSpacing.lg).frame(height: 50)
                .background(theme.tint).clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Holy Mass Guide — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassGuideModalView()
    }
}
