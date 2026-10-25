import Navigation
import SwiftUI

struct RuleOfLifeSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @State private var items: [DailyRuleChecklistItem]
    @State private var selectedPreset: RuleOfLifePreset
    private let onSelectPreset: ((RuleOfLifePreset) -> Void)?
    private let onEditRule: (() -> Void)?
    private let onTogglePractice: ((SpiritualPractice) -> Void)?

    // MARK: - Init
    init(
        items: [DailyRuleChecklistItem] = DailyRuleChecklistItem.stitchDefaultItems,
        selectedPreset: RuleOfLifePreset = .essentialDaily,
        onSelectPreset: ((RuleOfLifePreset) -> Void)? = nil,
        onEditRule: (() -> Void)? = nil,
        onTogglePractice: ((SpiritualPractice) -> Void)? = nil
    ) {
        _items = State(initialValue: items)
        _selectedPreset = State(initialValue: selectedPreset)
        self.onSelectPreset = onSelectPreset
        self.onEditRule = onEditRule
        self.onTogglePractice = onTogglePractice
    }

    init(
        progress: TodayProgressSummary,
        onSelectPreset: @escaping (RuleOfLifePreset) -> Void = { _ in },
        onTogglePractice: @escaping (SpiritualPractice) -> Void = { _ in },
        onEditRule: (() -> Void)? = nil
    ) {
        self.init(items: DailyRuleChecklistItem.from(summary: progress), selectedPreset: progress.selectedPreset, onSelectPreset: onSelectPreset, onEditRule: onEditRule ?? { onSelectPreset(progress.selectedPreset) }, onTogglePractice: onTogglePractice)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView(showsIndicators: false) {
                mainContentArea
                bottomActionArea
            }
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
                if let navigator { navigator.dismiss() } else { dismiss() }
            } label: {
                Image(systemName: "xmark").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityLabel("Fechar")
            Spacer()
            Text("Regra de Vida").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Color.clear.frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }
        .padding(.horizontal, MassMatesSpacing.md).frame(height: 56)
    }

    private var mainContentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FIDELIDADE DIÁRIA").font(MassMatesFont.caption).tracking(0.8)
                .foregroundStyle(MassMatesPalette.textSecondary).padding(.bottom, MassMatesSpacing.xs)
            presetPills
            progressSection
            checklistRows
            spiritualQuote
        }
        .padding(.horizontal, MassMatesLayout.screenMargin).padding(.top, MassMatesSpacing.sm)
    }

    private var presetPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(RuleOfLifePreset.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button { selectPreset(preset) } label: {
                        Text(preset.title).font(isSelected ? MassMatesFont.headline : MassMatesFont.caption)
                            .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textSecondary)
                            .padding(.horizontal, MassMatesSpacing.sm)
                            .frame(minHeight: MassMatesLayout.minTapTarget)
                            .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                            .contentShape(.rect(cornerRadius: MassMatesRadius.chip))
                    }
                    .buttonStyle(.plain).accessibilityLabel(preset.title)
                }
            }
        }.padding(.bottom, MassMatesSpacing.sm)
    }

    private var progressSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack {
                Text("Progresso de hoje").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("\(completedCount) de \(items.count)").font(MassMatesFont.callout).fontWeight(.medium).foregroundStyle(theme.tint)
            }
            MassMatesProgressBar(progress: progressRatio)
        }.padding(.bottom, MassMatesSpacing.md)
    }

    private var checklistRows: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            ForEach(items) { item in
                RuleOfLifeRowView(item: item) { toggleItem(item) }
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            }
        }
    }

    private var spiritualQuote: some View {
        Text("“A perseverança nas pequenas coisas é fruto do amor silencioso.”")
            .font(MassMatesFont.scriptureEmphasis).foregroundStyle(MassMatesPalette.textSecondary)
            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            .padding(.top, MassMatesSpacing.lg).padding(.horizontal, MassMatesSpacing.xs)
    }

    private var bottomActionArea: some View {
        Button { onEditRule?() } label: {
            Text("Editar regra de vida").font(MassMatesFont.callout).fontWeight(.medium).foregroundStyle(theme.tint)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .padding(.horizontal, MassMatesSpacing.md)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).padding(.vertical, MassMatesSpacing.md)
    }

    private var completedCount: Int { items.filter(\.isCompleted).count }
    private var progressRatio: Double { items.isEmpty ? 0 : Double(completedCount) / Double(items.count) }

    private func toggleItem(_ target: DailyRuleChecklistItem) {
        guard let index = items.firstIndex(where: { $0.id == target.id }) else { return }
        if reduceMotion { items[index] = items[index].toggled() } else {
            withAnimation(.easeInOut(duration: 0.2)) { items[index] = items[index].toggled() }
        }
        if let practice = target.practice { onTogglePractice?(practice) }
    }

    private func selectPreset(_ preset: RuleOfLifePreset) {
        selectedPreset = preset
        onSelectPreset?(preset)
        items = preset.practices.map { practice in
            DailyRuleChecklistItem(
                id: practice.rawValue, title: practice.title, schedule: practice.subtitle,
                isCompleted: items.first(where: { $0.practice == practice })?.isCompleted ?? false, practice: practice
            )
        }
    }
}

typealias RuleOfLifeChecklistView = RuleOfLifeSectionView

#Preview("Rule of Life Checklist — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in RuleOfLifeSectionView() }
}
