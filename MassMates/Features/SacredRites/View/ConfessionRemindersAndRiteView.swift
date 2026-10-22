import SwiftUI

struct ConfessionRemindersAndRiteView: View {
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
            priestRemindersSection
            penitentLiturgicalRiteSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var priestRemindersSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            remindersHeader
            customNoteInputRow
            if !viewModel.privateNotes.isEmpty {
                notesListView
            }
            Text("Dica: declare o pecado em espécie e número, com sobriedade e sem autojustificações.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
    }

    private var remindersHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lembretes para o Sacerdote")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Itens salvos somente neste aparelho")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            if !viewModel.privateNotes.isEmpty {
                Button {
                    viewModel.clearAllNotes()
                } label: {
                    Text("Limpar")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.danger)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customNoteInputRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            TextField("Adicionar outra falta confidencial...", text: $viewModel.customSinInput)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(height: 44)
                .background(MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.button).stroke(MassMatesPalette.line, lineWidth: 1))
                .onSubmit { viewModel.addCustomSinNote() }
            Button {
                viewModel.addCustomSinNote()
            } label: {
                Image(systemName: "plus")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.surface)
                    .frame(width: 44, height: 44)
                    .background(MassMatesPalette.textPrimary)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
        }
    }

    private var notesListView: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.privateNotes) { note in
                if note.id != viewModel.privateNotes.first?.id { Divider().overlay(MassMatesPalette.line) }
                noteRow(note)
            }
        }
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private func noteRow(_ note: ConfessionPrivateNote) -> some View {
        HStack(alignment: .center, spacing: MassMatesSpacing.xs) {
            Text("•")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(note.text)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                viewModel.removeNote(note)
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, MassMatesSpacing.xs)
    }

    private var penitentLiturgicalRiteSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Roteiro Litúrgico do Penitente")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            VStack(spacing: 0) {
                ForEach(viewModel.penitentRiteSteps) { step in
                    if step.id != viewModel.penitentRiteSteps.first?.id { Divider().overlay(MassMatesPalette.line) }
                    penitentStepBox(step)
                }
            }
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
        }
    }

    private func penitentStepBox(_ step: PenitentRiteStep) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack {
                Text(step.title.uppercased())
                    .font(MassMatesFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                if let trailingNote = step.trailingNote {
                    Text(trailingNote)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
            }
            if let lead = step.leadText {
                Text(lead).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text(step.quoteText)
                .font(MassMatesFont.customScripture(size: 15, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(3)
            if let closing = step.closingResponse {
                Text(closing).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Confession Reminders & Rite — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionRemindersAndRiteView(viewModel: ConfessionPrepViewModel())
    }
}
