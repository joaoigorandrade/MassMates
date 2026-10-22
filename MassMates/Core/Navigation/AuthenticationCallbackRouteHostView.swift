import Navigation
import SwiftUI

/// The destination of `massmates://auth/callback`. It completes the sign-in
/// and lands the user back inside the app — never on a dead route.
struct AuthenticationCallbackRouteHostView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.sharedAuthCallbackHandler) private var handler
    @Environment(\.dismiss) private var dismiss
    @State private var statusText: String = "Retomando sua sessão…"
    @State private var hasFailed = false
    private let payload: AuthCallbackPayload
    private let season: LiturgicalColor

    // MARK: - Init
    nonisolated init(payload: AuthCallbackPayload, season: LiturgicalColor) {
        self.payload = payload
        self.season = season
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            Image(systemName: hasFailed ? "exclamationmark.circle" : "checkmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(hasFailed ? MassMatesPalette.warning : theme.tint)
            Text(statusText)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            if hasFailed {
                MassMatesPrimaryButton(title: "Voltar ao MassMates", systemImage: "arrow.left") {
                    dismiss()
                }
            }
        }
        .padding(MassMatesLayout.screenMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg)
        .task {
            await completeSignIn()
        }
    }

    // MARK: - Subviews / Private Helpers
    private func completeSignIn() async {
        guard let handler else {
            hasFailed = true
            statusText = "Não foi possível concluir o acesso agora. Tente novamente pelo link."
            return
        }
        guard payload.carriesCredentials else {
            hasFailed = true
            statusText = "Este link de acesso não é mais válido. Peça um novo link."
            return
        }
        do {
            let completed = try await handler.completeSignIn(payload: payload)
            guard completed else {
                hasFailed = true
                statusText = "Este link de acesso não é mais válido. Peça um novo link."
                return
            }
            statusText = "Sessão restaurada. Bem-vindo de volta!"
            dismiss()
        } catch {
            hasFailed = true
            statusText = "Não foi possível concluir o acesso agora. Tente novamente pelo link."
        }
    }
}

#Preview("Auth Callback — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        AuthenticationCallbackRouteHostView(
            payload: AuthCallbackPayload(token: "123456", email: "fiel@paroquia.app", type: "email"),
            season: .green
        )
    }
}
