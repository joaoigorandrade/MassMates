import SwiftUI

struct ApostoladoSponsoredCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            headerRow
            contentRow
            footerRow
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack {
            Text("PATROCINADO • APOSTOLADO")
                .font(MassMatesFont.caption)
                .tracking(0.8)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Spacer()
            Image(systemName: "info.circle")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var contentRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "book.closed.fill")
                .font(MassMatesFont.title)
                .foregroundStyle(Theme(season: .white).tint)
                .frame(width: 48, height: 56)
                .background(Theme(season: .white).tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesSpacing.xs))
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Livraria Loyola — Espiritualidade & Liturgia")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Edições comentadas da Liturgia das Horas e clássicos da oração inaciana com desconto pastoral.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .lineLimit(2)
            }
        }
    }

    private var footerRow: some View {
        HStack {
            Spacer()
            HStack(spacing: MassMatesSpacing.xxs) {
                Text("Acessar Acervo Sagrado")
                Image(systemName: "arrow.up.right.square")
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(theme.tint)
        }
    }
}

#Preview("Apostolado Sponsored Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ApostoladoSponsoredCardView()
            .padding()
    }
}
