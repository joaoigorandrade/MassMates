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
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            step3ReviewOfHoursCard
            step4ContritionCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var step3ReviewOfHoursCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                stepHeader(
                    number: "3", title: "Passar em Revista as Horas",
                    subtitle: "Percorrer as ações, palavras, silêncios e afetos."
                )
                morningLectioBox
                Text("ATENÇÕES DA CONSCIÊNCIA:")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                ForEach(viewModel.attentionPrompts) { attentionCheckboxRow($0) }
            }
        }
    }

    private var morningLectioBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Label("RESOLUÇÃO DA MANHÃ (LECTIO)", systemImage: "sun.haze")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("“Guardar o recolhimento nas conversas de trabalho e não alimentar queixas nem murmurações.”")
                .font(MassMatesFont.customScripture(size: 15, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MassMatesSpacing.xs) {
                    ForEach(LectioResolutionEvaluation.allCases) { evaluationPillButton($0) }
                }
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private func evaluationPillButton(_ evaluation: LectioResolutionEvaluation) -> some View {
        let isSelected = viewModel.selectedEvaluation == evaluation
        let semanticColor: Color = {
            switch evaluation {
            case .fidelidade: MassMatesPalette.success
            case .deslize: MassMatesPalette.warning
            case .graca: Theme(season: .purple).tint
            }
        }()
        return Button { viewModel.selectEvaluation(evaluation) } label: {
            Label(evaluation.title, systemImage: evaluation.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? semanticColor : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(isSelected ? semanticColor.opacity(0.14) : MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.chip).stroke(isSelected ? semanticColor : MassMatesPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func attentionCheckboxRow(_ prompt: ConscienceAttentionPrompt) -> some View {
        let isChecked = viewModel.checkedAttentionIDs.contains(prompt.id)
        return Button { viewModel.toggleAttentionPrompt(prompt.id) } label: {
            HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? theme.tint : MassMatesPalette.textTertiary)
                Text(prompt.text).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(MassMatesSpacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var step4ContritionCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                stepHeader(number: "4", title: "Contrição & Perdão", subtitle: "Confiar no Amor misericordioso que acolhe e restaura.")
                actOfContritionBox
                confessionNoteTriggerRow
                if viewModel.isConfessionNoteExpanded { confessionNoteInputSection }
            }
        }
    }

    private var actOfContritionBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("ATO DE CONTRIÇÃO").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            Text("“Meu Deus, eu me arrependo de todo o coração de vos ter ofendido, porque sois infinitamente bom e digno de todo o amor. Proponho firmemente, com a vossa graça, não mais pecar e fugir das ocasiões de queda. Amém.”")
                .font(MassMatesFont.customScripture(size: 15, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var confessionNoteTriggerRow: some View {
        HStack {
            Label("Anotar para o Sacramento da Confissão", systemImage: "lock.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Button("Adicionar") { viewModel.toggleConfessionNoteInput() }
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.xs)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var confessionNoteInputSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            TextField("Ponto íntimo para o próximo confessor...", text: $viewModel.privateConfessionNote)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(MassMatesSpacing.sm)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            Text("Ficará visível exclusivamente no seu módulo seguro de Confissão.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private func stepHeader(number: String, title: String, subtitle: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text(number)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 28, height: 28)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text(subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }
}

#Preview("Nightly Examen Steps 3–4 — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenReviewAndClosingView(viewModel: NightlyExamenViewModel())
    }
}
