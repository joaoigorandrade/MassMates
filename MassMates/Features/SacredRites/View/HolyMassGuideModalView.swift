import Navigation
import SwiftUI

struct HolyMassGuideModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
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
            navigator?.dismiss()
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
        let curr = viewModel.currentSectionIndex + 1
        let total = HolyMassRiteSection.allCases.count
        return Text("\(viewModel.selectedSection.title.uppercased()) · \(curr) DE \(total)")
            .font(MassMatesFont.caption)
            .tracking(0.8)
            .fontWeight(.medium)
            .foregroundStyle(MassMatesPalette.textSecondary)
    }

    private var silentModeButton: some View {
        Button {
            viewModel.toggleSilentMode()
        } label: {
            Image(systemName: viewModel.isSilentModeActive ? "bell.slash" : "bell")
                .font(.system(size: 15))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var segmentedProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<HolyMassRiteSection.allCases.count, id: \.self) { idx in
                Capsule()
                    .fill(idx <= viewModel.currentSectionIndex ? theme.tint : MassMatesPalette.line)
                    .frame(height: 3)
            }
        }
    }

    private var viewportContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            selectedRiteContent
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.md)
        .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var selectedRiteContent: some View {
        switch viewModel.selectedSection {
        case .initialRites: HolyMassInitialRitesView()
        case .liturgyOfTheWord: HolyMassWordRitesView()
        case .eucharisticLiturgy: HolyMassEucharisticAndFinalRitesView()
        case .communionAndFinalRites: HolyMassCommunionAndFinalRitesView()
        }
    }

    private var dockedBottomNavigation: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack(spacing: 6) {
                ForEach(0..<HolyMassRiteSection.allCases.count, id: \.self) { idx in
                    Circle()
                        .fill(idx == viewModel.currentSectionIndex ? theme.tint : MassMatesPalette.line)
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
        .padding(.top, MassMatesSpacing.xs)
        .padding(.bottom, MassMatesSpacing.md)
        .background(MassMatesPalette.bg)
    }

    private var previousRiteButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.goToPreviousSection() }
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
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.goToNextSection() }
            } else {
                viewModel.celebrateMassCheckIn()
            }
        } label: {
            Text(viewModel.canGoToNextSection ? "Próximo →" : viewModel.registerMassButtonTitle)
                .font(MassMatesFont.headline).foregroundStyle(theme.onTint)
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
