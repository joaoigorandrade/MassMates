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
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeaderRow
            categoryFilterTabs
            commandmentsList
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeaderRow: some View {
        HStack {
            Text("Exame dos Dez Mandamentos")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Text(viewModel.selectionCounterText)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, 2)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private var categoryFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(ConfessionExamCategory.allCases) { category in
                    categoryFilterChip(category)
                }
            }
        }
    }

    private func categoryFilterChip(_ category: ConfessionExamCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                viewModel.selectCategory(category)
            }
        } label: {
            Text(category.title)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? MassMatesPalette.surface : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var commandmentsList: some View {
        VStack(spacing: MassMatesSpacing.md) {
            ForEach(viewModel.filteredCommandmentGroups) { group in
                commandmentGroupSection(group)
            }
        }
    }

    private func commandmentGroupSection(_ group: CommandmentExamGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader(group)
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
            ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(MassMatesPalette.line)
                        .frame(height: 1)
                }
                checklistRow(item)
            }
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    private func groupHeader(_ group: CommandmentExamGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(group.title)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(group.badge)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            Text(group.summary)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.vertical, MassMatesSpacing.xs)
    }

    private func checklistRow(_ item: CommandmentExamItem) -> some View {
        let isChecked = viewModel.isExamItemChecked(item)
        return Button {
            withAnimation(.snappy(duration: 0.15)) {
                viewModel.toggleExamItem(item)
            }
        } label: {
            HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
                Text(item.question)
                    .font(MassMatesFont.customScripture(size: 16))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                circularCheckmark(isChecked: isChecked)
            }
            .padding(.vertical, MassMatesSpacing.sm)
            .padding(.horizontal, MassMatesSpacing.xxs)
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .background(isChecked ? MassMatesPalette.surfaceMuted.opacity(0.6) : Color.clear)
            .clipShape(.rect(cornerRadius: MassMatesSpacing.xxs))
        }
        .buttonStyle(.plain)
    }

    private func circularCheckmark(isChecked: Bool) -> some View {
        ZStack {
            if isChecked {
                Circle()
                    .fill(MassMatesPalette.textPrimary)
                    .frame(width: 20, height: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MassMatesPalette.surface)
            } else {
                Circle()
                    .stroke(MassMatesPalette.line, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(width: 24, height: 24)
    }
}

#Preview("Confession Guided Exam — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionGuidedExamSectionView(viewModel: ConfessionPrepViewModel())
    }
}
