import SwiftUI

struct ConsistencyHeatmapCardView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let days: [ConsistencyHeatmapDay]
    private let activeStreakDays: Int

    private static let weekdayLabels = ["D", "S", "T", "Q", "Q", "S", "S"]
    private static let baselineWeeks: [[Int]] = [
        [1, 2, 0, 2, 4, 3, 0], [4, 3, 2, 0, 1, 4, 2], [0, 4, 3, 4, 1, 0, 2],
        [4, 4, 3, 1, 4, 0, 4], [2, 0, 4, 3, 4, 2, 0], [4, 4, 0, 3, 4, 1, 4],
        [2, 4, 0, 4, 3, 0, 4], [4, 3, 4, 0, 1, 4, 2], [0, 2, 4, 4, 3, 4, 0],
        [4, 0, 1, 4, 4, 3, 4], [3, 4, 0, 2, 4, 4, 0], [4, 2, 4, 3, 0, 4, 4]
    ]
    private static let defaultFaithfulDaysCount = 63

    nonisolated static func == (lhs: ConsistencyHeatmapCardView, rhs: ConsistencyHeatmapCardView) -> Bool {
        lhs.activeStreakDays == rhs.activeStreakDays && lhs.days == rhs.days
    }

    // MARK: - Init
    init(
        days: [ConsistencyHeatmapDay] = [],
        activeStreakDays: Int = 28,
        canClaimStreakMercy: Bool = false,
        onClaimStreakMercy: (() -> Void)? = nil
    ) {
        self.days = days
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            headerRow
            heatmapGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("Últimas 12 semanas · \(faithfulDaysCount) dias fiéis")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer(minLength: MassMatesSpacing.xs)
            legendView
        }
    }

    private var legendView: some View {
        HStack(spacing: 3) {
            Text("Menos")
                .font(.system(size: 10))
                .foregroundStyle(MassMatesPalette.textTertiary)
            ForEach([0.0, 0.15, 0.35, 0.65, 1.0], id: \.self) { opacity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(opacity == 0 ? MassMatesPalette.line : theme.tint.opacity(opacity))
                    .frame(width: 8, height: 8)
            }
            Text("Mais")
                .font(.system(size: 10))
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var heatmapGrid: some View {
        VStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { day in
                HStack(spacing: 3) {
                    Text(Self.weekdayLabels[day])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(MassMatesPalette.textTertiary)
                        .frame(width: 14, alignment: .leading)
                    ForEach(0..<12, id: \.self) { week in
                        cellView(week: week, day: day)
                    }
                }
            }
        }
    }

    private func cellView(week: Int, day: Int) -> some View {
        let level = intensityLevel(week: week, day: day)
        return RoundedRectangle(cornerRadius: 2.5)
            .fill(cellColor(level: level))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }

    private func cellColor(level: Int) -> Color {
        switch level {
        case 1: theme.tint.opacity(0.15)
        case 2: theme.tint.opacity(0.35)
        case 3: theme.tint.opacity(0.65)
        case 4...: theme.tint
        default: MassMatesPalette.line
        }
    }

    private func intensityLevel(week: Int, day: Int) -> Int {
        if days.count >= 84 {
            let offset = days.count - 84
            let dayItem = days[offset + (week * 7) + day]
            return dayItem.isRepairedByStreakMercy ? 4 : dayItem.intensityLevel
        }
        return Self.baselineWeeks[min(week, 11)][day]
    }

    private var faithfulDaysCount: Int {
        if days.count >= 84 {
            return days.suffix(84).filter { $0.practiceCount > 0 || $0.isRepairedByStreakMercy }.count
        }
        return Self.defaultFaithfulDaysCount
    }
}

#Preview("Consistency Heatmap — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConsistencyHeatmapCardView(
            days: LocalMyPathService.defaultHeatmapDays(),
            activeStreakDays: 28
        )
    }
}
