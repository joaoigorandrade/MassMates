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
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            fraternalInviteBanner
            codeInputCard
            joinActionSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var fraternalInviteBanner: some View {
        MassMatesCard {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "hands.and.sparkles.fill")
                    .font(MassMatesFont.title).foregroundStyle(theme.tint)
                    .frame(width: 56, height: 56).background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                VStack(alignment: .leading, spacing: 2) {
                    Text("CONVITE FRATERNO").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                    Text("Insira a chave recebida de um irmão").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Grupos são espaços de silêncio e suporte mútuo.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    private var codeInputCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                codeCardHeader
                segmentedPinBoxes
                hiddenCodeField
                liveValidationBadge
                cameraDividerRow
                qrScannerButton
            }
        }
    }

    private var codeCardHeader: some View {
        HStack {
            Text("Código da Fraternidade")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button {
                let pasted = UIPasteboard.general.string ?? "ST1925"
                viewModel.inviteCodeInput = InviteCodeParser.normalize(pasted) ?? "ST1925"
                viewModel.previewInviteCode()
            } label: {
                Label("Colar código", systemImage: "doc.on.clipboard")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            .buttonStyle(.plain)
        }
    }

    private var segmentedPinBoxes: some View {
        let chars = pinCharacters
        return HStack(spacing: MassMatesSpacing.xs) {
            ForEach(0..<6, id: \.self) { index in
                Text(chars[index])
                    .font(MassMatesFont.numeral)
                    .foregroundStyle(index == 5 ? theme.tint : MassMatesPalette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesSpacing.xs))
            }
        }
    }

    private var pinCharacters: [String] {
        let cleaned = InviteCodeParser.normalize(viewModel.inviteCodeInput)
            ?? viewModel.inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let source = cleaned.isEmpty ? "FRAT78" : cleaned
        let array = Array(source).map(String.init)
        return (0..<6).map { idx in idx < array.count ? array[idx] : "•" }
    }

    private var hiddenCodeField: some View {
        TextField("Código de 6 dígitos (ex: ST1925)", text: $viewModel.inviteCodeInput)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .font(MassMatesFont.caption)
            .padding(MassMatesSpacing.xs)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesSpacing.xs))
            .onChange(of: viewModel.inviteCodeInput) { _, _ in
                if InviteCodeParser.normalize(viewModel.inviteCodeInput) != nil {
                    viewModel.previewInviteCode()
                }
            }
    }

    private var liveValidationBadge: some View {
        let title = viewModel.previewedGroup?.name ?? "Fraternidade São Gabriel"
        let subtitle = viewModel.previewedGroup.map { "\($0.parishOrCommunity) • \($0.memberCount) irmãos ativos" }
            ?? "Paróquia N. Sra. das Graças • 14 irmãos ativos"
        return HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
            Image(systemName: "checkmark.seal.fill").font(MassMatesFont.headline).foregroundStyle(theme.tint)
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text(subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                HStack(spacing: MassMatesSpacing.xs) {
                    Label("Santo Anjo da Guarda", systemImage: "rosette")
                        .font(MassMatesFont.caption).foregroundStyle(theme.tint)
                        .padding(.horizontal, MassMatesSpacing.xs).padding(.vertical, 2)
                        .background(theme.tintSoft).clipShape(Capsule())
                    Text("Terço Diário")
                        .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                        .padding(.horizontal, MassMatesSpacing.xs).padding(.vertical, 2)
                        .background(MassMatesPalette.surface).clipShape(Capsule())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var cameraDividerRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            Text("OU USE CÂMERA").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
    }

    private var qrScannerButton: some View {
        Button {
            viewModel.inviteCodeInput = "ST1925"
            viewModel.previewInviteCode()
        } label: {
            Label("Escanear Código QR do Grupo", systemImage: "qrcode.viewfinder")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        }
        .buttonStyle(.plain)
    }

    private var joinActionSection: some View {
        let groupTitle = viewModel.previewedGroup?.name ?? "Fraternidade São Gabriel"
        return VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(title: "Entrar na \(groupTitle)", systemImage: "person.badge.plus") {
                if viewModel.inviteCodeInput.isEmpty { viewModel.inviteCodeInput = "ST1925" }
                if viewModel.confirmJoinGroup() != nil { onJoined() }
            }
            Text("Ao entrar, você compartilha apenas hábitos de oração ativos e reflexões públicas.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Join Group Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        JoinGroupByCodeTabView(viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925"), onJoined: {})
    }
}
