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
            progressTrack
            scrollViewContent
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            dockedBottomNavigation
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Button { navigator?.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer(minLength: 0)
            let curr = viewModel.currentSectionIndex + 1
            let total = HolyMassRiteSection.allCases.count
            Text("\(viewModel.selectedSection.title.uppercased()) · \(curr)/\(total)")
                .font(MassMatesFont.caption).tracking(0.5).foregroundStyle(MassMatesPalette.textSecondary)
            Spacer(minLength: 0)
            Button { viewModel.toggleSilentMode() } label: {
                Image(systemName: viewModel.isSilentModeActive ? "bell.slash" : "bell")
                    .font(.system(size: 16)).foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isSilentModeActive ? "Silêncio ativo" : "Notificações ativas")
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .frame(height: 48)
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(MassMatesPalette.line)
                Rectangle().fill(theme.tint)
                    .frame(width: max(0, geo.size.width * CGFloat(viewModel.progressRatio)))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.progressRatio)
            }
        }
        .frame(height: 2)
    }

    private var scrollViewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                riteHeaderTitle
                riteSectionTabs
                selectedRiteContent
                HolyMassCheckInCardView(viewModel: viewModel)
                contemplativeFooter
            }
            .padding(MassMatesLayout.readingMargin)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var riteHeaderTitle: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Celebração da Santa Missa")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            HStack(spacing: MassMatesSpacing.sm) {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Circle().fill(theme.tint).frame(width: 6, height: 6)
                    Text("TEMPO COMUM").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Label(viewModel.currentPosture.rawValue, systemImage: viewModel.currentPosture.systemImage)
                    .font(MassMatesFont.caption).foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.xs).padding(.vertical, 2)
                    .background(theme.tintSoft).clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
        }
    }

    private var riteSectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(HolyMassRiteSection.allCases) { section in
                    let isSel = viewModel.selectedSection == section
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectSection(section) }
                    } label: {
                        Text(section.title).font(MassMatesFont.callout)
                            .foregroundStyle(isSel ? MassMatesPalette.surface : MassMatesPalette.textSecondary)
                            .padding(.horizontal, MassMatesSpacing.md).frame(minHeight: 36)
                            .background(isSel ? theme.tint : MassMatesPalette.surfaceMuted)
                            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.goToPreviousSection() }
            } label: {
                Label("Anterior", systemImage: "chevron.left")
                    .font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGoToPreviousSection)
            .opacity(viewModel.canGoToPreviousSection ? 1.0 : 0.3)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.goToNextSection() }
            } label: {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Text("Próximo").font(MassMatesFont.callout.weight(.semibold))
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(theme.tint).frame(minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGoToNextSection)
            .opacity(viewModel.canGoToNextSection ? 1.0 : 0.3)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin).frame(height: 56)
        .background(MassMatesPalette.bg.opacity(0.95).background(.ultraThinMaterial))
        .overlay(alignment: .top) { Rectangle().fill(MassMatesPalette.line).frame(height: 1) }
    }

    private var contemplativeFooter: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Label("ITE, MISSA EST", systemImage: "building.columns")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            Text("«O silêncio interior é o espaço sagrado onde Deus nos visita.»")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, MassMatesSpacing.lg)
    }
}

#Preview("Holy Mass Guide — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassGuideModalView()
    }
}
