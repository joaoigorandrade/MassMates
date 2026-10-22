import SwiftUI

struct MyPathGraceAndMercyView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let canClaimStreakMercy: Bool
    private let onBack: () -> Void
    private let onClaimStreakMercy: () -> Void
    private let onUnlockSaintTheme: () -> Void

    // MARK: - Init
    init(
        canClaimStreakMercy: Bool = true,
        onBack: @escaping () -> Void = {},
        onClaimStreakMercy: @escaping () -> Void = {},
        onUnlockSaintTheme: @escaping () -> Void = {}
    ) {
        self.canClaimStreakMercy = canClaimStreakMercy
        self.onBack = onBack
        self.onClaimStreakMercy = onClaimStreakMercy
        self.onUnlockSaintTheme = onUnlockSaintTheme
    }

    nonisolated static func == (lhs: MyPathGraceAndMercyView, rhs: MyPathGraceAndMercyView) -> Bool {
        lhs.canClaimStreakMercy == rhs.canClaimStreakMercy
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            titleSection
            optionsSection
            contemplativeCard
            Spacer()
            footerCaption
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        Button(action: onBack) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text("Meu Caminho")
                    .font(MassMatesFont.callout)
            }
            .foregroundStyle(MassMatesPalette.textSecondary)
            .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Graça")
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Pequenos gestos de restauração e contemplação.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.top, MassMatesSpacing.xs)
        .padding(.bottom, MassMatesSpacing.lg)
    }

    private var optionsSection: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            streakMercyRow
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            saintThemesRow
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
    }

    private var streakMercyRow: some View {
        optionRow(
            icon: "flame.fill",
            iconBg: theme.tintSoft,
            iconTint: theme.tint,
            title: "Misericórdia da sequência",
            subtitle: "Repara 1 dia perdido · 1 por mês",
            action: onClaimStreakMercy
        )
    }

    private var saintThemesRow: some View {
        optionRow(
            icon: "sparkles",
            iconBg: MassMatesPalette.surfaceMuted,
            iconTint: MassMatesPalette.textSecondary,
            title: "Temas de Santos",
            subtitle: "Ícone e tema por 7 dias",
            action: onUnlockSaintTheme
        )
    }

    private func optionRow(
        icon: String,
        iconBg: Color,
        iconTint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: MassMatesSpacing.sm) {
            ZStack {
                Circle().fill(iconBg).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconTint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button(action: action) {
                Text("Assistir vídeo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.tint)
                    .padding(.vertical, MassMatesSpacing.xs)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 72)
    }

    private var contemplativeCard: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 16))
                .foregroundStyle(theme.tint)
                .padding(.top, 2)
            Text("\"A graça é a respiração da alma que descansa no sagrado.\"")
                .font(MassMatesFont.customScripture(size: 14, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineSpacing(4)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
        .padding(.top, MassMatesSpacing.xl)
    }

    private var footerCaption: some View {
        Text("Opcional. Vídeos patrocinados mantêm o app gratuito.")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, MassMatesSpacing.md)
    }
}

typealias MyPathRuleOfLifeDistributionCardView = MyPathGraceAndMercyView

#Preview("Grace & Mercy — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathGraceAndMercyView()
    }
}
