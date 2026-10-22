import SwiftUI

struct MyPathIdentityAndMetricsSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let activeStreakDays: Int
    private let prayersCount: Int
    private let fraternitiesCount: Int
    private let userName: String
    private let parishName: String
    private let onOpenSettings: () -> Void

    // MARK: - Init
    init(
        activeStreakDays: Int,
        prayersCount: Int = 384,
        fraternitiesCount: Int = 2,
        userName: String = "João",
        parishName: String = "Paróquia São José",
        onOpenSettings: @escaping () -> Void
    ) {
        self.activeStreakDays = activeStreakDays
        self.prayersCount = prayersCount
        self.fraternitiesCount = fraternitiesCount
        self.userName = userName
        self.parishName = parishName
        self.onOpenSettings = onOpenSettings
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.lg) {
            topBar
            profileHeader
            keyMetricsRow
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(
                        width: MassMatesLayout.minTapTarget,
                        height: MassMatesLayout.minTapTarget
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Configurações")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            avatarView
            Text("Meu Caminho")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("\(userName) • \(parishName)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(MassMatesPalette.surface)
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(MassMatesPalette.textSecondary.opacity(0.85))
                .padding(MassMatesSpacing.xxs)
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var keyMetricsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            statColumn(value: "\(activeStreakDays)", label: "Dias Seguidos")
            statDivider
            statColumn(value: "\(prayersCount)", label: "Orações Feitas")
            statDivider
            statColumn(value: "\(fraternitiesCount)", label: "Fraternidades")
        }
        .padding(.vertical, MassMatesSpacing.xs)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text(value)
                .font(MassMatesFont.numeral)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(label)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(width: 1, height: 32)
    }
}

#Preview("My Path Identity & Metrics — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathIdentityAndMetricsSectionView(
            activeStreakDays: 28,
            onOpenSettings: {}
        )
    }
}
