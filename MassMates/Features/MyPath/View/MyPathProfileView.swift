import SwiftUI

struct MyPathProfileView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @State private var viewModel: MyPathViewModel
    @State private var showingGraceAndMercy = false
    private let onOpenDiaryOverride: (() -> Void)?
    private let onOpenSettingsOverride: (() -> Void)?
    private let onOpenGraceAndMercyOverride: (() -> Void)?

    // MARK: - Init
    init(
        viewModel: MyPathViewModel = MyPathViewModel(),
        onOpenDiary: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onOpenGraceAndMercy: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenDiaryOverride = onOpenDiary
        self.onOpenSettingsOverride = onOpenSettings
        self.onOpenGraceAndMercyOverride = onOpenGraceAndMercy
    }

    // MARK: - Body / Public API
    var body: some View {
        Group {
            if showingGraceAndMercy {
                graceAndMercyView
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                dashboardView
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var dashboardView: some View {
        VStack(spacing: MassMatesSpacing.md) {
            headerBar
            statusBanner
            ConsistencyHeatmapCardView(
                days: viewModel.heatmapDays,
                activeStreakDays: viewModel.milestones.activeStreakDays
            )
            MyPathIdentityAndMetricsSectionView(
                rosariesCount: viewModel.milestones.rosariesPrayed,
                massesCount: viewModel.milestones.massesAttended,
                prayerHours: viewModel.milestones.mentalPrayerHours
            )
            navigationRows
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
    }

    private var headerBar: some View {
        HStack {
            Text("Meu Caminho")
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button(action: triggerOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajustes")
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let message = viewModel.statusBannerMessage {
            Text(message)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(MassMatesSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var navigationRows: some View {
        VStack(spacing: 0) {
            navRow(icon: "faceid", title: "Diário espiritual", action: triggerOpenDiary)
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            navRow(icon: "sparkles", title: "Graça & Misericórdia", action: triggerOpenGraceAndMercy)
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            navRow(icon: "slider.horizontal.3", title: "Ajustes", action: triggerOpenSettings)
        }
    }

    private func navRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .frame(height: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var graceAndMercyView: some View {
        MyPathGraceAndMercyView(
            canClaimStreakMercy: viewModel.milestones.canClaimStreakMercyThisMonth,
            onBack: { withAnimation(.easeInOut(duration: 0.2)) { showingGraceAndMercy = false } },
            onClaimStreakMercy: { Task { _ = await viewModel.claimStreakMercy() } },
            onUnlockSaintTheme: { viewModel.unlockOrSelectSaintIcon(.stTherese) }
        )
    }

    private func triggerOpenDiary() {
        if let onOpenDiaryOverride { onOpenDiaryOverride() } else { viewModel.requestOpenDiary() }
    }

    private func triggerOpenSettings() {
        if let onOpenSettingsOverride { onOpenSettingsOverride() } else { viewModel.requestOpenSettings() }
    }

    private func triggerOpenGraceAndMercy() {
        if let onOpenGraceAndMercyOverride {
            onOpenGraceAndMercyOverride()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingGraceAndMercy = true
            }
        }
    }
}

#Preview("My Path Profile — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { season in
        MyPathProfileView(viewModel: MyPathViewModel(season: season))
    }
}
