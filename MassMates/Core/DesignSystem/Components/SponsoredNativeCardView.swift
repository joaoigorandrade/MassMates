import SwiftUI

struct SponsoredNativeCardView: View {
    // MARK: - Dependencies & State
    private let sponsorName: String
    private let headline: String
    private let bodyText: String?
    private let couponCode: String?
    private let action: (() -> Void)?

    // MARK: - Init
    init(
        sponsorName: String = "Edições CNBB",
        headline: String = "Edições CNBB — Bíblia Sagrada Edição Pastoral",
        bodyText: String? = nil,
        couponCode: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.sponsorName = sponsorName
        self.headline = headline
        self.bodyText = bodyText
        self.couponCode = couponCode
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patrocinado: \(displayTitle)")
    }

    // MARK: - Subviews / Private Helpers
    private var cardContent: some View {
        HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PATROCINADO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(MassMatesPalette.sponsored)
                Text(displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineLimit(1)
            }
            Spacer(minLength: MassMatesSpacing.xs)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(cardBorder)
    }

    private var displayTitle: String {
        if headline.isEmpty {
            return sponsorName
        }
        if headline.localizedCaseInsensitiveContains(sponsorName) {
            return headline
        }
        return "\(sponsorName) — \(headline)"
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
