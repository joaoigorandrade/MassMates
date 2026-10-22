import SwiftUI

struct SettingsIndexView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
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
        VStack(spacing: 0) {
            topNavigationArea
            hairline
            rowsSection
            Spacer(minLength: 0)
            bottomActionSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
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
            navigationRow(icon: "bell", title: "Lembretes litúrgicos", subtitle: "Angelus 12h e 18h", dest: .reminders)
            navigationRow(icon: "paintpalette", title: "Aparência & idioma", subtitle: nil, dest: .appearance)
            navigationRow(icon: "shield", title: "Privacidade & anúncios", subtitle: nil, dest: .privacy)
            navigationRow(icon: "person", title: "Conta", subtitle: nil, dest: .privacy)
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
            }
            .buttonStyle(.plain)
            hairline
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("MassMates 1.0").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Button { viewModel.tapDeleteAccountStep() } label: {
                Text(deleteTitle).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.danger)
                    .frame(height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            if viewModel.accountDeletionState == .awaitingSecondTapConfirmation {
                Text("Toque novamente para confirmar. Não pode ser desfeito.")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
        .padding(.bottom, MassMatesSpacing.lg)
    }

    private var deleteTitle: String {
        switch viewModel.accountDeletionState {
        case .idle: "Excluir conta"
        case .awaitingSecondTapConfirmation: "Confirmar exclusão definitiva"
        case .permanentlyDeleted: "Conta excluída"
        }
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
