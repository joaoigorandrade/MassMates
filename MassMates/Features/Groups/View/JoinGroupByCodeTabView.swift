import SwiftUI
import UIKit

struct JoinGroupByCodeTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: CreateJoinGroupViewModel
    @FocusState private var isFieldFocused: Bool
    private let onJoined: () -> Void

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel, onJoined: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onJoined = onJoined
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            headerSection
            digitCellsContainer
            pasteActionButton
            previewOrAffirmationSection
            Spacer(minLength: MassMatesSpacing.xs)
            joinActionButton
        }
        .task { isFieldFocused = true }
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Entrar em um grupo")
                .font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            Text("Digite o código de 6 dígitos compartilhado pelo coordenador")
                .font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var digitCellsContainer: some View {
        ZStack {
            cellsRow
            hiddenTextField
        }
        .contentShape(Rectangle()).onTapGesture { isFieldFocused = true }
    }

    private var cellsRow: some View {
        let chars = pinCharacters
        return HStack(spacing: MassMatesSpacing.xs) {
            ForEach(0..<6, id: \.self) { digitCell(at: $0, char: chars[$0]) }
        }
        .frame(maxWidth: .infinity)
    }

    private func digitCell(at index: Int, char: String) -> some View {
        let isFilled = index < currentCount
        let isActive = index == currentCount
        return VStack(spacing: MassMatesSpacing.xxs) {
            Text(isFilled ? char : " ")
                .font(MassMatesFont.numeral).foregroundStyle(MassMatesPalette.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            RoundedRectangle(cornerRadius: 1)
                .fill(indicatorColor(isFilled: isFilled, isActive: isActive))
                .frame(height: isFilled || isActive ? 2 : 1)
                .padding(.horizontal, 6)
        }
        .frame(width: 48, height: 56)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.photo).strokeBorder(isActive ? theme.tint : MassMatesPalette.line, lineWidth: 1))
    }

    private func indicatorColor(isFilled: Bool, isActive: Bool) -> Color {
        isFilled ? theme.tint : (isActive ? MassMatesPalette.textPrimary : MassMatesPalette.line)
    }

    private var hiddenTextField: some View {
        TextField("", text: $viewModel.inviteCodeInput)
            .focused($isFieldFocused)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled().opacity(0.01)
            .frame(maxWidth: .infinity, minHeight: 56)
            .onChange(of: viewModel.inviteCodeInput) { _, newValue in
                handleCodeChange(newValue)
            }
    }

    private var currentCount: Int {
        viewModel.inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var pinCharacters: [String] {
        let cleaned = viewModel.inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let array = Array(cleaned).map(String.init)
        return (0..<6).map { idx in idx < array.count ? array[idx] : " " }
    }

    private func handleCodeChange(_ value: String) {
        if value.count > 6 { viewModel.inviteCodeInput = String(value.prefix(6)) }
        if InviteCodeParser.normalize(viewModel.inviteCodeInput) != nil {
            Task { await viewModel.previewInviteCode() }
        }
    }

    private var pasteActionButton: some View {
        Button {
            pasteCodeFromClipboard()
        } label: {
            Label("Ou cole o código do convite copiado", systemImage: "link")
                .font(MassMatesFont.callout).foregroundStyle(theme.tint)
        }
        .buttonStyle(.plain).frame(maxWidth: .infinity, alignment: .center)
    }

    private func pasteCodeFromClipboard() {
        let pasted = UIPasteboard.general.string ?? "ST1925"
        viewModel.inviteCodeInput = InviteCodeParser.normalize(pasted) ?? String(pasted.prefix(6)).uppercased()
        Task { await viewModel.previewInviteCode() }
    }

    @ViewBuilder
    private var previewOrAffirmationSection: some View {
        if let group = viewModel.previewedGroup {
            previewGroupRow(group)
        } else {
            affirmationRow
        }
    }

    private func previewGroupRow(_ group: CommunityGroup) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.seal.fill").font(MassMatesFont.title).foregroundStyle(theme.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("\(group.parishOrCommunity) • \(group.memberCount) irmãos")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.photo).strokeBorder(MassMatesPalette.line, lineWidth: 1))
    }

    private var affirmationRow: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "person.3.fill")
                .font(MassMatesFont.callout).foregroundStyle(theme.tint)
                .frame(width: 32, height: 32)
                .background(theme.tintSoft).clipShape(Circle())
            Text("Grupos ajudam a preservar a oração diária e a fidelidade aos hábitos santos.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center).frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity).padding(.vertical, MassMatesSpacing.xs)
    }

    private var joinActionButton: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(title: "Entrar na Fraternidade") {
                if viewModel.inviteCodeInput.isEmpty { viewModel.inviteCodeInput = "ST1925" }
                Task { if await viewModel.confirmJoinGroup() != nil { onJoined() } }
            }
            Text("Ao entrar, você compartilha apenas hábitos de oração ativos e reflexões públicas.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }
}

#Preview("Join Group Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        JoinGroupByCodeTabView(viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925"), onJoined: {})
    }
}
