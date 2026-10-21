import SwiftUI

struct ConfessionalModeOverlayView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: ConfessionPrepViewModel

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            overlayTopBar
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                    openingFormulaBlock
                    annotatedSinsBlock
                    actOfContritionBlock
                }
            }
            MassMatesPrimaryButton(
                title: "Absolvição Recebida (Destruir Notas)",
                systemImage: "checkmark.circle"
            ) {
                viewModel.completeSacramentAndDestroyNotes()
            }
        }
        .padding(MassMatesLayout.readingMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea())
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
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button {
                viewModel.closeConfessionalMode()
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
        }
    }

    private var openingFormulaBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("FÓRMULA DE INÍCIO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("\"Abençoai-me, Padre, porque pequei. Minha última confissão foi há 24 dias.\"")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    private var annotatedSinsBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("MINHAS FALTAS ANOTADAS")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            if viewModel.privateNotes.isEmpty {
                Text("Nenhuma anotação registrada. Fale com o sacerdote com confiança.")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            } else {
                ForEach(viewModel.privateNotes) { note in
                    confessionalNoteRow(note)
                }
            }
        }
    }

    private func confessionalNoteRow(_ note: ConfessionPrivateNote) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
            Text("•")
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.tint)
            Text(note.text)
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.button)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var actOfContritionBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
            Text("ATO DE CONTRIÇÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("\"Meu Deus, eu me arrependo de todo o coração de Vos ter ofendido, porque sois tão bom e amável. Prometo com Vossa graça não mais pecar e fugir das ocasiões. Meu Jesus, misericórdia!\"")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}

#Preview("Confessional Mode Overlay — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionalModeOverlayView(viewModel: ConfessionPrepViewModel())
    }
}
