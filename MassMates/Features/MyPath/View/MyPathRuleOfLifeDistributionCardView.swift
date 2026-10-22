import SwiftUI

struct MyPathRuleOfLifeDistributionCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            headerRow
            contentCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack {
            Text("REGRA DE VIDA")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)
            Spacer()
            Text("Outubro")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.horizontal, 2)
    }

    private var contentCard: some View {
        VStack(spacing: MassMatesSpacing.md) {
            practiceRow(title: "Santo Terço", percent: 92)
            practiceRow(title: "Lectio Divina & Evangelho", percent: 88)
            practiceRow(title: "Oração Mental (15 min)", percent: 75)
            practiceRow(title: "Exame de Consciência", percent: 81)
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private func practiceRow(title: String, percent: Int) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack {
                Text(title)
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
