import SwiftUI

struct TodayHeaderView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let seasonTitle: String
    private let saintOrFeast: String
    private let streakDays: Int
    private let onSelectSeason: (LiturgicalColor) -> Void
    private let onOpenStreak: (() -> Void)?

    // MARK: - Init
    init(
        seasonTitle: String,
        saintOrFeast: String,
        streakDays: Int,
        onSelectSeason: @escaping (LiturgicalColor) -> Void = { _ in },
        onOpenStreak: (() -> Void)? = nil
    ) {
        self.seasonTitle = seasonTitle
        self.saintOrFeast = saintOrFeast
        self.streakDays = streakDays
        self.onSelectSeason = onSelectSeason
        self.onOpenStreak = onOpenStreak
    }

    init(
        seasonTitle: String,
        saintOrFeast: String,
        feastRankLabel: String = "",
        weekdayAndWeekLabel: String = "",
        saintQuote: String = "",
        progress: TodayProgressSummary,
        onSelectSeason: @escaping (LiturgicalColor) -> Void = { _ in },
        onOpenOnboarding: (() -> Void)? = nil,
        onOpenHistory: (() -> Void)? = nil
    ) {
        self.init(
            seasonTitle: seasonTitle,
            saintOrFeast: saintOrFeast,
            streakDays: progress.activeStreakDays,
            onSelectSeason: onSelectSeason,
            onOpenStreak: onOpenHistory ?? onOpenOnboarding
        )
    }

    nonisolated static func == (lhs: TodayHeaderView, rhs: TodayHeaderView) -> Bool {
        lhs.seasonTitle == rhs.seasonTitle &&
        lhs.saintOrFeast == rhs.saintOrFeast &&
        lhs.streakDays == rhs.streakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            seasonPillRow
            titleAndStreakRow
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
    }

    // MARK: - Subviews / Private Helpers
    private var seasonPillRow: some View {
        Menu {
            ForEach(LiturgicalColor.allCases) { color in
                Button(color.defaultSeasonName) {
                    onSelectSeason(color)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(theme.tint)
                    .frame(width: 6, height: 6)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: theme.season)
                Text(seasonPillText)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tempo litúrgico: \(seasonPillText)")
    }

    private var titleAndStreakRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(saintOrFeast.isEmpty ? "Santos de Hoje" : saintOrFeast)
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(reduceMotion ? .identity : .opacity)
            Spacer(minLength: MassMatesSpacing.sm)
            streakCounterButton
        }
    }

    private var streakCounterButton: some View {
        Button {
            onOpenStreak?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.tint)
                    .symbolEffect(.bounce, value: streakDays)
                Text("\(streakDays)")
                    .font(MassMatesFont.numeral)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(MassMatesPressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streakDays) dias em oração")
    }

    private var seasonPillText: String {
        let colorName: String = switch theme.season {
        case .green: "VERDE"
        case .purple: "ROXO"
        case .white: "BRANCO"
        case .red: "VERMELHO"
        case .rose: "ROSA"
        }
        let cleanTitle = seasonTitle.isEmpty ? theme.season.defaultSeasonName : seasonTitle
        return "\(cleanTitle.uppercased()) · \(colorName)"
    }
}

#Preview("Today Header — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        TodayHeaderView(
            seasonTitle: season.defaultSeasonName,
            saintOrFeast: "Santa Teresa de Ávila",
            streakDays: 12
        )
    }
}
