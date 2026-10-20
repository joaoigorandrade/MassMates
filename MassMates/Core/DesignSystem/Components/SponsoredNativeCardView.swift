import SwiftUI

struct SponsoredNativeCardView: View {
    // MARK: - Dependencies & State
    private let sponsorName: String
    private let headline: String
    private let bodyText: String
    private let couponCode: String?

    // MARK: - Init
    init(
        sponsorName: String = "Livraria Católica Vozes da Fé",
        headline: String = "Leituras espirituais para o Tempo Comum",
        bodyText: String = "Obras clássicas dos santos e subsídios litúrgicos selecionados para sua fraternidade.",
        couponCode: String? = "MASSMATES10"
    ) {
        self.sponsorName = sponsorName
        self.headline = headline
        self.bodyText = bodyText
        self.couponCode = couponCode
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            sponsorBadgeRow
            Text(headline)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(bodyText)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let couponCode {
                couponChip(code: couponCode)
            }
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(cardBorder)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patrocinado por \(sponsorName). \(headline). \(bodyText)")
    }

    // MARK: - Subviews / Private Helpers
    private var sponsorBadgeRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("Patrocinado")
                .font(MassMatesFont.caption)
                .tracking(0.48)
                .foregroundStyle(MassMatesPalette.sponsored)
            Text("•")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text(sponsorName)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private func couponChip(code: String) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "bookmark")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("Cupom: \(code)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, MassMatesSpacing.xxs)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.card)
            .stroke(MassMatesPalette.line, lineWidth: 1)
    }
}

#Preview("Sponsored Native Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SponsoredNativeCardView()
    }
}
