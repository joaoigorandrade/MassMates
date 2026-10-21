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
            priestRemindersCard
            penitentLiturgicalRiteSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var priestRemindersCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                priestRemindersHeader
                ForEach(viewModel.privateNotes) { note in
                    priestNoteRow(note)
                }
                customNoteInputRow
                Text("Dica: diga o pecado em espécie e número, com sobriedade e sem autojustificações.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var priestRemindersHeader: some View {
        HStack {
            Image(systemName: "key.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 28, height: 28)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text("Lembretes para o Sacerdote").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Itens criptografados na memória segura").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button {
                viewModel.openConfessionalMode()
            } label: {
                Label("Modo Fila", systemImage: "circle.lefthalf.filled")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, MassMatesSpacing.xxs)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
        }
    }

    private func priestNoteRow(_ note: ConfessionPrivateNote) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(theme.tint)
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
            }
            .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.xs)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var customNoteInputRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            TextField("Adicionar outra falta confidencial...", text: $viewModel.customSinInput)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(MassMatesSpacing.xs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                .onSubmit { viewModel.addCustomSinNote() }
            Button {
                viewModel.addCustomSinNote()
            } label: {
                Image(systemName: "plus")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.onTint)
                    .frame(width: 36, height: 36)
                    .background(theme.tint)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
        }
    }

    private var penitentLiturgicalRiteSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Text("Roteiro Litúrgico do Penitente")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("Guia Prático")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    ForEach(viewModel.penitentRiteSteps) { step in
                        penitentStepBox(step)
                    }
                    Text("Padre: \"Louvai ao Senhor porque Ele é bom.\"\nVocê: \"Porque a Sua misericórdia dura para sempre.\"")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func penitentStepBox(_ step: PenitentRiteStep) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack {
                Text(step.title.uppercased())
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Spacer()
                if let trailingNote = step.trailingNote {
                    Text(trailingNote).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            if let lead = step.leadText {
                Text(lead).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text(step.quoteText)
                .font(MassMatesFont.customScripture(size: 15, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
            if let closing = step.closingResponse {
                Text(closing).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(step.isHighlighted ? theme.tintSoft : MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }
}

#Preview("Confession Reminders & Rite — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionRemindersAndRiteView(viewModel: ConfessionPrepViewModel())
    }
}
