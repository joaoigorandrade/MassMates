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
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader
            stepsList
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        Text("Lectio Divina")
            .font(MassMatesFont.headline)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .padding(.bottom, MassMatesSpacing.xxs)
    }

    private var stepsList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.reading.lectioSteps) { step in
                stepRow(for: step)
                if step.id != viewModel.reading.lectioSteps.last?.id {
                    Rectangle()
                        .fill(MassMatesPalette.line)
                        .frame(height: 1)
                }
            }
        }
    }

    private func stepRow(for step: LectioDivinaStep) -> some View {
        let isExpanded = viewModel.isStepExpanded(step)
        return VStack(alignment: .leading, spacing: 0) {
            stepHeaderButton(step: step, isExpanded: isExpanded)
            if isExpanded {
                accordionBody(step: step)
            }
        }
    }

    private func stepHeaderButton(step: LectioDivinaStep, isExpanded: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectLectioStep(step)
            }
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Text("\(step.number). \(step.title)")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("•")
                    .foregroundStyle(MassMatesPalette.line)
                Text(stepSubtitle(for: step))
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, MassMatesSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    private func accordionBody(step: LectioDivinaStep) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text(step.guidance)
                .font(step.id == "oratio" ? MassMatesFont.scriptureEmphasis : MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if let attentionTitle = step.attentionPointTitle,
               let attentionBody = step.attentionPointBody {
                attentionPointBox(title: attentionTitle, body: attentionBody)
            }
        }
        .padding(.top, MassMatesSpacing.xs)
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private func attentionPointBox(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(body)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay {
            RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        }
    }

    private func stepSubtitle(for step: LectioDivinaStep) -> String {
        if let dotIndex = step.subtitle.range(of: "•")?.upperBound {
            return step.subtitle[dotIndex...].trimmingCharacters(in: .whitespaces)
        }
        return step.subtitle.isEmpty ? step.stage : step.subtitle
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
