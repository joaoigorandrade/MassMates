import Navigation
import SwiftUI

struct NewCheckInModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: NewCheckInViewModel
    private let activeStreakDays: Int

    // MARK: - Init
    init(
        viewModel: NewCheckInViewModel,
        activeStreakDays: Int = 8
    ) {
        self.viewModel = viewModel
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerSection
                if let result = viewModel.submissionResult {
                    CheckInCelebrationCardView(
                        result: result,
                        activeStreakDays: activeStreakDays
                    ) {
                        navigator?.dismiss()
                    }
                } else {
                    practiceSelectorSection
                    reflectionAndWitnessCard
                    CheckInDestinationCardView(
                        isLockedToPrivateDiary: viewModel.isDestinationLockedToPrivateDiary,
                        destinationMode: viewModel.destinationMode,
                        availableGroups: viewModel.availableGroups,
                        selectedGroupIds: viewModel.selectedGroupIds,
                        onSelectMode: { mode in viewModel.selectDestinationMode(mode) },
                        onToggleGroup: { id in viewModel.toggleGroupSelection(id) }
                    )
                    submitSection
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Registrar Oração • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Novo Check-In Espiritual")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            MassMatesTextButton(title: "Fechar") {
                navigator?.dismiss()
            }
        }
    }

    private var practiceSelectorSection: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Escolha a prática")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                ForEach(SpiritualPractice.allCases) { practice in
                    practiceChipRow(practice)
                }
            }
        }
    }

    private func practiceChipRow(_ practice: SpiritualPractice) -> some View {
        let isSelected = viewModel.selectedPractice == practice
        return Button {
            viewModel.selectPractice(practice)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: practice.systemImage)
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(practice.title)
                        .font(MassMatesFont.body)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(practice.subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                if practice.isStrictlyPrivate {
                    Image(systemName: "lock.fill")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                } else {
                    Text("+\(practice.defaultCustomPoints) pts")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                }
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                    .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var reflectionAndWitnessCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text(viewModel.isDestinationLockedToPrivateDiary ? "Notas Privadas da Confissão" : "Fruto da Oração e Testemunho")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                TextField("Fruto da oração ou meditação (opcional)", text: $viewModel.fruitOfPrayer)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if viewModel.isDestinationLockedToPrivateDiary {
                    TextField("Penitência ou orientação do confessor (somente no aparelho)", text: $viewModel.confessorOrPenanceNotes)
                        .padding(MassMatesSpacing.sm)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                } else {
                    TextField("Legenda de foto / testemunho (opcional)", text: $viewModel.photoCaption)
                        .padding(MassMatesSpacing.sm)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                }
            }
        }
    }

    private var submitSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.danger)
            }
            MassMatesPrimaryButton(
                title: "Confirmar Check-In",
                systemImage: "checkmark.circle"
            ) {
                viewModel.submit()
            }
        }
    }
}

#Preview("New Check-In Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NewCheckInModalView(viewModel: NewCheckInViewModel())
    }
}
