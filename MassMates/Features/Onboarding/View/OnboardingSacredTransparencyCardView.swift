import Navigation
import SwiftUI

struct OnboardingSacredTransparencyCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel
    private let onBack: (() -> Void)?
    private let onShowAdPreferences: (() -> Void)?
    private let onFinish: (() -> Void)?

    // MARK: - Init
    init(
        viewModel: OnboardingViewModel,
        onBack: (() -> Void)? = nil,
        onShowAdPreferences: (() -> Void)? = nil,
        onFinish: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onBack = onBack
        self.onShowAdPreferences = onShowAdPreferences
        self.onFinish = onFinish
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                topNavigationBar
                ambientLockIcon
                    .padding(.top, MassMatesSpacing.md)
                    .padding(.bottom, MassMatesSpacing.sm)
                titleText
                    .padding(.bottom, MassMatesSpacing.lg)
                bulletPointsSection
                bottomActionSection
                    .padding(.top, MassMatesSpacing.xl)
            }
            .padding(.bottom, MassMatesSpacing.sm)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            stepIndicator
        }
        .frame(height: MassMatesLayout.minTapTarget)
    }

    private var stepIndicator: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step == 3 ? theme.tint : MassMatesPalette.line)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            viewModel.navigateBack()
            navigator?.pop()
        }
    }

    private var ambientLockIcon: some View {
        Image(systemName: "lock")
            .font(.system(size: 28))
            .foregroundStyle(MassMatesPalette.textPrimary.opacity(0.8))
    }

    private var titleText: some View {
        Text("Sua oração é só sua")
            .font(.system(size: 32, weight: .regular, design: .serif))
            .foregroundStyle(MassMatesPalette.textPrimary)
            .minimumScaleFactor(0.85)
    }

    private var bulletPointsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            bulletItem(icon: "iphone", text: "Diário e Confissão ficam só no seu iPhone")
            bulletItem(icon: "tag", text: "Anúncios mantêm o app gratuito")
            bulletItem(icon: "eye.slash", text: "Reflexões nunca personalizam anúncios")
        }
    }

    private func bulletItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 24, height: 24)
            Text(text)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            acceptButton
            adPreferencesButton
            if viewModel.isConsecrationToastVisible {
                consecrationToastBanner
            }
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private var acceptButton: some View {
        MassMatesPrimaryButton(title: "Aceitar e começar") {
            viewModel.acknowledgedLocalDiaryWarning = true
            viewModel.completeOnboardingWithConsent(allowPersonalizedAds: false)
            onFinish?()
        }
    }

    private var adPreferencesButton: some View {
        Button {
            if let onShowAdPreferences {
                onShowAdPreferences()
            } else {
                navigator?.present(.adPreferences)
            }
        } label: {
            Text("Preferências de anúncios")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var consecrationToastBanner: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.success)
            Text("Espaço sagrado pronto com paz.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.bg)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.textPrimary)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }
}

#Preview("Onboarding Transparency — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingSacredTransparencyCardView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
