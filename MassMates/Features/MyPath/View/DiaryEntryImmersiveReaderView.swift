import SwiftUI

struct DiaryEntryImmersiveReaderView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    private let entry: PrivateDiaryCheckInEntry
    @State private var isAudioPlaying = false
    @State private var toastMessage: String?

    // MARK: - Init
    init(
        entry: PrivateDiaryCheckInEntry = SpiritualDiaryViewModel.defaultSampleEntries()[0]
    ) {
        self.entry = entry
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                topActionHeaderBar
                if let toast = toastMessage { toastBanner(toast) }
                metadataAndPrivacySection
                DiaryEntryIlluminatingWordView()
                intimateDialogueArticle
                DiaryEntryImmersiveFooterView(
                    onShareFruit: { toastMessage = "Resolução enviada para a Fraternidade São José." },
                    onAddToExamen: { toastMessage = "Resolução vinculada ao Exame de Consciência de hoje!" },
                    onAddNote: { toastMessage = "Modo de edição do diário aberto." }
                )
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topActionHeaderBar: some View {
        HStack {
            Label("SIGILO INVIOLÁVEL", systemImage: "lock.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)
            Spacer()
            HStack(spacing: 4) {
                Button {
                    isAudioPlaying.toggle()
                    toastMessage = isAudioPlaying ? "Leitura guiada em voz contemplativa iniciada." : "Áudio pausado."
                } label: {
                    Image(systemName: isAudioPlaying ? "pause.circle.fill" : "speaker.wave.2")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                Button { toastMessage = "Preparando extrato estético em PDF da meditação..." } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                Menu {
                    Button("Editar reflexão") { toastMessage = "Modo de edição aberto." }
                    Button("Vincular virtudes") { toastMessage = "Virtudes vinculadas." }
                    Button("Fixar como graça") { toastMessage = "Entrada fixada como graça no Diário." }
                    Button("Excluir entrada", role: .destructive) { toastMessage = "Ação de exclusão em sigilo." }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: 36, height: 36)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.circle)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toastBanner(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(MassMatesFont.caption)
            .foregroundStyle(theme.tint)
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var metadataAndPrivacySection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack(spacing: MassMatesSpacing.xs) {
                Label("Lectio Divina", systemImage: "book.pages.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, 4)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Text("São Lucas 12, 8–12")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 4)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Label("18 min em oração", systemImage: "clock")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 4)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            Text("Sábado, 12 de Outubro de 2024").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            Text("06:40 • 28ª Semana do Tempo Comum • Memória de Nossa Senhora Aparecida").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Label("Sigilo Pessoal: Criptografado neste aparelho. Ninguém, nem os servidores MassMates, tem acesso às suas confidências com Deus.", systemImage: "checkmark.shield.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(MassMatesSpacing.sm)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        }
    }

    private var intimateDialogueArticle: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: 6) {
                Circle().fill(theme.tint).frame(width: 8, height: 8)
                Text("DIÁLOGO ÍNTIMO & MOVIMENTOS DO CORAÇÃO")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .tracking(0.5)
            }
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                    Text(entry.reflectionOrNotes ?? "No silêncio da manhã, diante da janela entreaberta, senti profunda consolação ao meditar estas palavras. Muitas vezes confundo o testemunho cristão com grandes gestos ou discursos públicos, mas hoje compreendi que o reconhecimento de Cristo se dá nas pequenas fidelidades cotidianas.")
                        .font(MassMatesFont.scripture)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("A providência paternal de Deus se manifestou com clareza. A tentação do medo do futuro e das opiniões alheias se dissipou no momento da contemplação. Se os anjos de Deus contemplam a nossa caminhada, basta-me o olhar do Pai.")
                        .font(MassMatesFont.scripture)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                }
            }
        }
    }
}

#Preview("Immersive Diary Entry Reader — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryImmersiveReaderView()
    }
}
