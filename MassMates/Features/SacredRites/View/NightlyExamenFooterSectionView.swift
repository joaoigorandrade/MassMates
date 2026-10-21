import SwiftUI

struct NightlyExamenFooterSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: NightlyExamenViewModel

    // MARK: - Init
    init(viewModel: NightlyExamenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            step5HopeAndPurposeCard
            complineBlessingCard
            if viewModel.isExamenConcluded {
                completionFeedbackBanner
            }
            footerActionButtons
            privacyReassuranceFooter
        }
    }

    // MARK: - Subviews / Private Helpers
    private var step5HopeAndPurposeCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                step5Header
                Text("“Qual a virtude ou atitude que desejo cultivar com especial zelo ao despertar?”")
                    .font(MassMatesFont.customScripture(size: 15, italic: true))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MassMatesSpacing.xs) {
                    ForEach(viewModel.virtueOptions) { virtueTile($0) }
                }
            }
        }
    }

    private var step5Header: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("5")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 28, height: 28)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text("Esperança & Propósito").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Entregar a noite a Deus e despertar pronto para servir.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private func virtueTile(_ virtue: ExamenVirtueOption) -> some View {
        let isSelected = viewModel.selectedVirtueID == virtue.id
        return Button {
            viewModel.selectVirtue(virtue.id)
        } label: {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                HStack {
                    Text(virtue.title).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                    }
                }
                Text(virtue.subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var complineBlessingCard: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("BÊNÇÃO DAS COMPLETAS")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("“O Senhor todo-poderoso nos conceda uma noite tranquila e um fim perfeito.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Text("Amém.")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var completionFeedbackBanner: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            StreakRingView(streakDays: 14, progress: 1.0, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Exame recolhido com paz")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("14º dia seguido nutrindo o hábito do recolhimento noturno.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var footerActionButtons: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: viewModel.concludeButtonTitle,
                systemImage: viewModel.concludeButtonSystemImage
            ) {
                viewModel.concludeExamen()
            }
            MassMatesSecondaryButton(title: viewModel.saveJournalButtonTitle) {
                viewModel.saveToPrivateJournal()
            }
        }
    }

    private var privacyReassuranceFooter: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "lock.fill")
                .font(MassMatesFont.caption)
            Text("Nenhum dado deste exame sai deste aparelho. Fique em paz.")
                .font(MassMatesFont.caption)
        }
        .foregroundStyle(MassMatesPalette.textTertiary)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Nightly Examen Footer — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenFooterSectionView(viewModel: NightlyExamenViewModel(isExamenConcluded: true))
    }
}
