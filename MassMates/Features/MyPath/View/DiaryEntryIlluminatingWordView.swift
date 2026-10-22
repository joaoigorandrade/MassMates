import SwiftUI

struct DiaryEntryIlluminatingWordView: View {
    // MARK: - Dependencies & State
    private let verseText: String
    private let reference: String

    // MARK: - Init
    init(
        verseText: String = "«Todo aquele que me reconhecer diante dos homens, também o Filho do Homem o reconhecerá diante dos anjos de Deus; mas quem me renegar diante dos homens será renegado diante dos anjos de Deus.»",
        reference: String = "São Lucas 12, 8–9"
    ) {
        self.verseText = verseText
        self.reference = reference
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            verseQuote
            referenceLabel
        }
        .padding(.leading, MassMatesSpacing.md)
        .overlay(alignment: .leading) {
            quoteIndicatorLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews / Private Helpers
    private var verseQuote: some View {
        Text(verseText)
            .font(MassMatesFont.scriptureEmphasis)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .lineSpacing(11)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var referenceLabel: some View {
        Text(reference)
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .padding(.top, 2)
    }

    private var quoteIndicatorLine: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(width: 1.5)
    }
}

#Preview("Diary Illuminating Word — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryIlluminatingWordView()
            .padding(MassMatesLayout.readingMargin)
            .background(MassMatesPalette.bg)
    }
}
