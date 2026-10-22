import SwiftUI

struct NightlyExamenReviewAndClosingView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: NightlyExamenViewModel

    // MARK: - Init
    init(viewModel: NightlyExamenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            if viewModel.currentStepIndex == 3 {
                step3ReviewContent
            } else {
                step4ContritionContent
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var step3ReviewContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Percorra com serenidade as ações, palavras e afetos deste dia. Onde respondi à graça e onde me fechei?")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            morningLectioResolutionBox
            attentionPromptsSection
        }
    }

    private var morningLectioResolutionBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "sun.haze").foregroundStyle(theme.tint)
                Text("RESOLUÇÃO DA MANHÃ (LECTIO)").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text("“Guardar o recolhimento nas conversas de trabalho e não alimentar queixas nem murmurações.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(LectioResolutionEvaluation.allCases) { evaluationPillButton($0) }
            }
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private func evaluationPillButton(_ evaluation: LectioResolutionEvaluation) -> some View {
        let isSelected = viewModel.selectedEvaluation == evaluation
        return Button { viewModel.selectEvaluation(evaluation) } label: {
            Text(evaluation.title)
                .font(MassMatesFont.caption)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: 36)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.chip).stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var attentionPromptsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("ATENÇÕES DA CONSCIÊNCIA").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            ForEach(viewModel.attentionPrompts) { attentionCheckboxRow($0) }
        }
    }

    private func attentionCheckboxRow(_ prompt: ConscienceAttentionPrompt) -> some View {
        let isChecked = viewModel.checkedAttentionIDs.contains(prompt.id)
        return Button { viewModel.toggleAttentionPrompt(prompt.id) } label: {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(isChecked ? theme.tint : MassMatesPalette.textTertiary)
                Text(prompt.text).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
            }
            .padding(MassMatesSpacing.sm)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .background(isChecked ? theme.tintSoft.opacity(0.4) : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var step4ContritionContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Acolha o amor misericordioso do Senhor que perdoa e restaura. Descanse no abraço do Pai.")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            actOfContritionBox
            confessionNoteSection
        }
    }

    private var actOfContritionBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("ATO DE CONTRIÇÃO").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            Text("“Meu Deus, eu me arrependo de todo o coração de vos ter ofendido, porque sois infinitamente bom e digno de todo o amor. Proponho firmemente, com a vossa graça, não mais pecar e fugir das ocasiões de queda. Amém.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var confessionNoteSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Button { viewModel.toggleConfessionNoteInput() } label: {
                HStack(spacing: MassMatesSpacing.xs) {
                    Image(systemName: "lock.fill").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                    Text("Anotar para o Sacramento da Confissão").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Image(systemName: viewModel.isConfessionNoteExpanded ? "chevron.up" : "chevron.down")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                .padding(MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
            if viewModel.isConfessionNoteExpanded {
                TextField("Ponto íntimo para o próximo confessor...", text: $viewModel.privateConfessionNote, axis: .vertical)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .padding(MassMatesSpacing.md)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.card))
                Text("Ficará visível exclusivamente no seu módulo seguro de Confissão.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .padding(.leading, MassMatesSpacing.xs)
            }
        }
    }
}

#Preview("Nightly Examen Steps 3–4 — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenReviewAndClosingView(viewModel: NightlyExamenViewModel())
    }
}
