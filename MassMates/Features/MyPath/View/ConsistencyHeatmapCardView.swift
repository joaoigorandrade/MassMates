import SwiftUI

struct ConsistencyHeatmapCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let days: [ConsistencyHeatmapDay]
    private let activeStreakDays: Int
    private let canClaimStreakMercy: Bool
    private let onClaimStreakMercy: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 7
    )
    private let weekdays = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]

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
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                headerRow
                weekdayHeaderRow
                LazyVGrid(columns: columns, spacing: 6) {
                    Color.clear.frame(height: 32)
                    Color.clear.frame(height: 32)
                    ForEach(days) { day in
                        dayCell(day)
                    }
                }
                pastoralLegendRow
                mercySection
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "calendar")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(theme.tint)
                Text("Outubro 2024")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.circle)
                Image(systemName: "chevron.right")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.circle)
            }
        }
    }

    private var weekdayHeaderRow: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { label in
                Text(label)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: ConsistencyHeatmapDay) -> some View {
        ZStack {
            Circle()
                .fill(dayBackground(for: day))
            if day.dayNumber == 27 || day.isRepairedByStreakMercy {
                Circle()
                    .stroke(
                        day.isRepairedByStreakMercy ? MassMatesPalette.warning : theme.tint,
                        lineWidth: 2
                    )
            }
            Text("\(day.dayNumber)")
                .font(MassMatesFont.caption)
                .foregroundStyle(dayTextColor(for: day))
        }
        .frame(height: 32)
        .accessibilityLabel("\(day.dateLabel), \(day.practiceCount) práticas")
    }

    private var pastoralLegendRow: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(theme.tint).frame(width: 10, height: 10)
                Text("Oração vivida")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(MassMatesPalette.surfaceMuted).frame(width: 10, height: 10)
                Text("Recomeço suave")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            Spacer()
            Text(theme.season.defaultSeasonName)
                .font(MassMatesFont.caption.italic())
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    @ViewBuilder
    private var mercySection: some View {
        if canClaimStreakMercy {
            MassMatesSecondaryButton(
                title: "Misericórdia da Constância (Restaurar 1 dia)",
                systemImage: "sparkles",
                action: onClaimStreakMercy
            )
        }
    }

    private func dayBackground(for day: ConsistencyHeatmapDay) -> Color {
        if day.isRepairedByStreakMercy {
            return theme.tintSoft
        }
        switch day.intensityLevel {
        case 0: return MassMatesPalette.surfaceMuted
        case 1: return theme.tintSoft
        default: return theme.tint
        }
    }

    private func dayTextColor(for day: ConsistencyHeatmapDay) -> Color {
        if day.isRepairedByStreakMercy || day.intensityLevel == 1 {
            return theme.tint
        }
        return day.intensityLevel >= 2 ? theme.onTint : MassMatesPalette.textSecondary
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
