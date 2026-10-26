import Navigation
import SwiftUI

struct OnboardingCustomizeRuleSheetView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
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
                Text("Práticas Incluídas")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                practiceList
                MassMatesPrimaryButton(title: "Pronto") {
                    navigator?.dismiss()
                }
                .padding(.top, MassMatesSpacing.md)
            }
            .padding(MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private var practiceList: some View {
        ForEach(viewModel.practicePreviewItems) { item in
            practiceRow(item)
        }
    }

    private func practiceRow(_ item: OnboardingPracticePreviewItem) -> some View {
        Button {
            viewModel.togglePracticePreview(id: item.id)
        } label: {
            HStack {
                Image(systemName: item.systemImage)
                    .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.textSecondary)
                Text(item.title)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.line)
            }
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
