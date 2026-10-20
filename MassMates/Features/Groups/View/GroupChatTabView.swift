import SwiftUI

struct GroupChatTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let pinnedNotice: GroupPinnedNotice
    private let messages: [GroupChatMessage]
    @Binding private var isEditingNotice: Bool
    @Binding private var noticeDraft: String
    @Binding private var messageDraft: String
    private let errorMessage: String?
    private let onSaveNotice: () -> Void
    private let onSendMessage: () -> Void

    // MARK: - Init
    init(
        pinnedNotice: GroupPinnedNotice,
        messages: [GroupChatMessage],
        isEditingNotice: Binding<Bool>,
        noticeDraft: Binding<String>,
        messageDraft: Binding<String>,
        errorMessage: String?,
        onSaveNotice: @escaping () -> Void,
        onSendMessage: @escaping () -> Void
    ) {
        self.pinnedNotice = pinnedNotice
        self.messages = messages
        self._isEditingNotice = isEditingNotice
        self._noticeDraft = noticeDraft
        self._messageDraft = messageDraft
        self.errorMessage = errorMessage
        self.onSaveNotice = onSaveNotice
        self.onSendMessage = onSendMessage
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            pinnedNoticeCard
            messagesSection
            composerCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var pinnedNoticeCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Label("Avisos Fixados • \(theme.season.defaultSeasonName)", systemImage: "pin.fill")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Spacer()
                    MassMatesTextButton(title: isEditingNotice ? "Cancelar" : "Editar Aviso") {
                        isEditingNotice.toggle()
                    }
                }
                Text(pinnedNotice.noticeText)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("\(pinnedNotice.leaderName) • \(pinnedNotice.updatedAtLabel)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                if isEditingNotice {
                    leaderNoticeEditor
                }
            }
        }
    }

    private var leaderNoticeEditor: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            TextField("Novo aviso semanal ou horário paroquial", text: $noticeDraft)
                .padding(MassMatesSpacing.sm)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            MassMatesSecondaryButton(title: "Salvar Aviso da Fraternidade", systemImage: "checkmark") {
                onSaveNotice()
            }
        }
    }

    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Chat Fraterno")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(messages) { message in
                messageRow(message)
            }
        }
    }

    private func messageRow(_ message: GroupChatMessage) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack(spacing: MassMatesSpacing.xs) {
                    Text(message.authorInitials)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                        .frame(width: 28, height: 28)
                        .background(theme.tintSoft)
                        .clipShape(Circle())
                    Text(message.authorName)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text(message.relativeTimeLabel)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Text(message.messageText)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
    }

    private var composerCard: some View {
        MassMatesCard {
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
                    onSendMessage()
                }
            }
        }
    }
}

#Preview("Group Chat Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupChatTabView(
            pinnedNotice: CommunitySampleData.initialPinnedNotice(for: "frat-sao-jose"),
            messages: CommunitySampleData.initialChatMessages(for: "frat-sao-jose"),
            isEditingNotice: .constant(false),
            noticeDraft: .constant(""),
            messageDraft: .constant(""),
            errorMessage: nil,
            onSaveNotice: {},
            onSendMessage: {}
        )
    }
}
