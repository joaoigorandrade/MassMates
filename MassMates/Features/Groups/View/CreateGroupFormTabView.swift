import SwiftUI

struct CreateGroupFormTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: CreateJoinGroupViewModel
    private let onCreated: () -> Void

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel, onCreated: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCreated = onCreated
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            headerInputsRow
            CreateGroupRulesAndLimitsView(viewModel: viewModel)
            createActionButton
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerInputsRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            coverImagePickerButton
            nameInputField
        }
    }

    private var coverImagePickerButton: some View {
        Button {
            // Photo picker intent placeholder
        } label: {
            Image(systemName: "camera")
                .font(.system(size: 20))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 56, height: 56)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: MassMatesRadius.button)
                        .strokeBorder(MassMatesPalette.line, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        }
        .buttonStyle(.plain)
    }

    private var nameInputField: some View {
        TextField("Nome da fraternidade ou grupo", text: $viewModel.draft.name)
            .font(MassMatesFont.body)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(height: 56)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var createActionButton: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(title: "Criar grupo") {
                if viewModel.submitCreateGroup() != nil {
                    onCreated()
                }
            }
            Text("Você poderá convidar irmãos logo após a criação.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, MassMatesSpacing.xs)
    }
}

#Preview("Create Group Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateGroupFormTabView(viewModel: CreateJoinGroupViewModel(initialTab: .createNew), onCreated: {})
    }
}
