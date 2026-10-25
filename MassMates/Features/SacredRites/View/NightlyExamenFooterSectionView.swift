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
            Text("“Qual a virtude ou atitude que desejo cultivar com especial zelo ao despertar?”")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)

            virtuesGridSection
            complineBlessingCard

            if viewModel.isExamenConcluded {
                completionFeedbackBanner
                diarySaveActionRow
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var virtuesGridSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("PROPÓSITO PARA AMANHÃ")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MassMatesSpacing.xs) {
                ForEach(viewModel.virtueOptions) { virtue in
                    virtueTile(virtue)
                }
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
                    Text(virtue.title)
                        .font(MassMatesFont.callout)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(theme.tint)
                    }
                }
                Text(virtue.subtitle)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.button)
                    .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
            .contentShape(Rectangle())
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
                .lineSpacing(4)

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
                    .fontWeight(.semibold)
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

    private var diarySaveActionRow: some View {
        Button {
            Task { await viewModel.saveToPrivateJournal() }
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: viewModel.isSavedToLocalJournal ? "checkmark.circle.fill" : "book.closed")
                Text(viewModel.saveJournalButtonTitle)
            }
            .font(MassMatesFont.callout)
            .foregroundStyle(viewModel.isSavedToLocalJournal ? MassMatesPalette.success : theme.tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Nightly Examen Footer — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenFooterSectionView(viewModel: NightlyExamenViewModel(isExamenConcluded: true))
    }
}
