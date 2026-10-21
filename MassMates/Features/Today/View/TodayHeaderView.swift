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
            topSeasonRow
            saintHeroSection
            streakBannerSection
        }
        .padding(MassMatesSpacing.md)
        .background(headerWashGradient)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.top, MassMatesSpacing.sm)
    }

    // MARK: - Subviews / Private Helpers
    private var topSeasonRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            HStack(spacing: 6) {
                Circle().fill(theme.tint).frame(width: 8, height: 8)
                Text("\(seasonTitle) • \(colorDisplayName)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .padding(.vertical, 6)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .overlay {
                Capsule().stroke(MassMatesPalette.line, lineWidth: 1)
            }
            Spacer(minLength: MassMatesSpacing.xs)
            Text(weekdayAndWeekLabel)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var saintHeroSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(feastRankLabel.uppercased())
                .font(MassMatesFont.caption)
                .tracking(0.6)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(saintOrFeast)
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(saintQuote)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var streakBannerSection: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            HStack(spacing: MassMatesSpacing.sm) {
                StreakRingView(
                    streakDays: progress.activeStreakDays,
                    progress: max(progress.ruleCompletionRatio, 0.8),
                    size: 64
                )
                streakCopyStack
                Spacer(minLength: MassMatesSpacing.xs)
                historyCalendarButton
            }
        }
    }

    private var streakCopyStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "flame.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.warning)
                Text("\(progress.activeStreakDays) dias em oração")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Text("Mais um dia de fidelidade no amor.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(2)
        }
    }

    private var historyCalendarButton: some View {
        Button {
            (onOpenHistory ?? onOpenOnboarding)?()
        } label: {
            Image(systemName: "calendar")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 40, height: 40)
                .background(MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                .overlay {
                    Circle().stroke(MassMatesPalette.line, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ver histórico de oração")
    }

    private var colorDisplayName: String {
        switch theme.season {
        case .green: "Verde"
        case .purple: "Roxo"
        case .white: "Branco"
        case .red: "Vermelho"
        case .rose: "Rosa"
        }
    }

    private var headerWashGradient: some View {
        LinearGradient(colors: [theme.tintSoft, MassMatesPalette.bg], startPoint: .top, endPoint: .bottom)
    }
}

#Preview("Today Header — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        TodayHeaderView(
            seasonTitle: season.defaultSeasonName,
            saintOrFeast: "Santa Clara de Assis, Virgem",
            progress: TodayProgressSummary(
                baseStreakDays: 13,
                items: [RuleOfLifeItem(practice: .rosary, isCompleted: true)],
                selectedPreset: .essentialDaily
            )
        )
    }
}
