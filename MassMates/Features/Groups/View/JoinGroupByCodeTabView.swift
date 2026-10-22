import SwiftUI
import UIKit

struct JoinGroupByCodeTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: CreateJoinGroupViewModel
    private let onJoined: () -> Void

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel, onJoined: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onJoined = onJoined
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            codeHeaderRow
            digitCellsContainer
            if let group = viewModel.previewedGroup {
                previewGroupRow(group)
            }
            qrScannerButton
            joinActionButton
        }
    }

    // MARK: - Subviews / Private Helpers
    private var codeHeaderRow: some View {
        HStack {
            Text("Código da Fraternidade")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button {
                pasteCodeFromClipboard()
            } label: {
                Label("Colar código", systemImage: "doc.on.clipboard")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            .buttonStyle(.plain)
        }
    }

    private var digitCellsContainer: some View {
        ZStack {
            cellsRow
            hiddenTextField
        }
    }

    private var cellsRow: some View {
        let chars = pinCharacters
        return HStack(spacing: MassMatesSpacing.xs) {
            ForEach(0..<6, id: \.self) { index in
                Text(chars[index])
                    .font(MassMatesFont.numeral)
                    .foregroundStyle(index < currentCount ? MassMatesPalette.textPrimary : MassMatesPalette.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            }
        }
    }

    private var hiddenTextField: some View {
        TextField("", text: $viewModel.inviteCodeInput)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .opacity(0.01)
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
        return (0..<6).map { idx in idx < array.count ? array[idx] : "•" }
    }

    private func handleCodeChange(_ value: String) {
        if value.count > 6 {
            viewModel.inviteCodeInput = String(value.prefix(6))
        }
        if InviteCodeParser.normalize(viewModel.inviteCodeInput) != nil {
            viewModel.previewInviteCode()
        }
    }

    private func pasteCodeFromClipboard() {
        let pasted = UIPasteboard.general.string ?? "ST1925"
        viewModel.inviteCodeInput = InviteCodeParser.normalize(pasted) ?? "ST1925"
        viewModel.previewInviteCode()
    }

    private func previewGroupRow(_ group: CommunityGroup) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(MassMatesFont.title)
                .foregroundStyle(theme.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("\(group.parishOrCommunity) • \(group.memberCount) irmãos")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var qrScannerButton: some View {
        Button {
            viewModel.inviteCodeInput = "ST1925"
            viewModel.previewInviteCode()
        } label: {
            Label("Escanear Código QR", systemImage: "qrcode.viewfinder")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var joinActionButton: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(title: "Entrar na Fraternidade") {
                if viewModel.inviteCodeInput.isEmpty { viewModel.inviteCodeInput = "ST1925" }
                if viewModel.confirmJoinGroup() != nil { onJoined() }
            }
            Text("Ao entrar, você compartilha apenas hábitos de oração ativos e reflexões públicas.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, MassMatesSpacing.xs)
    }
}

#Preview("Join Group Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        JoinGroupByCodeTabView(viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925"), onJoined: {})
    }
}
