import SwiftUI

struct SponsoredBannerView: View, Equatable {
    private let sponsorTitle: String
    private let message: String

    init(
        sponsorTitle: String = "Edições CNBB",
        message: String = "Liturgia Diária e subsídios para a oração em família."
    ) {
        self.sponsorTitle = sponsorTitle
        self.message = message
    }

    nonisolated static func == (lhs: SponsoredBannerView, rhs: SponsoredBannerView) -> Bool {
        lhs.sponsorTitle == rhs.sponsorTitle &&
        lhs.message == rhs.message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            headerRow
            Text(message)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(nil)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.vertical, MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patrocinado: \(sponsorTitle). \(message)")
    }

    private var headerRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("Patrocinado")
                .font(MassMatesFont.caption)
                .tracking(0.48)
                .foregroundStyle(MassMatesPalette.sponsored)
            Text("•")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text(sponsorTitle)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}

#Preview("Sponsored Banner — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SponsoredBannerView()
    }
}
