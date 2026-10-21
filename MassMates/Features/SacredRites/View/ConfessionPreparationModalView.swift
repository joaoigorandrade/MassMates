import Navigation
import SwiftUI

struct ConfessionPreparationModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: ConfessionPrepViewModel

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel = ConfessionPrepViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ZStack {
            mainScrollContent
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
                headerToolbar
                ConfessionHeaderAndStepsView(viewModel: viewModel)
                ConfessionGuidedExamSectionView(viewModel: viewModel)
                ConfessionRemindersAndRiteView(viewModel: viewModel)
                if let banner = viewModel.statusBannerText {
                    statusFeedbackCard(banner)
                }
                actionFooterSection
            }
            .padding(MassMatesLayout.screenMargin)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var headerToolbar: some View {
        HStack {
            Button {
                navigator?.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(theme.tint)
                Text("Preparacao Para A Confissao")
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            .font(MassMatesFont.caption)
            .padding(.horizontal, MassMatesSpacing.sm)
            .padding(.vertical, MassMatesSpacing.xxs)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            Spacer()
            Image(systemName: "person.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.onTint)
                .frame(width: 32, height: 32)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private func statusFeedbackCard(_ text: String) -> some View {
        Text(text)
            .font(MassMatesFont.caption)
            .foregroundStyle(theme.tint)
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var actionFooterSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: "Registrar Sacramento & Apagar Notas",
                systemImage: "checkmark.seal.fill"
            ) {
                viewModel.completeSacramentAndDestroyNotes()
            }
            MassMatesSecondaryButton(
                title: "Salvar Rascunho Criptografado",
                systemImage: "lock.fill"
            ) {
                viewModel.saveEncryptedDraft()
            }
            Text("Ao confirmar o Sacramento, a data da sua confissão é atualizada para hoje e todas as anotações secretas são apagadas definitivamente da memória do celular.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, MassMatesSpacing.xxs)
        }
    }
}

#Preview("Confession Preparation Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionPreparationModalView(viewModel: ConfessionPrepViewModel())
    }
}
