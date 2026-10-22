import Navigation
import SwiftUI

struct LectioDivinaAccordionSectionView: View {
    // MARK: - Dependencies & State
    private struct StepItem: Identifiable, Sendable {
        let id: String; let number: Int; let stage: String; let prompt: String
    }

    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable var viewModel: DailyGospelViewModel
    var onDismiss: (() -> Void)?

    private let steps: [StepItem] = [
        .init(id: "lectio", number: 1, stage: "Ler", prompt: "O que o texto diz em si?"),
        .init(id: "meditatio", number: 2, stage: "Meditar", prompt: "O que Deus me diz através deste texto?"),
        .init(id: "oratio", number: 3, stage: "Orar", prompt: "O que respondo a Deus em oração?"),
        .init(id: "contemplatio", number: 4, stage: "Contemplar", prompt: "Repousar no silêncio da Sua presença.")
    ]

    // MARK: - Init
    init(viewModel: DailyGospelViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Spacer(minLength: MassMatesSpacing.sm)
            stepsSection
            Spacer(minLength: MassMatesSpacing.sm)
            bottomActionBar
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .frame(maxWidth: MassMatesLayout.readingMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerView: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack {
                Button(action: handleDismiss) {
                    Image(systemName: "chevron.left").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                }
                .buttonStyle(.plain).accessibilityLabel("Voltar")
                Spacer()
            }
            Text("ORAÇÃO CONTEMPLATIVA").font(MassMatesFont.caption).tracking(1.5).foregroundStyle(MassMatesPalette.textSecondary).padding(.top, MassMatesSpacing.xs)
            Text("Lectio Divina").font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepsSection: some View {
        VStack(spacing: MassMatesSpacing.md) {
            ForEach(steps) { item in
                stepRow(item: item, step: matchingStep(for: item))
                if item.id != steps.last?.id {
                    Rectangle().fill(MassMatesPalette.line).frame(height: 1).padding(.leading, 32)
                }
            }
        }
    }

    private func stepRow(item: StepItem, step: LectioDivinaStep?) -> some View {
        let isExpanded = step.map { viewModel.isStepExpanded($0) } ?? false
        return Button {
            if let step {
                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.selectLectioStep(step)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                stepHeader(item: item)
                if isExpanded, let step {
                    stepGuidanceCard(for: step)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func stepHeader(item: StepItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MassMatesSpacing.xs) {
            Text("\(item.number)").font(MassMatesFont.callout).fontWeight(.medium).foregroundStyle(theme.tint).frame(width: 20, alignment: .leading)
            Text(item.stage).font(MassMatesFont.scriptureEmphasis).foregroundStyle(MassMatesPalette.textPrimary)
            Text("—").font(MassMatesFont.scripture).foregroundStyle(MassMatesPalette.textTertiary)
            Text(item.prompt).font(MassMatesFont.scripture).foregroundStyle(MassMatesPalette.textPrimary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stepGuidanceCard(for step: LectioDivinaStep) -> some View {
        Text(step.guidance)
            .font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary).lineSpacing(3)
            .padding(MassMatesSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
            .background(MassMatesPalette.surface).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            .overlay { RoundedRectangle(cornerRadius: MassMatesRadius.photo).stroke(MassMatesPalette.line, lineWidth: 1) }
            .padding(.leading, 32)
    }

    private var bottomActionBar: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: viewModel.hasCompletedFruitRegistration ? "Fruto Registrado!" : "Concluir & Registrar Fruto",
                systemImage: viewModel.hasCompletedFruitRegistration ? "checkmark" : "checkmark.circle"
            ) { handleComplete() }
            Text("Registra a leitura na Regra de Vida").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private func matchingStep(for item: StepItem) -> LectioDivinaStep? {
        viewModel.reading.lectioSteps.first { $0.id == item.id }
            ?? (item.number <= viewModel.reading.lectioSteps.count ? viewModel.reading.lectioSteps[item.number - 1] : nil)
    }

    private func handleDismiss() {
        if let onDismiss { onDismiss() } else { navigator?.dismiss() }
    }

    private func handleComplete() {
        viewModel.completeAndReflect()
        navigator?.present(.newCheckIn(preselectedPractice: .dailyGospel, season: theme.season))
    }
}

#Preview("Lectio Divina — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        LectioDivinaAccordionSectionView(
            viewModel: DailyGospelViewModel(reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime))
        )
    }
}
