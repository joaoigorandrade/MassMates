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
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            if viewModel.currentStepIndex == 1 {
                step1PresenceContent
            } else {
                step2GratitudeContent
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var step1PresenceContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("“Em paz me deito e logo adormeço, porque só vós, Senhor, me fazeis viver seguro.”")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            Text("SALMO 4, 9")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            holySpiritInvocationCard
            presenceChoiceSection
            ambientAudioRow
        }
    }

    private var holySpiritInvocationCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "sparkles").foregroundStyle(theme.tint)
                Text("INVOCAÇÃO AO ESPÍRITO SANTO").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text("“Vinde, Espírito Santo, iluminai os recônditos da minha alma para que eu veja a verdade no amor.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var presenceChoiceSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Como vivi a presença do Senhor hoje?").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(ExamenPresenceEvaluation.allCases) { presenceChoiceButton($0) }
            }
        }
    }

    private func presenceChoiceButton(_ evaluation: ExamenPresenceEvaluation) -> some View {
        let isSelected = viewModel.selectedPresence == evaluation
        return Button { viewModel.selectPresence(evaluation) } label: {
            Text(evaluation.title)
                .font(MassMatesFont.callout)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: MassMatesLayout.minTapTarget)
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
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var step2GratitudeContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Pelo que o meu coração dá graças a Deus hoje? Reconheça a presença suave do Pai nas horas que passaram.")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            gratitudeChipsSection
            gratitudeTextareaForm
        }
    }

    private var gratitudeChipsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("BÊNÇÃOS RECONHECIDAS").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            FlowWrapLayout(horizontalSpacing: MassMatesSpacing.xs, verticalSpacing: MassMatesSpacing.xs) {
                ForEach(viewModel.gratitudeChips) { gratitudeChipButton($0) }
            }
        }
    }

    private func gratitudeChipButton(_ chip: IgnatianGratitudeChip) -> some View {
        let isSelected = viewModel.selectedGratitudeIDs.contains(chip.id)
        return Button { viewModel.toggleGratitudeChip(chip.id) } label: {
            Label(chip.title, systemImage: chip.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: 36)
                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var gratitudeTextareaForm: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("REGISTRO DE GRATIDÃO").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            TextField("Escreva aqui sua oração de gratidão (opcional)...", text: $viewModel.gratitudeJournalText, axis: .vertical)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(MassMatesSpacing.md)
                .frame(minHeight: 110, alignment: .topLeading)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        }
    }
}

#Preview("Nightly Examen Steps 1–2 — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenStepCardsView(viewModel: NightlyExamenViewModel())
    }
}
