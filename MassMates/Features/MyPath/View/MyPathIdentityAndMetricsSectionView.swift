import SwiftUI

struct MyPathIdentityAndMetricsSectionView: View {
    // MARK: - Dependencies & State
    private let rosariesCount: Int
    private let massesCount: Int
    private let prayerHours: Int

    // MARK: - Init
    init(
        rosariesCount: Int = 84,
        massesCount: Int = 22,
        prayerHours: Int = 31,
        activeStreakDays: Int = 28,
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.rosariesCount = rosariesCount
        self.massesCount = massesCount
        self.prayerHours = prayerHours
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack(spacing: 0) {
            statItem(value: "\(rosariesCount)", label: "Terços")
            hairlineDivider
            statItem(value: "\(massesCount)", label: "Missas")
            hairlineDivider
            statItem(value: "\(prayerHours)h", label: "Oração")
        }
        .padding(.vertical, MassMatesSpacing.sm)
        .overlay(alignment: .top) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
    }

    // MARK: - Subviews / Private Helpers
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text(value)
                .font(MassMatesFont.numeral)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(width: 1, height: 32)
    }
}

#Preview("My Path Identity & Metrics — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathIdentityAndMetricsSectionView(
            rosariesCount: 84,
            massesCount: 22,
            prayerHours: 31
        )
    }
}
