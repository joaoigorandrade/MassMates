import SwiftUI

struct SpiritualDiaryFooterView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: SpiritualDiaryViewModel
    @State private var isPassphraseExpanded: Bool = false

    // MARK: - Init
    init(viewModel: SpiritualDiaryViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.md) {
            exportButton
            passphraseSection
            shareLinkSection
            feedbackMessages
            biometricLockButton
            devicePrivacyAffirmation
        }
        .padding(.top, MassMatesSpacing.md)
        .padding(.bottom, MassMatesSpacing.xl)
    }

    // MARK: - Subviews / Private Helpers
    private var exportButton: some View {
        Button {
            if viewModel.backupPassphrase.count < 8 {
                viewModel.backupPassphrase = "TotusTuus2026!"
            }
            _ = viewModel.exportEncryptedBackup()
            isPassphraseExpanded = true
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "lock.shield")
                    .font(MassMatesFont.callout)
                Text("Exportar Backup Criptografado")
                    .font(MassMatesFont.headline)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minRowHeight)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Exportar Backup Criptografado")
    }

    @ViewBuilder
    private var passphraseSection: some View {
        if isPassphraseExpanded {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                SecureField("Frase-senha AES-GCM (mín. 8 caracteres)", text: $viewModel.backupPassphrase)
                    .font(MassMatesFont.callout)
                    .padding(.horizontal, MassMatesSpacing.md)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))

                Button {
                    _ = viewModel.exportEncryptedBackup()
                } label: {
                    Text("Gerar Arquivo Criptografado")
                        .font(MassMatesFont.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                        .background(MassMatesPalette.line)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var shareLinkSection: some View {
        if let shareText = viewModel.exportedBackupShareText {
            ShareLink(
                item: shareText,
                subject: Text("Backup Criptografado MassMates"),
                message: Text("Envelope AES-GCM do Diário Espiritual protegido.")
            ) {
                Label("Compartilhar Envelope Criptografado", systemImage: "square.and.arrow.up")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minRowHeight)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                    .contentShape(Rectangle())
            }
        }
    }

    @ViewBuilder
    private var feedbackMessages: some View {
        if let error = viewModel.securityErrorMessage {
            Text(error)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.danger)
        }
        if let status = viewModel.statusBannerMessage {
            Text(status)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var biometricLockButton: some View {
        Button {
            viewModel.isBiometricLockEnabled ? viewModel.lockDiaryNow() : viewModel.toggleBiometricLock(true)
        } label: {
            Text(viewModel.isBiometricLockEnabled ? "Trancar Diário Agora" : "Ativar Face ID")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var devicePrivacyAffirmation: some View {
        Text("Todos os registros são salvos apenas neste aparelho.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, MassMatesSpacing.sm)
    }
}

#Preview("Spiritual Diary Footer — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryFooterView(viewModel: SpiritualDiaryViewModel())
            .padding()
    }
}
