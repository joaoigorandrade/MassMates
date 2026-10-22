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
                .padding(.vertical, MassMatesSpacing.xs)
            }
            MassMatesPrimaryButton(
                title: "Absolvição Recebida (Destruir Notas)",
                systemImage: "checkmark.seal.fill"
            ) {
                Task { await viewModel.completeSacramentAndDestroyNotes() }
            }
        }
        .padding(MassMatesLayout.readingMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0).ignoresSafeArea())
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
                    ForEach(Array(viewModel.privateNotes.enumerated()), id: \.element.id) { index, note in
                        if index > 0 { darkSectionHairline }
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
