import SwiftUI

struct CreateGroupFormTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: CreateJoinGroupViewModel
    private let onAdvance: () -> Void

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel, onAdvance: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onAdvance = onAdvance
    }

    init(viewModel: CreateJoinGroupViewModel, onCreated: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onAdvance = onCreated
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                avatarPickerSection
                nameUnderlineSection
                parishUnderlineSection
                groupTypeSelectorSection
                if viewModel.draft.type == .challenge {
                    CreateGroupChallengeWindowView(viewModel: viewModel)
                }
                advanceButton
                    .padding(.top, MassMatesSpacing.xs)
            }
            .padding(.top, MassMatesSpacing.xs)
            .padding(.bottom, MassMatesSpacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Subviews / Private Helpers
    private var avatarPickerSection: some View {
        HStack {
            Spacer()
            Button {
                // Photo picker intent
            } label: {
                ZStack {
                    Circle()
                        .fill(MassMatesPalette.surfaceMuted)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .strokeBorder(MassMatesPalette.line, lineWidth: 1)
                        )
                    Image(systemName: "camera")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 64, height: 64)
            Spacer()
        }
    }

    private var nameUnderlineSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Nome da fraternidade")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            TextField("ex: Terço dos Homens, São Bento", text: $viewModel.draft.name)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .autocorrectionDisabled()
                .padding(.vertical, MassMatesSpacing.xxs)
            Rectangle()
                .fill(viewModel.draft.name.isEmpty ? MassMatesPalette.line : theme.tint)
                .frame(height: 1)
        }
    }

    private var parishUnderlineSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Paróquia ou comunidade (opcional)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            TextField("ex: Paróquia Nossa Senhora do Carmo", text: $viewModel.draft.parishOrCommunity)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .autocorrectionDisabled()
                .padding(.vertical, MassMatesSpacing.xxs)
            Rectangle()
                .fill(viewModel.draft.parishOrCommunity.isEmpty ? MassMatesPalette.line : theme.tint)
                .frame(height: 1)
        }
    }

    private var groupTypeSelectorSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Tipo de grupo")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            VStack(spacing: MassMatesSpacing.xs) {
                typeRadioRow(
                    type: .fraternity,
                    title: "Fraternidade contínua",
                    subtitle: "Caminhada perene de oração"
                )
                typeRadioRow(
                    type: .challenge,
                    title: "Desafio sazonal",
                    subtitle: "Período com início e término"
                )
            }
        }
    }

    private func typeRadioRow(
        type: CommunityGroupType,
        title: String,
        subtitle: String
    ) -> some View {
        let isSelected = viewModel.draft.type == type
        return Button {
            viewModel.selectType(type)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                radioIndicator(isSelected: isSelected)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(height: 48)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.button)
                    .strokeBorder(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func radioIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if isSelected {
                Circle()
                    .fill(theme.tint)
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var advanceButton: some View {
        let isNameEmpty = viewModel.draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        let isChallengeInvalid = viewModel.draft.type == .challenge && viewModel.draft.challengeWindowErrorMessage != nil
        let isDisabled = isNameEmpty || isChallengeInvalid
        return MassMatesPrimaryButton(title: "Avançar", systemImage: "arrow.right") {
            guard !isDisabled else { return }
            onAdvance()
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

#Preview("Create Group Form Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateGroupFormTabView(viewModel: CreateJoinGroupViewModel(initialTab: .createNew), onCreated: {})
            .padding()
    }
}
