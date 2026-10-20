import Navigation
import SwiftUI

struct SpiritualDiaryModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: SpiritualDiaryViewModel

    // MARK: - Init
    init(viewModel: SpiritualDiaryViewModel = SpiritualDiaryViewModel()) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerSection
                localOnlyWarningBanner
                if viewModel.isDiaryUnlocked {
                    unlockedDiaryContent
                } else {
                    lockedBiometricGateCard
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Santuário Privado • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Diário Espiritual")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            MassMatesTextButton(title: "Fechar") {
                navigator?.dismiss()
            }
        }
    }

    private var localOnlyWarningBanner: some View {
        MassMatesCard {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(theme.tint)
                Text("Armazenamento 100% local: suas notas de Confissão e Lectio jamais vão para a nuvem. Exporte um backup criptografado para não perdê-las ao trocar de aparelho.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private var lockedBiometricGateCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                Label("Protegido por Face ID / Touch ID", systemImage: "faceid")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Desbloqueie seu Diário Espiritual para ler suas reflexões e registros de Confissão.")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                MassMatesPrimaryButton(title: "Desbloquear com Biometria", systemImage: "lock.open") {
                    _ = viewModel.unlockWithBiometrics(simulateSuccess: true)
                }
            }
        }
    }

    private var unlockedDiaryContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            searchAndLockControlsCard
            ForEach(viewModel.filteredEntries) { entry in
                diaryEntryCard(entry)
            }
            encryptedBackupCard
        }
    }

    private var searchAndLockControlsCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                TextField("Buscar reflexão, Salmo ou penitência...", text: $viewModel.searchQuery)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                HStack {
                    Text("Bloqueio Biométrico (Face ID)")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    MassMatesTextButton(title: viewModel.isBiometricLockEnabled ? "Trancar Agora" : "Ativar") {
                        if viewModel.isBiometricLockEnabled {
                            viewModel.lockDiaryNow()
                        } else {
                            viewModel.toggleBiometricLock(true)
                        }
                    }
                }
            }
        }
    }

    private func diaryEntryCard(_ entry: PrivateDiaryCheckInEntry) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Label(entry.practice.title, systemImage: entry.practice.systemImage)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Spacer()
                    if entry.practice.isStrictlyPrivate {
                        Text("Confissão • Só no Aparelho")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    }
                }
                if let reflection = entry.reflectionOrNotes {
                    Text(reflection)
                        .font(MassMatesFont.scripture)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                }
                if let penance = entry.confessorOrPenanceNotes {
                    Text("Penitência / Orientação: \(penance)")
                        .font(MassMatesFont.scriptureEmphasis)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    private var encryptedBackupCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Backup Local Criptografado (AES-GCM)")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                SecureField("Frase-senha (mín. 8 caracteres)", text: $viewModel.backupPassphrase)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if let error = viewModel.securityErrorMessage {
                    Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
                }
                if let status = viewModel.statusBannerMessage {
                    Text(status).font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                MassMatesSecondaryButton(title: "Exportar Backup Criptografado", systemImage: "square.and.arrow.up") {
                    _ = viewModel.exportEncryptedBackup()
                }
            }
        }
    }
}

#Preview("Spiritual Diary Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryModalView(viewModel: SpiritualDiaryViewModel())
    }
}
