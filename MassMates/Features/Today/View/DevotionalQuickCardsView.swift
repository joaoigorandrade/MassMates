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
            sectionHeader
            gospelLectioCard
            adorationAndRosaryCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack {
            Text("Devocionais do Dia")
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Text("Momento presente")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var gospelLectioCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                gospelCardHeader
                VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                    Text("Evangelho de Hoje")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(reading.gospelCalloutQuote)
                        .font(MassMatesFont.scriptureEmphasis)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                gospelCardFooter
            }
        }
    }

    private var gospelCardHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "book.pages")
                Text(reading.gospelReference)
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(theme.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            Spacer()
            Text("Liturgia da Palavra")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var gospelCardFooter: some View {
        HStack {
            Text("Guia de 4 passos (Lectio, Meditatio...)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(1)
            Spacer(minLength: MassMatesSpacing.xs)
            Button(action: onOpenGospel) {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Text("Iniciar Lectio")
                    Image(systemName: "arrow.right")
                }
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.onTint)
                .padding(.horizontal, MassMatesSpacing.md)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
        }
    }

    private var adorationAndRosaryCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                adorationCardHeader
                Text("Temporizador contemplativo com carrilhões de mosteiro, mistérios do dia e acompanhamento de respiração.")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                adorationCardFooter
            }
        }
    }

    private var adorationCardHeader: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            ZStack {
                Circle().fill(MassMatesPalette.surfaceMuted).frame(width: 48, height: 48)
                Image(systemName: "timelapse")
                    .font(MassMatesFont.title)
                    .foregroundStyle(theme.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("SILÊNCIO & PRESENÇA")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("Adoração & Santo Terço")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer(minLength: MassMatesSpacing.xs)
            Text("Sons suaves")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, 4)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private var adorationCardFooter: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Circle().fill(MassMatesPalette.success).frame(width: 8, height: 8)
                Text("1.240 rezando agora")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer(minLength: MassMatesSpacing.xs)
            Button {
                onOpenTimer(.mentalPrayer)
            } label: {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Text("Rezar Agora")
                    Image(systemName: "play.fill")
                }
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(.horizontal, MassMatesSpacing.md)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
        }
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
