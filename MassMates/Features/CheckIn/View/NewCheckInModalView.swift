import Navigation
import SwiftUI

enum CheckInWizardStep: Equatable { case practice, fruitAndDestination }

struct NewCheckInModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: NewCheckInViewModel
    @State private var currentStep: CheckInWizardStep = .practice
    private let activeStreakDays: Int

    // MARK: - Init
    init(viewModel: NewCheckInViewModel, activeStreakDays: Int = 14) {
        self.viewModel = viewModel
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(MassMatesPalette.line).frame(width: 36, height: 4).padding(.vertical, 8)
            if let result = viewModel.submissionResult {
                CheckInCelebrationCardView(result: result, activeStreakDays: activeStreakDays) { navigator?.dismiss() }
            } else if currentStep == .practice {
                practiceStep
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            } else {
                fruitAndDestinationStep
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            }
        }
        .animation(reduceMotion ? .none : .snappy(duration: 0.28), value: currentStep)
        .sensoryFeedback(.selection, trigger: viewModel.selectedPractice)
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.bottom, MassMatesSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .task { await viewModel.load() }
    }

    // MARK: - Subviews / Private Helpers
    private var practiceStep: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            stepTopBar(stepText: "Passo 1 de 2", showBack: false)
            titleHeader("O que você rezou?", subtitle: "Selecione o momento com o Senhor para registrar.")
            practiceGrid
            Spacer()
            continueActionSection
        }
    }

    private var fruitAndDestinationStep: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            stepTopBar(stepText: viewModel.selectedPractice.checkInChipTitle.uppercased(), showBack: true)
            titleHeader("Fruto & Destino")
            CheckInSafeguardAndNoteSectionView(viewModel: viewModel, activeStreakDays: activeStreakDays)
            CheckInDestinationCardView(
                isLockedToPrivateDiary: viewModel.isDestinationLockedToPrivateDiary,
                destinationMode: viewModel.destinationMode,
                availableGroups: viewModel.availableGroups,
                selectedGroupIds: viewModel.selectedGroupIds,
                activeStreakDays: activeStreakDays,
                onSelectMode: { viewModel.selectDestinationMode($0) },
                onToggleGroup: { viewModel.toggleGroupSelection($0) }
            )
            Spacer()
            confirmActionSection
        }
    }

    private var practiceGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(SpiritualPractice.allCases) { practiceTile($0) }
        }
    }

    private func practiceTile(_ practice: SpiritualPractice) -> some View {
        let isSelected = viewModel.selectedPractice == practice
        return Button { viewModel.selectPractice(practice) } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: practice.checkInIconName).font(.system(size: 18))
                        .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                        .symbolEffect(.bounce, value: isSelected)
                    Spacer()
                    if isSelected {
                        Circle().fill(theme.tint).frame(width: 8, height: 8)
                    } else if practice == .confession {
                        Text("PRIVADO").font(.system(size: 10, weight: .semibold)).foregroundStyle(MassMatesPalette.textTertiary)
                    }
                }
                Text(practice.checkInChipTitle).font(MassMatesFont.callout.weight(.medium))
                    .foregroundStyle(MassMatesPalette.textPrimary).lineLimit(1)
            }
            .padding(MassMatesSpacing.sm).frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(isSelected ? theme.tintSoft.opacity(0.4) : MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.button)
                .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: isSelected ? 1.5 : 1))
            .scaleEffect(isSelected && !reduceMotion ? 1.02 : 1.0)
            .animation(reduceMotion ? .none : .snappy(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func stepTopBar(stepText: String, showBack: Bool) -> some View {
        HStack {
            if showBack {
                Button {
                    withAnimation(reduceMotion ? .none : .snappy(duration: 0.28)) { currentStep = .practice }
                } label: {
                    Image(systemName: "chevron.left").font(MassMatesFont.caption.weight(.semibold))
                        .foregroundStyle(MassMatesPalette.textSecondary).frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            Text(stepText).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary).tracking(0.6)
            Spacer()
            Button { navigator?.dismiss() } label: {
                Image(systemName: "xmark").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32).background(MassMatesPalette.surfaceMuted).clipShape(.circle)
            }
            .buttonStyle(.plain)
        }
    }

    private func titleHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 24, weight: .semibold, design: .serif)).foregroundStyle(MassMatesPalette.textPrimary)
            if let subtitle { Text(subtitle).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary) }
        }
    }

    private var continueActionSection: some View {
        VStack(spacing: 6) {
            Button {
                withAnimation(reduceMotion ? .none : .snappy(duration: 0.28)) { currentStep = .fruitAndDestination }
            } label: {
                Text("Continuar").font(MassMatesFont.headline).foregroundStyle(theme.onTint)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                    .background(theme.tint).clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
            Text("O registro fortalecerá a sua fidelidade diária.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var confirmActionSection: some View {
        VStack(spacing: 6) {
            if let error = viewModel.errorMessage {
                Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
            }
            Button { Task { await viewModel.submit() } } label: {
                Text("Confirmar Registro").font(MassMatesFont.headline).foregroundStyle(theme.onTint)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                    .background(theme.tint).clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
            Text(viewModel.isDestinationLockedToPrivateDiary
                ? "Destino restrito ao diário pessoal para proteger o sigilo."
                : "Seu registro fortalece a perseverança comunitária.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
    }
}

#Preview("New Check-In Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in NewCheckInModalView(viewModel: NewCheckInViewModel()) }
}
