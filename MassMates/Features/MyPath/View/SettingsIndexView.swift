import Navigation
import SwiftUI

struct SettingsIndexView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @State private var showingDeleteAlert: Bool = false
    private let viewModel: SettingsViewModel
    private let onNavigate: (SettingsScreen) -> Void
    private let onDismiss: () -> Void

    // MARK: - Init
    init(
        viewModel: SettingsViewModel,
        onNavigate: @escaping (SettingsScreen) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigate = onNavigate
        self.onDismiss = onDismiss
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topNavigationArea
                hairline
                rowsSection
                bottomActionSection.padding(.top, MassMatesSpacing.xl)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fechar")
                Spacer()
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)

            Text("Ajustes")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesLayout.screenMargin)
                .padding(.top, MassMatesSpacing.xs)
                .padding(.bottom, MassMatesSpacing.md)
        }
    }

    private var rowsSection: some View {
        VStack(spacing: 0) {
            navigationRow(icon: "bell", title: "Lembretes e Horários", subtitle: "Angelus 12h e 18h · Oração diária", dest: .reminders)
            navigationRow(icon: "shield", title: "Privacidade e Criptografia", subtitle: "Face ID · Backup local · Conta", dest: .privacy)
            navigationRow(icon: "paintpalette", title: "Aparência e Liturgia", subtitle: "Cores litúrgicas · Ícone · Idioma", dest: .appearance)
        }
    }

    private func navigationRow(icon: String, title: String, subtitle: String?, dest: SettingsScreen) -> some View {
        VStack(spacing: 0) {
            Button { onNavigate(dest) } label: {
                HStack(spacing: MassMatesSpacing.md) {
                    Image(systemName: icon)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                        if let subtitle {
                            Text(subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                        }
                    }
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

    private var bottomActionSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("MassMates 1.0").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Button { showingDeleteAlert = true } label: {
                Text(deleteTitle).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.danger)
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
                Text("Esta ação apagará permanentemente sua conta e todos os dados locais. Não pode ser desfeita.")
            }
            if viewModel.accountDeletionState == .awaitingSecondTapConfirmation {
                Text("Toque novamente para confirmar. Não pode ser desfeito.")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
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

    private func handleDismiss() {
        onDismiss()
    }

    private var hairline: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }
}

#Preview("Settings Index — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsIndexView(viewModel: SettingsViewModel(), onNavigate: { _ in }, onDismiss: {})
    }
}
