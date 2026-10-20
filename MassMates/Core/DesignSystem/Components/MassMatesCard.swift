import SwiftUI

struct MassMatesCard<Content: View>: View {
    // MARK: - Dependencies & State
    private let content: Content

    // MARK: - Init
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: - Body / Public API
    var body: some View {
        content
            .padding(MassMatesSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(cardBorder)
    }

    // MARK: - Subviews / Private Helpers
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.card)
            .stroke(MassMatesPalette.line, lineWidth: 1)
    }
}

#Preview("Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        MassMatesCard {
            Text(season.defaultSeasonName)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}
