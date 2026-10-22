import SwiftUI

struct OnboardingSacredTransparencyCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel
    @State private var showAdPreferences: Bool = false
    private let onBack: (() -> Void)?

    // MARK: - Init
    init(
        viewModel: OnboardingViewModel,
        onBack: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topNavigationBar
            ambientLockIcon
                .padding(.top, MassMatesSpacing.md)
                .padding(.bottom, MassMatesSpacing.sm)
            Text("Sua oração é só sua")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.bottom, MassMatesSpacing.xl)
            bulletPointsSection
            Spacer()
            bottomActionSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAdPreferences) {
            adPreferencesSheet
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button(action: { onBack?() ?? viewModel.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
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

    private var ambientLockIcon: some View {
        Image(systemName: "lock")
            .font(.system(size: 28))
            .foregroundStyle(MassMatesPalette.textPrimary.opacity(0.8))
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
            MassMatesPrimaryButton(title: "Aceitar e começar") {
                viewModel.acknowledgedLocalDiaryWarning = true
                viewModel.completeOnboardingWithConsent(allowPersonalizedAds: false)
            }
            Button {
                showAdPreferences = true
            } label: {
                Text("Preferências de anúncios")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.vertical, MassMatesSpacing.xxs)
            if viewModel.isConsecrationToastVisible {
                consecrationToastBanner
            }
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private var adPreferencesSheet: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Preferências de Anúncios")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("O MassMates exibe apenas anúncios discretos e éticos, sem rastreamento de dados de oração ou exame.")
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            MassMatesPrimaryButton(title: "Confirmar") {
                showAdPreferences = false
            }
        }
        .padding(MassMatesSpacing.lg)
        .background(MassMatesPalette.bg)
    }

    private var consecrationToastBanner: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.success)
            Text("Espaço sagrado pronto com paz.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.bg)
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
