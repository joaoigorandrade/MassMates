import SwiftUI

struct MyPathProfileView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @State private var viewModel: MyPathViewModel
    private let onOpenDiaryOverride: (() -> Void)?
    private let onOpenSettingsOverride: (() -> Void)?

    // MARK: - Init
    init(
        viewModel: MyPathViewModel = MyPathViewModel(),
        onOpenDiary: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenDiaryOverride = onOpenDiary
        self.onOpenSettingsOverride = onOpenSettings
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                MyPathIdentityAndMetricsSectionView(
                    activeStreakDays: viewModel.milestones.activeStreakDays,
                    onOpenSettings: triggerOpenSettings
                )
                statusBanner
                ConsistencyHeatmapCardView(
                    days: viewModel.heatmapDays,
                    activeStreakDays: viewModel.milestones.activeStreakDays,
                    canClaimStreakMercy: viewModel.milestones.canClaimStreakMercyThisMonth,
                    onClaimStreakMercy: { _ = viewModel.claimStreakMercy() }
                )
                MyPathRuleOfLifeDistributionCardView()
                milestonesSection
                MyPathDiaryPreviewAndPrivacySectionView(
                    onOpenDiary: triggerOpenDiary,
                    onOpenSettings: triggerOpenSettings
                )
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var statusBanner: some View {
        if let message = viewModel.statusBannerMessage {
            Text(message)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("MARCOS")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)
            HStack(spacing: MassMatesSpacing.md) {
                milestoneStat(value: "\(viewModel.milestones.rosariesPrayed)", label: "terços")
                milestoneStat(value: "\(viewModel.milestones.massesAttended)", label: "missas")
                milestoneStat(value: "\(viewModel.milestones.mentalPrayerHours)h", label: "oração")
            }
        }
        .padding(.horizontal, 2)
    }

    private func milestoneStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(value)
                .font(MassMatesFont.numeral)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(label)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func triggerOpenDiary() {
        if let onOpenDiaryOverride { onOpenDiaryOverride() } else { viewModel.requestOpenDiary() }
    }

    private func triggerOpenSettings() {
        if let onOpenSettingsOverride { onOpenSettingsOverride() } else { viewModel.requestOpenSettings() }
    }
}

#Preview("My Path Profile — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        MyPathProfileView(viewModel: MyPathViewModel(season: season))
    }
}
