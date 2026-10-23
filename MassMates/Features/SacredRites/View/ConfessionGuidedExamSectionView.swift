import SwiftUI

struct ConfessionGuidedExamSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: ConfessionPrepViewModel
    private let commandmentIndex: Int

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel, commandmentIndex: Int = 0) {
        self.viewModel = viewModel
        self.commandmentIndex = min(max(commandmentIndex, 0), Self.commandments.count - 1)
    }

    // MARK: - Body / Public API
    var body: some View {
        let step = Self.commandments[commandmentIndex]
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            commandmentHeader(title: step.title, summary: step.summary)
            checklistRows(items: step.items)
            customNoteInputRow
            meditativeFooter
        }
    }

    // MARK: - Subviews / Private Helpers
    private func commandmentHeader(title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(summary)
                .font(MassMatesFont.customScripture(size: 17, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func checklistRows(items: [CommandmentExamItem]) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            ForEach(items) { item in
                checklistRow(item)
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            }
        }
    }

    private func checklistRow(_ item: CommandmentExamItem) -> some View {
        let isChecked = viewModel.isExamItemChecked(item)
        return Button {
            withAnimation(.snappy(duration: 0.15)) {
                viewModel.toggleExamItem(item)
            }
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                Text(item.question)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                circularCheckmark(isChecked: isChecked)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .padding(.horizontal, MassMatesSpacing.xxs)
        }
        .buttonStyle(.plain)
    }

    private func circularCheckmark(isChecked: Bool) -> some View {
        ZStack {
            if isChecked {
                Circle().fill(theme.tint).frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.onTint)
            } else {
                Circle().stroke(MassMatesPalette.line, lineWidth: 1.5).frame(width: 22, height: 22)
            }
        }
    }

    private var customNoteInputRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            TextField("Anotar outra falta para este mandamento...", text: $viewModel.customSinInput)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(height: 40)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                .onSubmit { viewModel.addCustomSinNote() }
            Button { viewModel.addCustomSinNote() } label: {
                Image(systemName: "plus")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.onTint)
                    .frame(width: 40, height: 40)
                    .background(theme.tint)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
        }
    }

    private var meditativeFooter: some View {
        Text("Toque no círculo apenas se desejar confessar este ponto. Seu exame permanece em silêncio.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .lineSpacing(2)
            .padding(.top, MassMatesSpacing.xs)
    }

    private struct StepData: Sendable {
        let title: String
        let summary: String
        let items: [CommandmentExamItem]
    }

    private static let commandments: [StepData] = [
        StepData(title: "1º Mandamento", summary: "Amar a Deus sobre todas as coisas.", items: [
            CommandmentExamItem(id: "c1a", question: "Negligenciei a oração pessoal ou rezei com indiferença?", sinNote: "Falta à oração", isInitiallyChecked: false),
            CommandmentExamItem(id: "c1b", question: "Coloquei comodismo ou aprovação dos outros acima da fé?", sinNote: "Comodismo acima de Deus", isInitiallyChecked: false)
        ]),
        StepData(title: "2º Mandamento", summary: "Não tomar Seu Santo Nome em vão.", items: [
            CommandmentExamItem(id: "c2a", question: "Pronunciei o Santo Nome de Deus sem respeito ou com ira?", sinNote: "Uso leviano do Santo Nome", isInitiallyChecked: false),
            CommandmentExamItem(id: "c2b", question: "Fiz promessas ou juramentos falsos no Nome de Deus?", sinNote: "Juramento falso", isInitiallyChecked: false)
        ]),
        StepData(title: "3º Mandamento", summary: "Guardar domingos e festas.", items: [
            CommandmentExamItem(id: "c3a", question: "Faltei à Missa dominical por negligência ou preguiça?", sinNote: "Falta à Missa dominical", isInitiallyChecked: false),
            CommandmentExamItem(id: "c3b", question: "Cheguei atrasado à celebração sem motivo justo?", sinNote: "Atraso na Missa", isInitiallyChecked: false),
            CommandmentExamItem(id: "c3c", question: "Trabalhei sem necessidade aos domingos?", sinNote: "Trabalho servil ao domingo", isInitiallyChecked: false)
        ]),
        StepData(title: "4º Mandamento", summary: "Honrar pai e mãe.", items: [
            CommandmentExamItem(id: "c4a", question: "Fui impaciente, ríspido ou ingrato com meus pais?", sinNote: "Impaciência com pais", isInitiallyChecked: true),
            CommandmentExamItem(id: "c4b", question: "Deixei de apoiar minha família em suas necessidades?", sinNote: "Omissão familiar", isInitiallyChecked: false)
        ]),
        StepData(title: "5º Mandamento", summary: "Não matar.", items: [
            CommandmentExamItem(id: "c5a", question: "Alimentei ressentimento ou recusa em perdoar?", sinNote: "Rancor e recusa em perdoar", isInitiallyChecked: false),
            CommandmentExamItem(id: "c5b", question: "Prejudiquei minha saúde com excessos deliberados?", sinNote: "Excessos de saúde", isInitiallyChecked: false)
        ]),
        StepData(title: "6º Mandamento", summary: "Não pecar contra a castidade.", items: [
            CommandmentExamItem(id: "c6a", question: "Fui vigilante nos olhos, telas e conversas puras?", sinNote: "Falta de vigilância em telas", isInitiallyChecked: false),
            CommandmentExamItem(id: "c6b", question: "Cometi atos impuros contrários à pureza do corpo?", sinNote: "Atos impuros", isInitiallyChecked: false)
        ]),
        StepData(title: "7º Mandamento", summary: "Não furtar.", items: [
            CommandmentExamItem(id: "c7a", question: "Fui honesto nas horas de trabalho e bens alheios?", sinNote: "Desonestidade no trabalho", isInitiallyChecked: false),
            CommandmentExamItem(id: "c7b", question: "Retive bens alheios ou gastei irresponsavelmente?", sinNote: "Desperdício ou retenção", isInitiallyChecked: false)
        ]),
        StepData(title: "8º Mandamento", summary: "Não levantar falso testemunho.", items: [
            CommandmentExamItem(id: "c8a", question: "Falei mal dos outros ou proferi juízos precipitados?", sinNote: "Maledicência", isInitiallyChecked: true),
            CommandmentExamItem(id: "c8b", question: "Menti deliberadamente para obter vantagens?", sinNote: "Mentiras", isInitiallyChecked: false)
        ]),
        StepData(title: "9º Mandamento", summary: "Não desejar a mulher do próximo.", items: [
            CommandmentExamItem(id: "c9a", question: "Consenti voluntariamente em pensamentos impuros?", sinNote: "Consentimento em pensamentos impuros", isInitiallyChecked: false),
            CommandmentExamItem(id: "c9b", question: "Alimentei inveja das afeições e relações alheias?", sinNote: "Cobiça de afeições", isInitiallyChecked: false)
        ]),
        StepData(title: "10º Mandamento", summary: "Não cobiçar as coisas alheias.", items: [
            CommandmentExamItem(id: "c10a", question: "Senti inveja dos sucessos e bens materiais do próximo?", sinNote: "Inveja de bens", isInitiallyChecked: false),
            CommandmentExamItem(id: "c10b", question: "Fui apegado aos bens esquecendo a caridade fraterna?", sinNote: "Apego desordenado", isInitiallyChecked: false)
        ])
    ]
}

#Preview("Confession Guided Exam — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionGuidedExamSectionView(viewModel: ConfessionPrepViewModel())
    }
}
