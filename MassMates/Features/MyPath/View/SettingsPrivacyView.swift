import Navigation
import SwiftUI

struct SettingsPrivacyView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator
    @State private var showingDeleteAlert: Bool = false
    private let viewModel: SettingsViewModel
    private let onBack: () -> Void

    // MARK: - Init
    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topNavigationArea
                hairline
                rowsSection
                bottomDestructiveSection.padding(.top, MassMatesSpacing.xl)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: handleBack) {
                    HStack(spacing: MassMatesSpacing.xxs) {
                        Image(systemName: "chevron.left").font(MassMatesFont.headline)
                        Text("Ajustes").font(MassMatesFont.callout)
                    }
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(minHeight: MassMatesLayout.minTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voltar")
                Spacer()
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)

            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Privacidade e Criptografia")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Sua oração e seus dados pertencem a você.")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.top, MassMatesSpacing.xs)
            .padding(.bottom, MassMatesSpacing.md)
        }
    }

    private var rowsSection: some View {
        VStack(spacing: 0) {
            toggleRow(title: "Anúncios personalizados", isOn: Binding(
                get: { viewModel.isPersonalizedAdConsentEnabled },
                set: { viewModel.togglePersonalizedAdConsent($0) }
            ))
            toggleRow(title: "Bloquear diário com Face ID", isOn: Binding(
                get: { viewModel.isBiometricLockEnabled },
                set: { viewModel.toggleBiometricLock($0) }
            ))
            actionRow(title: "Exportar backup criptografado") {
                viewModel.requestDiaryBackupExport()
            }
            actionRow(title: "Sair da conta") {
                viewModel.signOut()
            }
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Toggle("", isOn: isOn).labelsHidden().tint(theme.tint)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .contentShape(Rectangle())
            hairline
        }
    }

    private func actionRow(title: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    Text(title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                }
                .frame(minHeight: MassMatesLayout.minRowHeight)
                .padding(.horizontal, MassMatesLayout.screenMargin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            hairline
        }
    }

    private var bottomDestructiveSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            if let banner = viewModel.statusBannerMessage {
                Text(banner)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.md)
                    .padding(.bottom, MassMatesSpacing.xs)
            }
            Button { showingDeleteAlert = true } label: {
                Text(deleteTitle)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.danger)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Apagar minha conta")
            .alert("Apagar Minha Conta", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { viewModel.cancelAccountDeletion() }
                Button("Confirmar Exclusão", role: .destructive) {
                    viewModel.tapDeleteAccountStep()
                    if viewModel.accountDeletionState == .awaitingSecondTapConfirmation {
                        viewModel.tapDeleteAccountStep()
                    }
                }
            } message: {
                Text("Esta ação é definitiva e apagará todos os seus registros locais e conta.")
            }
            Text("Dois toques. Não pode ser desfeito.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .padding(.bottom, MassMatesSpacing.lg)
    }

    private var deleteTitle: String {
        switch viewModel.accountDeletionState {
        case .idle: "Apagar minha conta"
        case .awaitingSecondTapConfirmation: "Confirmar exclusão definitiva"
        case .permanentlyDeleted: "Conta excluída"
        }
    }

    private func handleBack() {
        onBack()
        if let navigator, navigator.canPop() {
            navigator.pop()
        }
    }

    private var hairline: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }
}

#Preview("Settings Privacy — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsPrivacyView(viewModel: SettingsViewModel(), onBack: {})
    }
}
