import SwiftUI

struct NightlyExamenStepCardsView: View {
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
            if viewModel.currentStepIndex == 1 {
                step1GratitudeView
            } else {
                step2LuzDoEspiritoView
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var step1GratitudeView: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Onde senti a presença e os dons de Deus hoje?")
                .font(MassMatesFont.scripture).foregroundStyle(MassMatesPalette.textPrimary).lineSpacing(4)
            hairlineJournalInput
            gratitudeChipsSection
        }
    }

    private var hairlineJournalInput: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            TextField("Escreva, se quiser…", text: $viewModel.gratitudeJournalText, axis: .vertical)
                .font(MassMatesFont.scripture).foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(3...5).padding(.vertical, MassMatesSpacing.xs)
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            Text("Um instante de silêncio e gratidão já é oração completa.")
                .font(MassMatesFont.caption).italic().foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var gratitudeChipsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("BÊNÇÃOS RECONHECIDAS").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            FlowWrapLayout(horizontalSpacing: MassMatesSpacing.xs, verticalSpacing: MassMatesSpacing.xs) {
                ForEach(viewModel.gratitudeChips) { chipButton($0) }
            }
        }
    }

    private func chipButton(_ chip: IgnatianGratitudeChip) -> some View {
        let isSelected = viewModel.selectedGratitudeIDs.contains(chip.id)
        return Button { viewModel.toggleGratitudeChip(chip.id) } label: {
            Label(chip.title, systemImage: chip.systemImage)
                .font(MassMatesFont.caption).foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm).frame(minHeight: 34)
                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var step2LuzDoEspiritoView: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("“Em paz me deito e logo adormeço, porque só vós, Senhor, me fazeis viver seguro.”")
                .font(MassMatesFont.scripture).foregroundStyle(MassMatesPalette.textPrimary).lineSpacing(4)
            Text("SALMO 4, 9").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            invocationCard
            presenceChoices
            ambientAudioRow
        }
    }

    private var invocationCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "sparkles").foregroundStyle(theme.tint)
                Text("INVOCAÇÃO AO ESPÍRITO SANTO").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text("“Vinde, Espírito Santo, iluminai os recônditos da minha alma para que eu veja a verdade no amor.”")
                .font(MassMatesFont.scriptureEmphasis).foregroundStyle(MassMatesPalette.textPrimary).lineSpacing(3)
        }
        .padding(MassMatesSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var presenceChoices: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Como vivi a presença do Senhor hoje?").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(ExamenPresenceEvaluation.allCases) { presenceButton($0) }
            }
        }
    }

    private func presenceButton(_ eval: ExamenPresenceEvaluation) -> some View {
        let isSelected = viewModel.selectedPresence == eval
        return Button { viewModel.selectPresence(eval) } label: {
            Text(eval.title)
                .font(MassMatesFont.callout).fontWeight(isSelected ? .medium : .regular)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                .frame(maxWidth: .infinity).frame(minHeight: 40)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.chip).stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var ambientAudioRow: some View {
        Button { viewModel.toggleAmbientAudio() } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: viewModel.ambientAudioSystemImage)
                    .foregroundStyle(viewModel.isAmbientMusicPlaying ? MassMatesPalette.success : theme.tint)
                Text(viewModel.ambientAudioLabel).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text(viewModel.isAmbientMusicPlaying ? "Ligado" : "Tocar").font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
            .padding(.horizontal, MassMatesSpacing.md).frame(height: 40)
            .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Nightly Examen Steps 1–2 — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenStepCardsView(viewModel: NightlyExamenViewModel())
    }
}
