import Navigation
import SwiftUI

struct SettingsModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @State private var viewModel: SettingsViewModel

    // MARK: - Init
    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerSection
                statusBanner
                remindersCard
                languageAndIconCard
                privacyAndBackupCard
                accountDeletionCard
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
                Text("Preferências • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Configurações e Lembretes")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            MassMatesTextButton(title: "Fechar") {
                navigator?.dismiss()
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let message = viewModel.statusBannerMessage {
            Text(message)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var remindersCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Lembretes Litúrgicos e do Angelus")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                ForEach(viewModel.reminders) { item in
                    reminderRow(item)
                }
            }
        }
    }

    private func reminderRow(_ item: LiturgicalReminderItem) -> some View {
        Button {
            viewModel.toggleReminder(item.id)
        } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(MassMatesFont.body)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("\(item.timeLabel) • \(item.subtitle)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                Image(systemName: item.isEnabled ? "bell.fill" : "bell.slash")
                    .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.textTertiary)
            }
            .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var languageAndIconCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Idioma (pt-BR / EN) e Ícone do App")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: MassMatesSpacing.xs) {
                    ForEach(AppLanguage.allCases) { language in
                        MassMatesSecondaryButton(title: language.displayName) {
                            viewModel.selectLanguage(language)
                        }
                    }
                }
                Text("Ícone ativo: \(viewModel.activeAppIcon.title) (\(viewModel.activeAppIcon.saintPatronTitle))")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private var privacyAndBackupCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Privacidade, Consentimento e Backup")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                MassMatesSecondaryButton(
                    title: viewModel.isPersonalizedAdConsentEnabled
                        ? "Anúncios Personalizados: Ativados"
                        : "Anúncios Contextuais Silenciosos (Padrão)",
                    systemImage: "hand.raised"
                ) {
                    viewModel.togglePersonalizedAdConsent(!viewModel.isPersonalizedAdConsentEnabled)
                }
                MassMatesSecondaryButton(
                    title: "Exportar Backup Criptografado do Diário",
                    systemImage: "lock.doc"
                ) {
                    viewModel.requestDiaryBackupExport()
                }
            }
        }
    }

    private var accountDeletionCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Exclusão de Conta e Dados Locais")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.danger)
                Text(deletionDescriptionText)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                MassMatesSecondaryButton(title: deletionButtonTitle, systemImage: "trash") {
                    viewModel.tapDeleteAccountStep()
                }
            }
        }
    }

    private var deletionDescriptionText: String {
        switch viewModel.accountDeletionState {
        case .idle: "Exclua permanentemente sua conta e todos os registros privados em 2 toques."
        case .awaitingSecondTapConfirmation: "Toque novamente para confirmar a exclusão definitiva e irreversível."
        case .permanentlyDeleted: "Conta e registros locais excluídos permanentemente."
        }
    }

    private var deletionButtonTitle: String {
        switch viewModel.accountDeletionState {
        case .idle: "1º Toque: Solicitar Exclusão"
        case .awaitingSecondTapConfirmation: "2º Toque: Confirmar Exclusão Definitiva"
        case .permanentlyDeleted: "Dados Excluídos"
        }
    }
}

#Preview("Settings Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsModalView(viewModel: SettingsViewModel())
    }
}
