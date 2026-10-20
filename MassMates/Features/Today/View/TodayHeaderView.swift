import SwiftUI

struct TodayHeaderView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let seasonTitle: String
    private let saintOrFeast: String
    private let progress: TodayProgressSummary
    private let onSelectSeason: (LiturgicalColor) -> Void
    private let onOpenOnboarding: (() -> Void)?

    // MARK: - Init
    init(
        seasonTitle: String,
        saintOrFeast: String,
        progress: TodayProgressSummary,
        onSelectSeason: @escaping (LiturgicalColor) -> Void = { _ in },
        onOpenOnboarding: (() -> Void)? = nil
    ) {
        self.seasonTitle = seasonTitle
        self.saintOrFeast = saintOrFeast
        self.progress = progress
        self.onSelectSeason = onSelectSeason
        self.onOpenOnboarding = onOpenOnboarding
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            topContentRow
            encouragementBanner
            seasonCycleStrip
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.vertical, MassMatesSpacing.lg)
        .background(headerWashGradient)
    }

    // MARK: - Subviews / Private Helpers
    private var topContentRow: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.md) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("Calendário Litúrgico")
                    .font(MassMatesFont.caption)
                    .foregroundStyle( theme.tint )
                Text(seasonTitle)
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(saintOrFeast)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer(minLength: MassMatesSpacing.sm)
            StreakRingView(
                streakDays: progress.activeStreakDays,
                progress: progress.ruleCompletionRatio
            )
        }
    }

    private var encouragementBanner: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: progress.hasCompletedAnyToday ? "flame.fill" : "sparkles")
                .foregroundStyle(theme.tint)
            Text(progress.encouragementText)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            if let onOpenOnboarding {
                MassMatesTextButton(title: "Compromisso") {
                    onOpenOnboarding()
                }
            }
        }
    }

    private var seasonCycleStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(LiturgicalColor.allCases) { season in
                    seasonChip(season)
                }
            }
        }
    }

    private func seasonChip(_ season: LiturgicalColor) -> some View {
        let isSelected = theme.season == season
        return Button {
            onSelectSeason(season)
        } label: {
            Text(season.defaultSeasonName)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay {
                    Capsule()
                        .stroke(isSelected ? theme.tint : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var headerWashGradient: some View {
        LinearGradient(
            colors: [theme.tintSoft, MassMatesPalette.bg],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Today Header — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        TodayHeaderView(
            seasonTitle: season.defaultSeasonName,
            saintOrFeast: "São Pedro de Alcântara, Presbítero",
            progress: TodayProgressSummary(
                baseStreakDays: 7,
                items: [RuleOfLifeItem(practice: .rosary, isCompleted: true)],
                selectedPreset: .essentialDaily
            )
        )
    }
}
