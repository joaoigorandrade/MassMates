import Navigation
import SwiftUI

struct ConfessionalModeOverlayView: View {
    // MARK: - Dependencies & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: ConfessionPrepViewModel

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            overlayTopBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                    openingFormulaBlock
                    annotatedSinsBlock
                    actOfContritionBlock
                }
                .padding(.vertical, MassMatesSpacing.xs)
                .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            }
            MassMatesPrimaryButton(
                title: "Apagar Notas e Concluir",
                systemImage: "checkmark.seal.fill"
            ) {
                Task {
                    await viewModel.completeSacramentAndDestroyNotes()
                    onCompletePractice(.confession)
                    if let navigator { navigator.dismiss() } else { dismiss() }
                }
            }
            .frame(maxWidth: MassMatesLayout.readingMaxWidth)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .padding(.top, MassMatesSpacing.md)
        .padding(.bottom, MassMatesSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Subviews / Private Helpers
    private var overlayTopBar: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(theme.tint)
                Text("MODO CONFESSIONÁRIO")
                    .font(MassMatesFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button {
                viewModel.closeConfessionalMode()
            } label: {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: "xmark")
                    Text("Sair")
                }
                .font(MassMatesFont.caption.weight(.medium))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sair do Modo Confessionário")
        }
    }

    private var openingFormulaBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("FÓRMULA DE INÍCIO")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("\"Abençoai-me, Padre, porque pequei. Minha última confissão foi há 24 dias.\"")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
        }
    }

    private var annotatedSinsBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            darkSectionHairline
            Text("MINHAS FALTAS ANOTADAS")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            if viewModel.privateNotes.isEmpty {
                Text("Nenhuma anotação registrada. Fale com o sacerdote com confiança.")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .padding(.vertical, MassMatesSpacing.xs)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.privateNotes) { note in
                        if note.id != viewModel.privateNotes.first?.id { darkSectionHairline }
                        confessionalNoteRow(note)
                    }
                }
            }
        }
    }

    private func confessionalNoteRow(_ note: ConfessionPrivateNote) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Text("•")
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.tint)
            Text(note.text)
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, MassMatesSpacing.sm)
    }

    private var actOfContritionBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            darkSectionHairline
            Text("ATO DE CONTRIÇÃO")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("\"Meu Deus, eu me arrependo de todo o coração de Vos ter ofendido, porque sois tão bom e amável. Prometo com Vossa graça não mais pecar e fugir das ocasiões. Meu Jesus, misericórdia!\"")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
        }
    }

    private var darkSectionHairline: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }
}

#Preview("Confessional Mode Overlay — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionalModeOverlayView(viewModel: ConfessionPrepViewModel())
    }
}
