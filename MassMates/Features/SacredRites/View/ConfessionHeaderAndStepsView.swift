import SwiftUI

struct ConfessionHeaderAndStepsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: ConfessionPrepViewModel
    @Binding private var selectedTab: ConfessionTab

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel, selectedTab: Binding<ConfessionTab> = .constant(.contrition)) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            headerTitleSection
            quietSegmentedTabs
            if selectedTab == .contrition {
                contritionAndStepsContent
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerTitleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Preparação para a Confissão")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .tracking(-0.3)
            Text("Exame de Consciência · Dez Mandamentos")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            lastConfessionIndicator
        }
    }

    private var lastConfessionIndicator: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(systemName: "calendar")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(viewModel.lastConfessionBadgeText)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.top, 2)
    }

    private var quietSegmentedTabs: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            ForEach(Array(ConfessionTab.allCases.enumerated()), id: \.element.id) { index, tab in
                if index > 0 {
                    Text("·")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.line)
                }
                tabButton(tab)
            }
            Spacer()
        }
        .padding(.top, MassMatesSpacing.xs)
    }

    private func tabButton(_ tab: ConfessionTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.snappy(duration: 0.2)) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Text(tab.title)
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                    .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                Capsule()
                    .fill(isSelected ? MassMatesPalette.textPrimary : Color.clear)
                    .frame(height: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var contritionAndStepsContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            holySpiritSection
            fiveStepsSection
        }
    }

    private var holySpiritSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Button {
                viewModel.toggleHolySpiritPrayer()
            } label: {
                HStack {
                    Label("Oração ao Espírito Santo", systemImage: "flame")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Image(systemName: viewModel.isHolySpiritPrayerExpanded ? "chevron.up" : "chevron.down")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .buttonStyle(.plain)
            if viewModel.isHolySpiritPrayerExpanded {
                Text("\"Vinde, Espírito Santo, enchei o meu coração com a Vossa luz. Dai-me a graça de conhecer com sinceridade as minhas fraquezas e pecados, a dor humilde e confiante do arrependimento, e a coragem de me acusar sem escrúpulos ou vergonha no Sacramento da Vossa infinita misericórdia. Por Cristo, Nosso Senhor. Amém.\"")
                    .font(MassMatesFont.customScripture(size: 15, italic: true))
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var fiveStepsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Os 5 Passos para uma Boa Confissão")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            VStack(spacing: 0) {
                ForEach(Array(viewModel.fiveSteps.enumerated()), id: \.element.id) { index, step in
                    if index > 0 { Divider().overlay(MassMatesPalette.line) }
                    stepRow(step)
                }
            }
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
        }
    }

    private func stepRow(_ step: GoodConfessionStep) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Text("\(step.number)")
                .font(MassMatesFont.caption)
                .foregroundStyle(step.isCompleted ? MassMatesPalette.surface : MassMatesPalette.textPrimary)
                .frame(width: 22, height: 22)
                .background(step.isCompleted ? MassMatesPalette.textPrimary : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(MassMatesFont.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(step.description)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
        }
        .padding(MassMatesSpacing.sm)
        .frame(minHeight: MassMatesLayout.minRowHeight)
    }
}

#Preview("Confession Header & Steps — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionHeaderAndStepsView(
            viewModel: ConfessionPrepViewModel(),
            selectedTab: .constant(.commandments)
        )
    }
}
