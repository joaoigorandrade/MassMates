import Navigation
import SwiftUI

enum CheckInWizardStep: Equatable { case practice, fruitAndDestination }

struct NewCheckInModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
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
                CheckInCelebrationCardView(result: result, activeStreakDays: activeStreakDays) { dismissModal() }.equatable()
            } else if currentStep == .practice {
                practiceStep.transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            } else {
                fruitAndDestinationStep.transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                stepTopBar(stepText: "Passo 1 de 2", showBack: false)
                titleHeader("O que você rezou?", subtitle: "Selecione o momento com o Senhor para registrar.")
                practiceGrid
                continueActionSection
                    .padding(.top, MassMatesSpacing.sm)
            }
            .padding(.bottom, MassMatesSpacing.md)
        }
    }

    private var fruitAndDestinationStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
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
                confirmActionSection
                    .padding(.top, MassMatesSpacing.sm)
            }
            .padding(.bottom, MassMatesSpacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var practiceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(SpiritualPractice.allCases, id: \.id) { practice in
                CheckInPracticeTileView(practice: practice, isSelected: viewModel.selectedPractice == practice) {
                    viewModel.selectPractice(practice)
                }.equatable()
            }
        }
    }

    private func stepTopBar(stepText: String, showBack: Bool) -> some View {
        HStack {
            if showBack {
                Button {
                    withAnimation(reduceMotion ? .none : .snappy(duration: 0.28)) { currentStep = .practice }
                } label: {
                    Image(systemName: "chevron.left").font(MassMatesFont.caption.weight(.semibold))
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            Text(stepText).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary).tracking(0.6)
            Spacer()
            Button { dismissModal() } label: {
                Image(systemName: "xmark").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32).background(MassMatesPalette.surfaceMuted).clipShape(.circle)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .trailing)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }

    private func titleHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 24, weight: .semibold, design: .serif)).foregroundStyle(MassMatesPalette.textPrimary)
                .minimumScaleFactor(0.85)
            if let subtitle {
                Text(subtitle).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
            Text("O registro fortalecerá a sua fidelidade diária.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var confirmActionSection: some View {
        VStack(spacing: 6) {
            if let error = viewModel.errorMessage {
                Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            Button { Task { await viewModel.submit() } } label: {
                Text("Confirmar Registro").font(MassMatesFont.headline).foregroundStyle(theme.onTint)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                    .background(theme.tint).clipShape(.rect(cornerRadius: MassMatesRadius.button))
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
            Text(viewModel.isDestinationLockedToPrivateDiary
                ? "Destino restrito ao diário pessoal para proteger o sigilo."
                : "Seu registro fortalece a perseverança comunitária.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func dismissModal() {
        if let navigator { navigator.dismiss() } else { dismiss() }
    }
}

#Preview("New Check-In Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in NewCheckInModalView(viewModel: NewCheckInViewModel()) }
}
