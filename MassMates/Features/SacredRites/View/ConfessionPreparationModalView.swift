import Navigation
import SwiftUI

struct ConfessionPreparationModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: ConfessionPrepViewModel
    @State private var selectedTab: ConfessionTab = .commandments

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel = ConfessionPrepViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack(alignment: .bottom) {
            mainScrollContent
            dockedSanctuaryActionBar
            if viewModel.isConfessionalModePresented {
                ConfessionalModeOverlayView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var mainScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                topNavigationBar
                ConfessionHeaderAndStepsView(viewModel: viewModel, selectedTab: $selectedTab)
                tabContentSection
                if let banner = viewModel.statusBannerText {
                    statusFeedbackCard(banner)
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.top, MassMatesSpacing.sm)
            .padding(.bottom, 120)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var topNavigationBar: some View {
        HStack {
            Button {
                navigator?.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget, alignment: .leading)
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "lock.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("Somente no seu dispositivo")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var tabContentSection: some View {
        switch selectedTab {
        case .commandments:
            ConfessionGuidedExamSectionView(viewModel: viewModel)
        case .contrition:
            actOfContritionCard
        case .rite:
            ConfessionRemindersAndRiteView(viewModel: viewModel)
        }
    }

    private var actOfContritionCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Ato de Contrição")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("\"Meu Deus, eu me arrependo de todo o coração de Vos ter ofendido, porque sois tão bom e amável. Prometo firmemente, com a ajuda da Vossa graça, nunca mais Vos ofender e fugir das ocasiões de pecar. Meu Jesus, misericórdia!\"")
                .font(MassMatesFont.customScripture(size: 16, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
                .padding(MassMatesSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.card))
                .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
        }
    }

    private func statusFeedbackCard(_ text: String) -> some View {
        Text(text)
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var dockedSanctuaryActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
            VStack(spacing: MassMatesSpacing.xxs) {
                Button {
                    viewModel.openConfessionalMode()
                } label: {
                    Text("Modo confessionário")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                        .background(MassMatesPalette.textPrimary)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                }
                .buttonStyle(.plain)
                Text("As notas selecionadas serão apagadas após a confissão.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.top, MassMatesSpacing.xs)
            .padding(.bottom, MassMatesSpacing.md)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(MassMatesPalette.bg.opacity(0.95))
    }
}

#Preview("Confession Preparation Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionPreparationModalView(viewModel: ConfessionPrepViewModel())
    }
}
