import Navigation
import SwiftUI

struct NewCheckInModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: NewCheckInViewModel
    private let activeStreakDays: Int

    // MARK: - Init
    init(viewModel: NewCheckInViewModel, activeStreakDays: Int = 14) {
        self.viewModel = viewModel
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                topGrabberAndCloseRow
                titleSection
                if let result = viewModel.submissionResult {
                    celebrationView(result)
                } else {
                    formContent
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topGrabberAndCloseRow: some View {
        HStack {
            Color.clear.frame(width: 32, height: 32)
            Spacer()
            Capsule()
                .fill(MassMatesPalette.line)
                .frame(width: 36, height: 5)
            Spacer()
            Button { navigator?.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
        }
    }

    private var titleSection: some View {
        Text("Novo registro")
            .font(.system(size: 26, weight: .semibold, design: .serif))
            .foregroundStyle(MassMatesPalette.textPrimary)
    }

    private func celebrationView(_ result: CheckInSubmissionResult) -> some View {
        CheckInCelebrationCardView(
            result: result,
            activeStreakDays: activeStreakDays
        ) {
            navigator?.dismiss()
        }
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            practiceSelectorSection
            CheckInSafeguardAndNoteSectionView(
                viewModel: viewModel,
                activeStreakDays: activeStreakDays
            )
            CheckInDestinationCardView(
                isLockedToPrivateDiary: viewModel.isDestinationLockedToPrivateDiary,
                destinationMode: viewModel.destinationMode,
                availableGroups: viewModel.availableGroups,
                selectedGroupIds: viewModel.selectedGroupIds,
                activeStreakDays: activeStreakDays,
                onSelectMode: { mode in viewModel.selectDestinationMode(mode) },
                onToggleGroup: { id in viewModel.toggleGroupSelection(id) }
            )
            submitSection
        }
    }

    private var practiceSelectorSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("PRÁTICA")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)

            FlowWrapLayout(horizontalSpacing: MassMatesSpacing.xs, verticalSpacing: MassMatesSpacing.xs) {
                ForEach(SpiritualPractice.allCases) { practice in
                    practiceChip(practice)
                }
            }
        }
    }

    private func practiceChip(_ practice: SpiritualPractice) -> some View {
        let isSelected = viewModel.selectedPractice == practice
        return Button {
            viewModel.selectPractice(practice)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: practice.checkInIconName)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                Text(practice.checkInChipTitle)
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textPrimary)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(height: 36)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                    .stroke(isSelected ? theme.tint : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var submitSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.danger)
            }
            Button {
                viewModel.submit()
            } label: {
                Text("Registrar")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.onTint)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                    .background(theme.tint)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, MassMatesSpacing.xs)
    }
}

#Preview("New Check-In Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NewCheckInModalView(viewModel: NewCheckInViewModel())
    }
}
