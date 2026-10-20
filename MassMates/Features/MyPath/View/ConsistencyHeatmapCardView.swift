import SwiftUI

struct ConsistencyHeatmapCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let days: [ConsistencyHeatmapDay]
    private let activeStreakDays: Int
    private let canClaimStreakMercy: Bool
    private let onClaimStreakMercy: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: MassMatesSpacing.xs),
        count: 7
    )

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
                LazyVGrid(columns: columns, spacing: MassMatesSpacing.xs) {
                    ForEach(days) { day in
                        dayCell(day)
                    }
                }
                legendAndMercySection
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Mapa de Constância • 28 dias")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Sem culpa nos dias silenciosos: recomece sempre em paz.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Text("\(activeStreakDays) d")
                .font(MassMatesFont.numeral)
                .foregroundStyle(theme.tint)
        }
    }

    private func dayCell(_ day: ConsistencyHeatmapDay) -> some View {
        VStack(spacing: 2) {
            Text("\(day.dayNumber)")
                .font(MassMatesFont.caption)
                .foregroundStyle(dayTextColor(for: day))
            if day.isRepairedByStreakMercy {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.warning)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(dayBackground(for: day))
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                .stroke(dayBorderColor(for: day), lineWidth: 1)
        )
        .accessibilityLabel("\(day.dateLabel), \(day.practiceCount) práticas")
    }

    private var legendAndMercySection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Misericórdia da Constância (1×/mês): restaure 1 dia silencioso assistindo a um breve vídeo de apoio.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            if canClaimStreakMercy {
                MassMatesSecondaryButton(
                    title: "Restaurar 1 dia (Vídeo de Apoio)",
                    systemImage: "sparkles"
                ) {
                    onClaimStreakMercy()
                }
            } else {
                Text("Misericórdia mensal já aplicada neste ciclo.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle( theme.tint)
            }
        }
    }

    private func dayBackground(for day: ConsistencyHeatmapDay) -> Color {
        if day.isRepairedByStreakMercy {
            return theme.tintSoft
        }
        switch day.intensityLevel {
        case 0: return MassMatesPalette.surfaceMuted
        case 1: return theme.tintSoft
        case 2: return theme.tint.opacity(0.65)
        default: return theme.tint
        }
    }

    private func dayTextColor(for day: ConsistencyHeatmapDay) -> Color {
        day.intensityLevel >= 2 && !day.isRepairedByStreakMercy
            ? theme.onTint
            : MassMatesPalette.textPrimary
    }

    private func dayBorderColor(for day: ConsistencyHeatmapDay) -> Color {
        day.isRepairedByStreakMercy ? MassMatesPalette.warning : MassMatesPalette.line
    }
}

#Preview("Consistency Heatmap — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConsistencyHeatmapCardView(
            days: LocalMyPathService.defaultHeatmapDays(),
            activeStreakDays: 12,
            canClaimStreakMercy: true,
            onClaimStreakMercy: {}
        )
    }
}
