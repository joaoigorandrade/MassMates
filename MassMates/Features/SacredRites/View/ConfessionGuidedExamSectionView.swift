import SwiftUI

struct ConfessionGuidedExamSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: ConfessionPrepViewModel

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Text("Exame Guiado de Consciência")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(viewModel.selectionCounterText)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            categoryTabsRow
            ForEach(viewModel.filteredCommandmentGroups) { group in
                commandmentGroupCard(group)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var categoryTabsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(ConfessionExamCategory.allCases) { category in
                    categoryTabButton(category)
                }
            }
        }
    }

    private func categoryTabButton(_ category: ConfessionExamCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectCategory(category)
        } label: {
            Text(category.title)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private func commandmentGroupCard(_ group: CommandmentExamGroup) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Circle().fill(theme.tint).frame(width: 8, height: 8)
                    Text(group.title)
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text(group.badge)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
                Text(group.summary)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                ForEach(group.items) { item in
                    examItemRow(item)
                }
            }
        }
    }

    private func examItemRow(_ item: CommandmentExamItem) -> some View {
        let isChecked = viewModel.isExamItemChecked(item)
        return Button {
            viewModel.toggleExamItem(item)
        } label: {
            HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? theme.tint : MassMatesPalette.textTertiary)
                Text(item.question)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, MassMatesSpacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Confession Guided Exam — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionGuidedExamSectionView(viewModel: ConfessionPrepViewModel())
    }
}
