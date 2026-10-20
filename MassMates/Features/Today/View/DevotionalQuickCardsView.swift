import SwiftUI

struct DevotionalQuickCardsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let reading: DailyLiturgicalReading
    private let onOpenGospel: () -> Void
    private let onOpenTimer: (PrayerTimerMode) -> Void

    // MARK: - Init
    init(
        reading: DailyLiturgicalReading,
        onOpenGospel: @escaping () -> Void,
        onOpenTimer: @escaping (PrayerTimerMode) -> Void
    ) {
        self.reading = reading
        self.onOpenGospel = onOpenGospel
        self.onOpenTimer = onOpenTimer
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Recolhimento e Palavra")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            gospelCardButton
            HStack(spacing: MassMatesSpacing.sm) {
                timerQuickCard(
                    title: "Oração Mental",
                    subtitle: "Temporizador silencioso",
                    systemImage: "hourglass",
                    mode: .mentalPrayer
                )
                timerQuickCard(
                    title: "Santo Terço",
                    subtitle: "Guia e contador tátil",
                    systemImage: "circle.grid.cross",
                    mode: .rosary
                )
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var gospelCardButton: some View {
        Button(action: onOpenGospel) {
            MassMatesCard {
                HStack(spacing: MassMatesSpacing.md) {
                    Image(systemName: "book.closed")
                        .font(MassMatesFont.title)
                        .foregroundStyle(theme.tint)
                    VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                        Text("Evangelho Diário e Lectio Divina")
                            .font(MassMatesFont.headline)
                            .foregroundStyle(MassMatesPalette.textPrimary)
                        Text("\(reading.gospelReference) • Sem anúncios")
                            .font(MassMatesFont.callout)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func timerQuickCard(
        title: String,
        subtitle: String,
        systemImage: String,
        mode: PrayerTimerMode
    ) -> some View {
        Button {
            onOpenTimer(mode)
        } label: {
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                    Image(systemName: systemImage)
                        .font(MassMatesFont.title)
                        .foregroundStyle(theme.tint)
                    Text(title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Devotional Quick Cards — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DevotionalQuickCardsView(
            reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime),
            onOpenGospel: {},
            onOpenTimer: { _ in }
        )
    }
}
