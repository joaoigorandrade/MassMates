import SwiftUI

struct OnboardingAuthStepView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.md) {
            topNavigationBar
            seasonIndicator
            welcomeEmblemHeader
            socialProvidersSection
            insetEmailDivider
            OnboardingEmailAuthFormView(viewModel: viewModel)
            OnboardingAuthTrustCardsView {
                viewModel.signIn(with: .apple)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button(action: viewModel.navigateBack) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "building.columns.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                Text("MassMates")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Image(systemName: "person.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.onTint)
                .frame(width: 32, height: 32)
                .background(theme.tint)
                .clipShape(Circle())
        }
    }

    private var seasonIndicator: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Circle()
                .fill(theme.tint)
                .frame(width: 6, height: 6)
            Text("TEMPO COMUM • SEMANA V")
                .font(MassMatesFont.caption)
                .tracking(1.0)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var welcomeEmblemHeader: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            emblemCircleBadge
            Text("Bem-vindo ao MassMates")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Text("Acesse sua Regra de Vida, fraternidades e mantenha seu ritmo espiritual diário com serenidade.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var emblemCircleBadge: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(theme.tintSoft)
                    .frame(width: 64, height: 64)
                Circle()
                    .fill(MassMatesPalette.surface)
                    .frame(width: 48, height: 48)
                Image(systemName: "camera.macro")
                    .font(MassMatesFont.title)
                    .foregroundStyle(theme.tint)
            }
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 24, height: 24)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Circle())
        }
    }

    private var socialProvidersSection: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            Button {
                viewModel.signIn(with: .apple)
            } label: {
                Label("Continuar com a Apple", systemImage: "apple.logo")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.bg)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                    .background(MassMatesPalette.textPrimary)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.signIn(with: .google)
            } label: {
                Label("Continuar com o Google", systemImage: "globe")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                    .background(MassMatesPalette.surface)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: MassMatesRadius.button)
                            .stroke(MassMatesPalette.line, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var insetEmailDivider: some View {
        ZStack {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
            Text("OU COM SEU E-MAIL")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .background(MassMatesPalette.bg)
        }
    }
}

#Preview("Onboarding Auth — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingAuthStepView(viewModel: OnboardingViewModel(initialStep: .authSignIn))
    }
}
