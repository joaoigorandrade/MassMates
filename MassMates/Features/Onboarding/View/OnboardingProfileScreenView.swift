import Navigation
import SwiftUI

struct OnboardingProfileScreenView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel
    @State private var validationError: String?

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                topNavigationBar
                titleSection
                    .padding(.top, MassMatesSpacing.md)
                    .padding(.bottom, MassMatesSpacing.lg)
                avatarSection
                    .padding(.bottom, MassMatesSpacing.lg)
                formSection
                errorBanner
                continueButton
                    .padding(.top, MassMatesSpacing.xl)
            }
            .padding(.bottom, MassMatesSpacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button {
                viewModel.navigateBack()
                navigator?.pop()
            } label: {
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

    private var titleSection: some View {
        Text("Como podemos te chamar?")
            .font(MassMatesFont.displayMobile)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .minimumScaleFactor(0.85)
    }

    private var avatarSection: some View {
        HStack {
            Spacer()
            avatarPickerButton
            Spacer()
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

    private var formSection: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            inputUnderlineField("Nome", text: $viewModel.userName)
            inputUnderlineField("Paróquia ou cidade (opcional)", text: $viewModel.parishOrCity)
        }
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
            navigator?.navigate(to: .rule)
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }
}
