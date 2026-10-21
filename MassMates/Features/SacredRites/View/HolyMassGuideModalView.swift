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
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerToolbar
                statusBanner
                riteTabs
                selectedRiteContent
                HolyMassCheckInCardView(viewModel: viewModel)
                contemplativeFooter
            }
            .padding(MassMatesLayout.readingMargin)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerToolbar: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Button { navigator?.dismiss() } label: {
                Image(systemName: "chevron.left")
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MassMatesPalette.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Celebração Da Santa Missa & Guia Dos Ritos")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineLimit(2)
                HStack(spacing: MassMatesSpacing.xxs) {
                    Circle().fill(theme.tint).frame(width: 6, height: 6)
                    Text("TEMPO COMUM • MODO CELEBRAÇÃO")
                }
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer(minLength: 0)
            silentModeButton
        }
    }

    private var silentModeButton: some View {
        Button { viewModel.toggleSilentMode() } label: {
            Image(systemName: viewModel.isSilentModeActive ? "bell.slash" : "bell")
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isSilentModeActive ? "Silêncio ativo" : "Notificações ativas")
    }

    private var statusBanner: some View {
        HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Circle().fill(theme.tint).frame(width: 8, height: 8)
                    Text("28º DOMINGO DO TEMPO COMUM • ANO B")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                Text("Modo Igreja Ativo • Silêncio Sagrado")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer(minLength: 0)
            Label(viewModel.currentPosture.rawValue, systemImage: viewModel.currentPosture.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .contentTransition(.opacity)
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var riteTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(HolyMassRiteSection.allCases) { section in
                    riteTabButton(section)
                }
            }
        }
    }

    private func riteTabButton(_ section: HolyMassRiteSection) -> some View {
        let isSelected = viewModel.selectedSection == section
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectSection(section) }
        } label: {
            Label(section.title, systemImage: section.systemImage)
                .font(MassMatesFont.callout)
                .foregroundStyle(isSelected ? MassMatesPalette.surface : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.md)
                .frame(minHeight: 40)
                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
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

    private var contemplativeFooter: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Label("ITE, MISSA EST", systemImage: "building.columns")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("«O silêncio interior é o espaço sagrado onde Deus nos visita.»")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MassMatesSpacing.lg)
    }
}

#Preview("Holy Mass Guide — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassGuideModalView()
    }
}
