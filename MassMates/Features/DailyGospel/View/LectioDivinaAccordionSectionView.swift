import SwiftUI

struct LectioDivinaAccordionSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: DailyGospelViewModel

    // MARK: - Init
    init(viewModel: DailyGospelViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader
            Text("Guia tradicional dos Padres do Deserto para acolher e ruminar a Palavra de Deus.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: MassMatesSpacing.sm) {
                ForEach(viewModel.reading.lectioSteps) { step in
                    accordionCard(for: step)
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "book.pages")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                Text("Lectio Divina")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Text("4 Passos")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private func accordionCard(for step: LectioDivinaStep) -> some View {
        let isExpanded = viewModel.isStepExpanded(step)
        return VStack(alignment: .leading, spacing: 0) {
            accordionHeaderButton(step: step, isExpanded: isExpanded)
            if isExpanded {
                accordionBodyContent(step: step)
            }
        }
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        }
    }

    private func accordionHeaderButton(step: LectioDivinaStep, isExpanded: Bool) -> some View {
        Button {
            viewModel.selectLectioStep(step)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                Text("\(step.number)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .frame(width: 28, height: 28)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(step.subtitle.isEmpty ? step.stage : step.subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(MassMatesSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private func accordionBodyContent(step: LectioDivinaStep) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text(step.guidance)
                .font(step.id == "oratio" ? MassMatesFont.scriptureEmphasis : MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let attentionTitle = step.attentionPointTitle,
               let attentionBody = step.attentionPointBody {
                VStack(alignment: .leading, spacing: 2) {
                    Text(attentionTitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(attentionBody)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            }
        }
        .padding(.horizontal, MassMatesSpacing.md)
        .padding(.bottom, MassMatesSpacing.md)
    }
}

#Preview("Lectio Divina Accordion — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        LectioDivinaAccordionSectionView(
            viewModel: DailyGospelViewModel(
                reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime)
            )
        )
    }
}
