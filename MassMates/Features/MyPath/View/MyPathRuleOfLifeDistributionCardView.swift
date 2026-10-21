import SwiftUI

struct MyPathRuleOfLifeDistributionCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    Text("Práticas da Regra de Vida")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text("Outubro")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                practiceProgressRow(icon: "circle.grid.cross", title: "Santo Terço", percent: 92)
                practiceProgressRow(icon: "book.closed", title: "Lectio Divina & Evangelho", percent: 88)
                practiceProgressRow(icon: "leaf", title: "Oração Mental (15 min)", percent: 75)
                practiceProgressRow(icon: "moon.stars", title: "Exame de Consciência", percent: 81)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private func practiceProgressRow(icon: String, title: String, percent: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("\(percent)%")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            MassMatesProgressBar(progress: Double(percent) / 100.0)
        }
    }
}

#Preview("Rule of Life Distribution — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathRuleOfLifeDistributionCardView()
            .padding()
    }
}
