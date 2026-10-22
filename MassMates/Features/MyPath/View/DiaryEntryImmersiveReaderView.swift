import Navigation
import SwiftUI

struct DiaryEntryImmersiveReaderView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    private let entry: PrivateDiaryCheckInEntry
    private let hasAttachedPhoto: Bool

    // MARK: - Init
    init(
        entry: PrivateDiaryCheckInEntry = SpiritualDiaryViewModel.defaultSampleEntries()[0],
        hasAttachedPhoto: Bool = true
    ) {
        self.entry = entry
        self.hasAttachedPhoto = hasAttachedPhoto
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topNavigationBar
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                    metadataAndTitleSection
                    if hasAttachedPhoto {
                        attachedPhotoProof
                    }
                    DiaryEntryIlluminatingWordView()
                    reflectionArticle
                    DiaryEntryImmersiveFooterView()
                }
                .padding(.horizontal, MassMatesLayout.readingMargin)
                .padding(.top, MassMatesSpacing.md)
                .frame(maxWidth: MassMatesLayout.readingMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden()
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voltar ao diário")

            Spacer()

            ShareLink(
                item: exportEncryptedText,
                subject: Text("Registro Seguro do Diário Espiritual"),
                message: Text("Registro confidencial do Diário Espiritual.")
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Exportar registro criptografado")
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .frame(height: MassMatesLayout.minRowHeight)
        .background(MassMatesPalette.bg)
    }

    private var metadataAndTitleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text(formattedMetadata)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)

            Text(entryTitle)
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    private var attachedPhotoProof: some View {
        ZStack {
            MassMatesPalette.surfaceMuted
            VStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "camera")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                Text("Registro do recolhimento • Canto de oração")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var reflectionArticle: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            ForEach(reflectionParagraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(11)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
    }

    private var formattedMetadata: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d 'de' MMMM"
        let date = formatter.string(from: entry.createdAt)
        return "\(date) · \(entry.practice.title) · Mistérios Dolorosos"
    }

    private var entryTitle: String {
        switch entry.practice {
        case .rosary: "Consolação ao pé da Cruz"
        case .dailyGospel: "Luz no Evangelho do Dia"
        case .mentalPrayer: "Recolhimento e Paz Interior"
        case .confession: "Paz após o Sacramento da Reconciliação"
        default: "Consolação ao pé da Cruz"
        }
    }

    private var reflectionParagraphs: [String] {
        if let notes = entry.reflectionOrNotes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let split = notes.components(separatedBy: "\n\n").filter { !$0.isEmpty }
            return split.isEmpty ? [notes] : split
        }
        return [
            "Ofereci cada mistério pelas intenções e aflições da família do Mateus. Durante a terceira dezena, veio-me ao coração uma viva consciência de que a cruz que carregamos hoje já foi redimida pelo amor de Nosso Senhor.",
            "Senti uma profunda paz ao rezar a Salve Rainha. Compreendi que o recolhimento interior não é ausência de ruídos exteriores, mas a decisão firme de fixar o olhar em Cristo mesmo em meio à tempestade da rotina.",
            "Renovei o propósito de guardar a mansidão nas conversas de trabalho e não alimentar queixas nem desânimos diante das dificuldades que surgirem."
        ]
    }

    private var exportEncryptedText: String {
        """
        [MassMates — Registro Criptografado do Diário]
        Data: \(formattedMetadata)
        Título: \(entryTitle)
        Sigilo: Armazenado exclusivamente neste dispositivo.

        \(reflectionParagraphs.joined(separator: "\n\n"))
        """
    }
}

#Preview("Immersive Diary Entry Reader — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryImmersiveReaderView()
    }
}
