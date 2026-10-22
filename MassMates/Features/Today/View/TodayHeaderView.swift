import SwiftUI

struct TodayHeaderView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let seasonTitle: String
    private let saintOrFeast: String
    private let feastRankLabel: String
    private let weekdayAndWeekLabel: String
    private let saintQuote: String
    private let progress: TodayProgressSummary
    private let onSelectSeason: (LiturgicalColor) -> Void
    private let onOpenOnboarding: (() -> Void)?
    private let onOpenHistory: (() -> Void)?

    // MARK: - Init
    init(
        seasonTitle: String,
        saintOrFeast: String,
        feastRankLabel: String = "MEMÓRIA FACULTATIVA",
        weekdayAndWeekLabel: String = "Quarta-feira • Semana III",
        saintQuote: String = "“Olha cada dia para o teu Esposo, Cristo, e repara nas suas virtudes.”",
        progress: TodayProgressSummary,
        onSelectSeason: @escaping (LiturgicalColor) -> Void = { _ in },
        onOpenOnboarding: (() -> Void)? = nil,
        onOpenHistory: (() -> Void)? = nil
    ) {
        self.seasonTitle = seasonTitle
        self.saintOrFeast = saintOrFeast
        self.feastRankLabel = feastRankLabel
        self.weekdayAndWeekLabel = weekdayAndWeekLabel
        self.saintQuote = saintQuote
        self.progress = progress
        self.onSelectSeason = onSelectSeason
        self.onOpenOnboarding = onOpenOnboarding
        self.onOpenHistory = onOpenHistory
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            headerMainRow
            if !saintOrFeast.isEmpty {
                saintSection
            }
            hairlineDivider
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.top, MassMatesSpacing.sm)
    }

    // MARK: - Subviews / Private Helpers
    private var headerMainRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Hoje")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                seasonSubtitleRow
            }
            Spacer(minLength: MassMatesSpacing.md)
            streakRingButton
        }
    }

    private var seasonSubtitleRow: some View {
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
                Text(seasonSubtitle)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var streakRingButton: some View {
        Button {
            (onOpenHistory ?? onOpenOnboarding)?()
        } label: {
            StreakRingView(
                streakDays: progress.activeStreakDays,
                progress: progress.ruleCompletionRatio,
                size: 58
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ver histórico de oração: \(progress.activeStreakDays) dias em oração")
    }

    private var saintSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            if !feastRankLabel.isEmpty {
                Text(feastRankLabel.uppercased())
                    .font(MassMatesFont.caption)
                    .tracking(0.6)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text(saintOrFeast)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if !saintQuote.isEmpty {
                Text(saintQuote)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
            .padding(.top, MassMatesSpacing.xs)
    }

    private var seasonSubtitle: String {
        let separatorCandidates = ["•", "·", "-"]
        for sep in separatorCandidates where weekdayAndWeekLabel.contains(sep) {
            let parts = weekdayAndWeekLabel.components(separatedBy: sep)
            if parts.count > 1 {
                let suffix = parts[1].trimmingCharacters(in: .whitespaces)
                return "\(seasonTitle) · \(suffix)"
            }
        }
        if weekdayAndWeekLabel.isEmpty {
            return "\(seasonTitle) · Semana 29"
        }
        return "\(seasonTitle) · \(weekdayAndWeekLabel)"
    }
}

#Preview("Today Header — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        TodayHeaderView(
            seasonTitle: season.defaultSeasonName,
            saintOrFeast: "Santa Clara de Assis, Virgem",
            progress: TodayProgressSummary(
                baseStreakDays: 14,
                items: [RuleOfLifeItem(practice: .rosary, isCompleted: true)],
                selectedPreset: .essentialDaily
            )
        )
    }
}
