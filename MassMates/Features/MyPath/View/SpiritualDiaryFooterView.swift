import SwiftUI

struct SpiritualDiaryFooterView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: SpiritualDiaryViewModel

    // MARK: - Init
    init(viewModel: SpiritualDiaryViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            preservationCard
            quoteFooter
        }
    }

    // MARK: - Subviews / Private Helpers
    private var preservationCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Label("Preservação & Cópia Segura", systemImage: "arrow.down.doc.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                SecureField("Frase-senha AES-GCM (mín. 8 caracteres)", text: $viewModel.backupPassphrase)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if let error = viewModel.securityErrorMessage {
                    Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
                }
                if let status = viewModel.statusBannerMessage {
                    Text(status).font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                MassMatesSecondaryButton(title: "Exportar Diário Criptografado (PDF / Markdown)", systemImage: "doc.text.fill") {
                    _ = viewModel.exportEncryptedBackup()
                }
                if let shareText = viewModel.exportedBackupShareText {
                    ShareLink(
                        item: shareText,
                        subject: Text("Backup Criptografado MassMates"),
                        message: Text("Envelope AES-GCM do Diário Espiritual protegido.")
                    ) {
                        Label("Compartilhar Envelope Criptografado", systemImage: "square.and.arrow.up")
                            .font(MassMatesFont.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(theme.tintSoft)
                            .foregroundStyle(theme.tint)
                            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                    }
                }
                MassMatesTextButton(title: viewModel.isBiometricLockEnabled ? "Trancar Agora (Face ID)" : "Ativar Face ID") {
                    viewModel.isBiometricLockEnabled ? viewModel.lockDiaryNow() : viewModel.toggleBiometricLock(true)
                }
            }
        }
    }

    private var quoteFooter: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("“Guarda a memória das graças que o Senhor te fez; elas serão o teu escudo nos dias de aridez.”")
                .font(MassMatesFont.customScripture(size: 16, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
            Text("— SÃO FRANCISCO DE SALES")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Spiritual Diary Footer — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryFooterView(viewModel: SpiritualDiaryViewModel())
            .padding()
    }
}
