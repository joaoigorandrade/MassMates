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
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerSection
                statusBanner
                ConsistencyHeatmapCardView(
                    days: viewModel.heatmapDays,
                    activeStreakDays: viewModel.milestones.activeStreakDays,
                    canClaimStreakMercy: viewModel.milestones.canClaimStreakMercyThisMonth,
                    onClaimStreakMercy: { _ = viewModel.claimStreakMercy() }
                )
                milestonesCard
                saintIconsCard
                widgetAndQuickShortcutsCard
                navigationFooterButtons
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.lg)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Vida Interior • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Meu Caminho")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            Spacer()
            Button(action: triggerOpenSettings) {
                Image(systemName: "gearshape")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                    .background(MassMatesPalette.surface)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
        }
    }

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

    private var milestonesCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Marcos Espirituais")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: MassMatesSpacing.sm) {
                    milestoneStat(value: "\(viewModel.milestones.rosariesPrayed)", label: "Terços")
                    milestoneStat(value: "\(viewModel.milestones.massesAttended)", label: "Missas")
                    milestoneStat(value: "\(viewModel.milestones.mentalPrayerHours)h", label: "Oração Mental")
                }
            }
        }
    }

    private func milestoneStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(value).font(MassMatesFont.numeral).foregroundStyle(theme.tint)
            Text(label).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var saintIconsCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Ícones de Santos Padroeiros")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                ForEach(SaintAppIconOption.allCases) { icon in
                    saintIconRow(icon)
                }
            }
        }
    }

    private func saintIconRow(_ icon: SaintAppIconOption) -> some View {
        let isUnlocked = viewModel.milestones.unlockedSaintIcons.contains(icon)
        let isActive = viewModel.milestones.activeAppIcon == icon
        return Button { viewModel.unlockOrSelectSaintIcon(icon) } label: {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: icon.systemImage)
                    .foregroundStyle(isActive ? theme.tint : MassMatesPalette.textSecondary)
                Text(icon.title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(isActive ? "Ativo" : (isUnlocked ? "Usar" : "Vídeo de Apoio"))
                    .font(MassMatesFont.caption)
                    .foregroundStyle(isActive ? theme.tint : MassMatesPalette.textSecondary)
            }
            .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var widgetAndQuickShortcutsCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Widgets e Atalhos Rápidos (Tela Inicial / Bloqueio)")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                MassMatesProgressBar(progress: viewModel.widgetSnapshot.progressRatio)
                HStack(spacing: MassMatesSpacing.xs) {
                    ForEach(viewModel.widgetSnapshot.quickPractices) { practice in
                        MassMatesSecondaryButton(title: practice.title, systemImage: practice.systemImage) {
                            viewModel.triggerQuickWidgetCheckIn(practice)
                        }
                    }
                }
            }
        }
    }

    private var navigationFooterButtons: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            MassMatesPrimaryButton(title: "Abrir Diário Espiritual Privado", systemImage: "lock.shield", action: triggerOpenDiary)
            MassMatesSecondaryButton(title: "Lembretes do Angelus e Configurações", systemImage: "bell.badge", action: triggerOpenSettings)
        }
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
