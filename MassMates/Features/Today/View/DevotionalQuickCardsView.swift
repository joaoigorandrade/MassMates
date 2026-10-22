import SwiftUI

struct DevotionalQuickCardsView: View {
    // MARK: - Dependencies & State
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
        VStack(spacing: 0) {
            hairlineDivider
            gospelRow
            hairlineDivider
            prayerAndRosaryRow
            hairlineDivider
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
    }

    // MARK: - Subviews / Private Helpers
    private var gospelRow: some View {
        Button(action: onOpenGospel) {
            devotionalRow(
                title: "Evangelho do dia",
                subtitle: gospelSubtitle
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Evangelho do dia, \(gospelSubtitle)")
    }

    private var prayerAndRosaryRow: some View {
        Button {
            onOpenTimer(.rosary)
        } label: {
            devotionalRow(
                title: "Oração & Terço",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Oração & Terço")
    }

    private func devotionalRow(title: String, subtitle: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .frame(minHeight: MassMatesLayout.minRowHeight)
        .contentShape(Rectangle())
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private var gospelSubtitle: String {
        reading.gospelReference.isEmpty ? "Lc 12,49-53" : reading.gospelReference
    }
}

#Preview("Devotional Quick Rows — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DevotionalQuickCardsView(
            reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime),
            onOpenGospel: {},
            onOpenTimer: { _ in }
        )
    }
}
