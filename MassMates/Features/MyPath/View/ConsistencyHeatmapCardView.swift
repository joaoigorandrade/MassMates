import SwiftUI

struct ConsistencyHeatmapCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let days: [ConsistencyHeatmapDay]
    private let activeStreakDays: Int
    private let canClaimStreakMercy: Bool
    private let onClaimStreakMercy: () -> Void

    private static let baselineWeeks: [[Int]] = [
        [0, 1, 3, 4, 0, 2, 4], [4, 3, 0, 2, 4, 1, 4], [0, 2, 4, 3, 0, 0, 2], [4, 4, 3, 1, 4, 0, 4],
        [2, 0, 4, 3, 4, 2, 0], [4, 4, 0, 3, 4, 1, 4], [2, 4, 0, 4, 3, 0, 4], [4, 3, 4, 0, 1, 4, 2],
        [0, 2, 4, 4, 3, 4, 0], [4, 0, 1, 4, 4, 3, 4], [3, 4, 0, 2, 4, 4, 0], [4, 2, 4, 3, 0, 4, 4]
    ]

    // MARK: - Init
    init(
        days: [ConsistencyHeatmapDay],
        activeStreakDays: Int,
        canClaimStreakMercy: Bool,
        onClaimStreakMercy: @escaping () -> Void
    ) {
        self.days = days
        self.activeStreakDays = activeStreakDays
        self.canClaimStreakMercy = canClaimStreakMercy
        self.onClaimStreakMercy = onClaimStreakMercy
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            headerRow
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    monthLabelsRow
                    heatmapMatrix
                }
            }
            legendRow
            mercySection
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack {
            Text("CONSTÂNCIA")
                .font(MassMatesFont.caption)
                .tracking(0.8)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Text("Últimos 4 meses")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var monthLabelsRow: some View {
        HStack(spacing: 0) {
            ForEach(["Jul", "Ago", "Set", "Out"], id: \.self) { month in
                Text(month)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: (12 * 4) + (5 * 4), alignment: .leading)
            }
        }
    }

    private var heatmapMatrix: some View {
        HStack(spacing: 5) {
            ForEach(0..<16, id: \.self) { week in
                VStack(spacing: 5) {
                    ForEach(0..<7, id: \.self) { dayOfWeek in
                        cellView(week: week, dayOfWeek: dayOfWeek)
                    }
                }
            }
        }
    }

    private func cellView(week: Int, dayOfWeek: Int) -> some View {
        let info = cellInfo(week: week, dayOfWeek: dayOfWeek)
        return RoundedRectangle(cornerRadius: 3)
            .fill(info.isRepaired ? theme.tint : cellColor(level: info.level))
            .frame(width: 12, height: 12)
            .overlay {
                if info.isRepaired {
                    RoundedRectangle(cornerRadius: 3).stroke(MassMatesPalette.warning, lineWidth: 1.5)
                }
            }
    }

    private var legendRow: some View {
        HStack(spacing: 4) {
            Text("Menos").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            ForEach([0.0, 0.15, 0.35, 0.65, 1.0], id: \.self) { opacity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(opacity == 0 ? MassMatesPalette.line : theme.tint.opacity(opacity))
                    .frame(width: 9, height: 9)
            }
            Text("Mais").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            Spacer()
            Text(theme.season.defaultSeasonName).font(MassMatesFont.caption.italic()).foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    @ViewBuilder
    private var mercySection: some View {
        if canClaimStreakMercy {
            Button(action: onClaimStreakMercy) {
                HStack(spacing: MassMatesSpacing.xs) {
                    Image(systemName: "sparkles").foregroundStyle(theme.tint)
                    Text("Misericórdia da Constância (Restaurar 1 dia)")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                }
                .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private func cellInfo(week: Int, dayOfWeek: Int) -> (level: Int, isRepaired: Bool) {
        if days.count >= 112 {
            let offset = days.count - 112
            let day = days[offset + (week * 7) + dayOfWeek]
            return (day.intensityLevel, day.isRepairedByStreakMercy)
        }
        if week >= 12 {
            let dayIndex = (week - 12) * 7 + dayOfWeek
            if dayIndex < days.count {
                let day = days[dayIndex]
                return (day.intensityLevel, day.isRepairedByStreakMercy)
            }
        }
        return (Self.baselineWeeks[min(week, 11)][dayOfWeek], false)
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
}

#Preview("Consistency Heatmap — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConsistencyHeatmapCardView(
            days: LocalMyPathService.defaultHeatmapDays(),
            activeStreakDays: 28,
            canClaimStreakMercy: true,
            onClaimStreakMercy: {}
        )
    }
}
