import SwiftUI

struct NightlyExamenStepCardsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: NightlyExamenViewModel
    @FocusState private var isGratitudeFocused: Bool

    // MARK: - Init
    init(viewModel: NightlyExamenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            step1GratitudeCard
            step2HolySpiritCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var step1GratitudeCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                stepHeader(
                    number: "1",
                    title: "Presença de Deus & Gratidão",
                    subtitle: "Reconhecer as bênçãos e os cuidados do Pai neste dia."
                )
                Text("“Pelo que o meu coração dá graças e louvores a Deus hoje?”")
                    .font(MassMatesFont.customScripture(size: 15, italic: true))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                gratitudeChipsGrid
                TextField("Breve registro de gratidão pessoal (opcional)...", text: $viewModel.gratitudeJournalText, axis: .vertical)
                    .lineLimit(2...4)
                    .focused($isGratitudeFocused)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
        }
    }

    private var gratitudeChipsGrid: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(viewModel.gratitudeChips.prefix(2)) { gratitudeChipButton($0) }
            }
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(viewModel.gratitudeChips.dropFirst(2)) { gratitudeChipButton($0) }
            }
            Button("+ Outra graça") { isGratitudeFocused = true }
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .buttonStyle(.plain)
        }
    }

    private func gratitudeChipButton(_ chip: IgnatianGratitudeChip) -> some View {
        let isSelected = viewModel.selectedGratitudeIDs.contains(chip.id)
        return Button {
            viewModel.toggleGratitudeChip(chip.id)
        } label: {
            Label(chip.title, systemImage: chip.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var step2HolySpiritCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                stepHeader(
                    number: "2",
                    title: "Pedido de Luz ao Espírito",
                    subtitle: "Enxergar o dia com misericórdia e sem autoengano."
                )
                HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
                    Image(systemName: "sparkles").foregroundStyle(theme.tint)
                    VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                        Text("“Vinde, Espírito Santo, iluminai os recônditos da minha alma para que eu veja a verdade no amor.”")
                            .font(MassMatesFont.customScripture(size: 15, italic: true))
                            .foregroundStyle(MassMatesPalette.textPrimary)
                        Text("Silêncio de escuta interior")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(theme.tint)
                    }
                }
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
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

#Preview("Nightly Examen Steps 1–2 — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenStepCardsView(viewModel: NightlyExamenViewModel())
    }
}
