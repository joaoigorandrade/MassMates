import SwiftUI

struct GroupChatInputBarView: View {
    // MARK: - Dependencies & State
    @Binding private var messageDraft: String
    private let errorMessage: String?
    private let onSendMessage: () -> Void

    // MARK: - Init
    init(
        messageDraft: Binding<String>,
        errorMessage: String?,
        onSendMessage: @escaping () -> Void
    ) {
        self._messageDraft = messageDraft
        self.errorMessage = errorMessage
        self.onSendMessage = onSendMessage
    }

    // MARK: - Body / Public API
    var body: some View {
        let isDraftEmpty = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                TextField("Escrever mensagem fraterna...", text: $messageDraft)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if let errorMessage {
                    Text(errorMessage)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.danger)
                }
                MassMatesPrimaryButton(title: "Enviar no Chat", systemImage: "paperplane.fill") {
                    guard !isDraftEmpty else { return }
                    onSendMessage()
                }
                .disabled(isDraftEmpty)
                .opacity(isDraftEmpty ? 0.5 : 1.0)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Group Chat Input Bar — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupChatInputBarView(
            messageDraft: .constant(""),
            errorMessage: nil,
            onSendMessage: {}
        )
        .padding()
    }
}
