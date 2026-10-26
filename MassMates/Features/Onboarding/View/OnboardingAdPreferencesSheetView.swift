import Navigation
import SwiftUI

struct OnboardingAdPreferencesSheetView: View {
    // MARK: - Dependencies & State
    @OptionalNavigator<OnboardingRoute> private var navigator
    @Bindable private var viewModel: OnboardingViewModel

    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                Text("Preferências de Anúncios")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                descriptionText
                MassMatesPrimaryButton(title: "Confirmar") {
                    navigator?.dismiss()
                }
                .padding(.top, MassMatesSpacing.lg)
            }
            .padding(MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private var descriptionText: some View {
        Text("O MassMates exibe apenas anúncios discretos e éticos, sem rastreamento de dados de oração ou exame.")
            .font(MassMatesFont.body)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
