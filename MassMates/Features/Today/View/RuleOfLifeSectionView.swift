import Navigation
import SwiftUI

struct RuleOfLifeSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @State private var items: [DailyRuleChecklistItem]
    private let onEditRule: (() -> Void)?
    private let onTogglePractice: ((SpiritualPractice) -> Void)?

    // MARK: - Init
    init(
        items: [DailyRuleChecklistItem] = DailyRuleChecklistItem.stitchDefaultItems,
        onEditRule: (() -> Void)? = nil,
        onTogglePractice: ((SpiritualPractice) -> Void)? = nil
    ) {
        _items = State(initialValue: items)
        self.onEditRule = onEditRule
        self.onTogglePractice = onTogglePractice
    }

    init(
        progress: TodayProgressSummary,
        onSelectPreset: @escaping (RuleOfLifePreset) -> Void = { _ in },
        onTogglePractice: @escaping (SpiritualPractice) -> Void = { _ in },
        onEditRule: (() -> Void)? = nil
    ) {
        self.init(
            items: DailyRuleChecklistItem.from(summary: progress),
            onEditRule: onEditRule ?? { onSelectPreset(progress.selectedPreset) },
            onTogglePractice: onTogglePractice
        )
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            mainContentArea
            Spacer(minLength: MassMatesSpacing.sm)
            bottomActionArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: completedCount)
    }

    // MARK: - Subviews / Private Helpers
    private var navigationBar: some View {
        HStack {
            Button {
                if let navigator, navigator.canPop() { navigator.pop() } else { dismiss() }
            } label: {
                Image(systemName: "chevron.left").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
            }
            .buttonStyle(.plain).accessibilityLabel("Voltar")
            Spacer()
            Text("Regra de Vida").font(.system(size: 20, weight: .semibold, design: .serif)).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Color.clear.frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }
        .padding(.horizontal, MassMatesSpacing.md).frame(height: 56)
    }

    private var mainContentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FIDELIDADE DIÁRIA").font(.system(size: 12, weight: .medium)).tracking(0.8)
                .foregroundStyle(MassMatesPalette.textSecondary).padding(.bottom, MassMatesSpacing.md)
            progressSection
            checklistRows
            spiritualQuote
        }
        .padding(.horizontal, MassMatesLayout.readingMargin).padding(.top, MassMatesSpacing.sm)
    }

    private var progressSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack {
                Text("Progresso de hoje").font(.system(size: 14)).foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("\(completedCount) de \(items.count)").font(.system(size: 14, weight: .medium)).foregroundStyle(theme.tint)
            }
            MassMatesProgressBar(progress: progressRatio)
        }.padding(.bottom, MassMatesSpacing.lg)
    }

    private var checklistRows: some View {
        VStack(spacing: 0) {
            hairlineDivider
            ForEach(items) { item in
                practiceRow(item)
                hairlineDivider
            }
        }
    }

    private func practiceRow(_ item: DailyRuleChecklistItem) -> some View {
        Button { toggleItem(item) } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                circularToggle(isCompleted: item.isCompleted)
                Text(item.title).font(.system(size: 16)).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                trailingLabel(for: item)
            }
            .frame(height: MassMatesLayout.minRowHeight).contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel("\(item.title), \(item.isCompleted ? "concluído" : "pendente")")
    }

    @ViewBuilder
    private func circularToggle(isCompleted: Bool) -> some View {
        if isCompleted {
            ZStack {
                Circle().fill(theme.tint)
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(theme.onTint)
            }.frame(width: 24, height: 24)
        } else {
            Circle().stroke(MassMatesPalette.textTertiary, lineWidth: 1).frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    private func trailingLabel(for item: DailyRuleChecklistItem) -> some View {
        if item.isCompleted {
            Text("Feito").font(.system(size: 12)).foregroundStyle(MassMatesPalette.textSecondary)
        } else if let schedule = item.schedule, !schedule.isEmpty {
            Text(schedule).font(.system(size: 13)).foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var spiritualQuote: some View {
        Text("“A perseverança nas pequenas coisas é fruto do amor silencioso.”")
            .font(.system(size: 14, weight: .regular, design: .serif).italic())
            .foregroundStyle(MassMatesPalette.textSecondary).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            .padding(.top, MassMatesSpacing.xl).padding(.horizontal, MassMatesSpacing.xs)
    }

    private var bottomActionArea: some View {
        Button {
            onEditRule?()
        } label: {
            Text("Editar regra de vida").font(.system(size: 14, weight: .medium)).foregroundStyle(theme.tint)
                .padding(.vertical, MassMatesSpacing.xs).padding(.horizontal, MassMatesSpacing.md)
        }
        .buttonStyle(.plain).padding(.bottom, MassMatesSpacing.lg)
    }

    private var hairlineDivider: some View { Rectangle().fill(MassMatesPalette.line).frame(height: 1) }
    private var completedCount: Int { items.filter(\.isCompleted).count }
    private var progressRatio: Double { items.isEmpty ? 0 : Double(completedCount) / Double(items.count) }

    private func toggleItem(_ target: DailyRuleChecklistItem) {
        guard let index = items.firstIndex(where: { $0.id == target.id }) else { return }
        if reduceMotion {
            items[index] = items[index].toggled()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { items[index] = items[index].toggled() }
        }
        if let practice = target.practice { onTogglePractice?(practice) }
    }
}

typealias RuleOfLifeChecklistView = RuleOfLifeSectionView

#Preview("Rule of Life Checklist — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in RuleOfLifeSectionView() }
}
