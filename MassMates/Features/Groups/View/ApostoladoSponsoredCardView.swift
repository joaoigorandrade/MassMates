import SwiftUI

struct ApostoladoSponsoredCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let sponsorName: String
    private let title: String
    private let action: (() -> Void)?

    // MARK: - Init
    init(
        sponsorName: String = "Edições CNBB",
        title: String = "Novena a N. Sra. Aparecida",
        action: (() -> Void)? = nil
    ) {
        self.sponsorName = sponsorName
        self.title = title
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: MassMatesSpacing.sm) {
                iconView
                VStack(alignment: .leading, spacing: 2) {
                    Text("PATROCINADO")
                        .font(MassMatesFont.caption)
                        .tracking(0.6)
                        .foregroundStyle(MassMatesPalette.sponsored)
                    Text(title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .lineLimit(1)
                    Text(sponsorName)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minRowHeight)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.tintSoft)
                .frame(width: 44, height: 44)
            Image(systemName: "church.fill")
                .font(.system(size: 18))
                .foregroundStyle(theme.tint)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.card)
            .stroke(MassMatesPalette.line, lineWidth: 1)
    }
}

#Preview("Apostolado Sponsored Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ApostoladoSponsoredCardView()
            .padding()
    }
}
