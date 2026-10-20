import Navigation
import SwiftUI

struct DailyGospelModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: DailyGospelViewModel

    // MARK: - Init
    init(viewModel: DailyGospelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                headerToolbar
                fontSizeControlRow
                readingBlock(
                    reference: viewModel.reading.firstReadingReference,
                    title: viewModel.reading.firstReadingTitle,
                    bodyText: viewModel.reading.firstReadingText
                )
                psalmBlock
                readingBlock(
                    reference: viewModel.reading.gospelReference,
                    title: viewModel.reading.gospelTitle,
                    bodyText: viewModel.reading.gospelText
                )
                lectioDivinaSection
                MassMatesPrimaryButton(title: "Concluir e refletir", systemImage: "checkmark") {
                    viewModel.completeAndReflect()
                    navigator?.dismiss()
                }
            }
            .padding(MassMatesLayout.readingMargin)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerToolbar: some View {
        HStack {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text(viewModel.reading.liturgicalDateLabel)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("Liturgia da Palavra")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Button("Fechar") {
                navigator?.dismiss()
            }
            .font(MassMatesFont.callout)
            .foregroundStyle(theme.tint)
            .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
        }
    }

    private var fontSizeControlRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "textformat.size")
                .foregroundStyle(MassMatesPalette.textSecondary)
            Slider(value: $viewModel.scriptureFontSize, in: 16...28, step: 1)
                .tint(theme.tint)
                .accessibilityLabel("Tamanho da fonte bíblica")
            Text("\(Int(viewModel.scriptureFontSize)) pt")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func readingBlock(reference: String, title: String, bodyText: String) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Rectangle()
                .fill(theme.tint)
                .frame(width: MassMatesSpacing.xl, height: 1)
            Text(reference)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(title)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(bodyText)
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize))
                .lineSpacing(8)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var psalmBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Rectangle()
                .fill(theme.tint)
                .frame(width: MassMatesSpacing.xl, height: 1)
            Text(viewModel.reading.psalmReference)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(viewModel.reading.psalmRefrain)
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.reading.psalmVerses)
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize))
                .lineSpacing(8)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lectioDivinaSection: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Lectio Divina")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                lectioStepsTabs
                if let activeStep = viewModel.activeLectioStep {
                    Text(activeStep.title)
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(activeStep.guidance)
                        .font(MassMatesFont.scriptureEmphasis)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    private var lectioStepsTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(viewModel.reading.lectioSteps) { step in
                    lectioStepChip(step)
                }
            }
        }
    }

    private func lectioStepChip(_ step: LectioDivinaStep) -> some View {
        let isSelected = step.id == viewModel.activeLectioStepID
        return Button {
            viewModel.selectLectioStep(step)
        } label: {
            Text(step.stage)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Daily Gospel Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DailyGospelModalView(
            viewModel: DailyGospelViewModel(
                reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime)
            )
        )
    }
}
