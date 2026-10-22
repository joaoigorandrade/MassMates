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
                remindersSection
                preferencesSection
                privacyAndBackupSection
                accountDeletionSection
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Configurações").font(MassMatesFont.title).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Preferências • \(theme.season.defaultSeasonName)").font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
            Spacer()
            Button("Fechar") { navigator?.dismiss() }.font(MassMatesFont.body).foregroundStyle(theme.tint)
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let message = viewModel.statusBannerMessage {
            Text(message).font(MassMatesFont.caption).foregroundStyle(theme.tint).padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading).background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("LEMBRETES LITÚRGICOS")
            hairline
            ForEach(viewModel.reminders) { item in
                HStack(spacing: MassMatesSpacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                        Text("\(item.timeLabel) • \(item.subtitle)").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(get: { item.isEnabled }, set: { _ in viewModel.toggleReminder(item.id) }))
                        .labelsHidden().tint(theme.tint)
                }
                .frame(minHeight: MassMatesLayout.minRowHeight)
                hairline
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("IDIOMA & ÍCONE")
            hairline
            HStack {
                Text("Idioma do Aplicativo").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                HStack(spacing: MassMatesSpacing.xs) {
                    ForEach(AppLanguage.allCases) { lang in
                        let isSelected = viewModel.selectedLanguage == lang
                        Button(lang.displayName) { viewModel.selectLanguage(lang) }
                            .font(MassMatesFont.caption)
                            .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textSecondary)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                    }
                }
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            hairline
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ícone do Aplicativo").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                    Text(viewModel.activeAppIcon.title).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                Image(systemName: viewModel.activeAppIcon.systemImage).font(MassMatesFont.headline).foregroundStyle(theme.tint)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            hairline
        }
    }

    private var privacyAndBackupSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("PRIVACIDADE & BACKUP")
            hairline
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anúncios Personalizados").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Silenciosos e contextuais por padrão").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { viewModel.isPersonalizedAdConsentEnabled }, set: { viewModel.togglePersonalizedAdConsent($0) }))
                    .labelsHidden().tint(theme.tint)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            hairline
            Button { viewModel.requestDiaryBackupExport() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exportar Backup Criptografado").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                        Text("Diário salvo com AES-GCM").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                .frame(minHeight: MassMatesLayout.minRowHeight)
            }
            .buttonStyle(.plain)
            hairline
        }
    }

    private var accountDeletionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("CONTA")
            hairline
            Button { viewModel.tapDeleteAccountStep() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.accountDeletionState.buttonTitle).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.danger)
                        Text(viewModel.accountDeletionState.descriptionText).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "trash").font(MassMatesFont.body).foregroundStyle(MassMatesPalette.danger)
                }
                .frame(minHeight: MassMatesLayout.minRowHeight)
            }
            .buttonStyle(.plain)
            hairline
        }
    }

    private var hairline: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(MassMatesFont.caption).tracking(0.8).foregroundStyle(MassMatesPalette.textSecondary).padding(.bottom, MassMatesSpacing.xs)
    }
}

#Preview("Settings Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsModalView(viewModel: SettingsViewModel())
    }
}
