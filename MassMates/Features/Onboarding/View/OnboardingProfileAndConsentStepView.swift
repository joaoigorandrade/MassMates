import SwiftUI

struct OnboardingProfileAndConsentStepView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel
    @State private var wizardStep: Int
    @State private var validationError: String?

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        self._wizardStep = State(
            initialValue: viewModel.currentStep == .privacyAndAdConsent ? 3 : 1
        )
    }

    // MARK: - Body / Public API
    var body: some View {
        Group {
            switch wizardStep {
            case 1:
                nameStepView
            case 2:
                OnboardingRuleAndPrivacyCardsView(
                    viewModel: viewModel,
                    onBack: { withAnimation { wizardStep = 1 } },
                    onNext: {
                        viewModel.acknowledgedLocalDiaryWarning = true
                        withAnimation { wizardStep = 3 }
                    }
                )
            default:
                OnboardingSacredTransparencyCardView(
                    viewModel: viewModel,
                    onBack: { withAnimation { wizardStep = 2 } }
                )
            }
        }
        .animation(.default, value: wizardStep)
        .padding(.horizontal, MassMatesLayout.screenMargin)
    }

    // MARK: - Subviews / Private Helpers
    private var nameStepView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                topNavigationBar
                Text("Como podemos te chamar?")
                    .font(MassMatesFont.displayMobile)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .minimumScaleFactor(0.85)
                    .padding(.top, MassMatesSpacing.md)
                    .padding(.bottom, MassMatesSpacing.lg)
                HStack {
                    Spacer()
                    avatarPickerButton
                    Spacer()
                }
                .padding(.bottom, MassMatesSpacing.lg)
                VStack(spacing: MassMatesSpacing.lg) {
                    inputUnderlineField("Nome", text: $viewModel.userName)
                    inputUnderlineField("Paróquia ou cidade (opcional)", text: $viewModel.parishOrCity)
                }
                errorBanner
                continueButton
                    .padding(.top, MassMatesSpacing.xl)
            }
            .padding(.bottom, MassMatesSpacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var topNavigationBar: some View {
        HStack {
            Button(action: viewModel.navigateBack) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            stepIndicator(active: 1)
        }
        .frame(height: MassMatesLayout.minTapTarget)
    }

    private func stepIndicator(active: Int) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step == active ? theme.tint : MassMatesPalette.line)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var avatarPickerButton: some View {
        Button {
            viewModel.hasSelectedAvatarPhoto.toggle()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(MassMatesPalette.surfaceMuted)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: viewModel.hasSelectedAvatarPhoto ? "person.fill" : "camera.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    )
                    .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
                Circle()
                    .fill(theme.tint)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.onTint)
                    )
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func inputUnderlineField(_ placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: text)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.vertical, MassMatesSpacing.sm)
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = validationError ?? viewModel.errorMessage {
            Text(error)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.danger)
                .padding(.top, MassMatesSpacing.xs)
        }
    }

    private var continueButton: some View {
        MassMatesPrimaryButton(title: "Continuar") {
            let trimmed = viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                validationError = OnboardingValidationError.emptyUserName.userMessage
                return
            }
            validationError = nil
            withAnimation(.easeInOut(duration: 0.25)) {
                wizardStep = 2
            }
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }
}

#Preview("Onboarding Profile & Consent — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingProfileAndConsentStepView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
