import Navigation
import SwiftUI

struct MyPathGraceAndMercyView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let canClaimStreakMercy: Bool
    private let activeSaintIcon: SaintAppIconOption?
    private let unlockedSaintIcons: Set<SaintAppIconOption>
    private let onBack: () -> Void
    private let onClaimStreakMercy: () -> Void
    private let onSelectSaintTheme: (SaintAppIconOption) -> Void

    // MARK: - Init
    init(
        canClaimStreakMercy: Bool = true,
        activeSaintIcon: SaintAppIconOption? = nil,
        unlockedSaintIcons: Set<SaintAppIconOption> = [],
        onBack: @escaping () -> Void = {},
        onClaimStreakMercy: @escaping () -> Void = {},
        onSelectSaintTheme: @escaping (SaintAppIconOption) -> Void = { _ in },
        onUnlockSaintTheme: @escaping () -> Void = {}
    ) {
        self.canClaimStreakMercy = canClaimStreakMercy
        self.activeSaintIcon = activeSaintIcon
        self.unlockedSaintIcons = unlockedSaintIcons
        self.onBack = onBack
        self.onClaimStreakMercy = onClaimStreakMercy
        self.onSelectSaintTheme = { icon in onSelectSaintTheme(icon); onUnlockSaintTheme() }
    }

    nonisolated static func == (lhs: MyPathGraceAndMercyView, rhs: MyPathGraceAndMercyView) -> Bool {
        lhs.canClaimStreakMercy == rhs.canClaimStreakMercy &&
        lhs.activeSaintIcon == rhs.activeSaintIcon &&
        lhs.unlockedSaintIcons == rhs.unlockedSaintIcons
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerBar
                titleSection
                optionsSection
                contemplativeCard
                footerCaption
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.bottom, 104)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerBar: some View {
        Button(action: handleBack) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                Text("Voltar").font(MassMatesFont.callout)
            }
            .foregroundStyle(MassMatesPalette.textSecondary)
            .frame(minHeight: MassMatesLayout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel("Voltar")
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Graça & Misericórdia").font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            Text("Pequenos gestos de restauração e contemplação.").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.top, MassMatesSpacing.xs).padding(.bottom, MassMatesSpacing.md)
    }

    private var optionsSection: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            streakMercySection
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            saintThemesSection
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
    }

    private var streakMercySection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.sm) {
                ZStack {
                    Circle().fill(theme.tintSoft).frame(width: 40, height: 40)
                    Image(systemName: "flame.fill").font(.system(size: 18)).foregroundStyle(theme.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Graça de Fidelidade").font(.system(size: 16, weight: .semibold)).foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Repara 1 dia perdido · 1 por mês").font(.system(size: 13)).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
            }
            Button(action: onClaimStreakMercy) {
                HStack(spacing: MassMatesSpacing.xs) {
                    Image(systemName: canClaimStreakMercy ? "sparkles" : "checkmark.circle.fill")
                    Text(canClaimStreakMercy ? "Reivindicar Graça de Fidelidade" : "Graça Já Utilizada Este Mês")
                }
                .font(MassMatesFont.callout.weight(.semibold))
                .foregroundStyle(canClaimStreakMercy ? theme.onTint : MassMatesPalette.textTertiary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(canClaimStreakMercy ? theme.tint : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain).disabled(!canClaimStreakMercy).accessibilityLabel("Reivindicar Graça de Fidelidade")
        }
        .padding(.vertical, MassMatesSpacing.sm)
    }

    private var saintThemesSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Temas de Santos").font(.system(size: 16, weight: .semibold)).foregroundStyle(MassMatesPalette.textPrimary)
            Text("Selecione o ícone sagrado do seu caminho").font(.system(size: 13)).foregroundStyle(MassMatesPalette.textSecondary)
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach([SaintAppIconOption.stTherese, .stMichael, .ourLadyOfAparecida, .stJoseph], id: \.self) { saint in
                    saintThemeButton(saint)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, MassMatesSpacing.sm)
    }

    private func saintThemeButton(_ saint: SaintAppIconOption) -> some View {
        let isSelected = activeSaintIcon == saint
        return Button { onSelectSaintTheme(saint) } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted).frame(width: 44, height: 44)
                    Image(systemName: saint.systemImage).font(.system(size: 18)).foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                }
                Text(saint.title).font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel(saint.title)
    }

    private var contemplativeCard: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "leaf.fill").font(.system(size: 16)).foregroundStyle(theme.tint).padding(.top, 2)
            Text("\"A graça é a respiração da alma que descansa no sagrado.\"")
                .font(MassMatesFont.customScripture(size: 14, italic: true)).foregroundStyle(MassMatesPalette.textSecondary).lineSpacing(4)
        }
        .padding(MassMatesSpacing.md).frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.photo).stroke(MassMatesPalette.line, lineWidth: 1))
        .padding(.top, MassMatesSpacing.lg)
    }

    private var footerCaption: some View {
        Text("Opcional. Vídeos patrocinados mantêm o app gratuito.")
            .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            .frame(maxWidth: .infinity).padding(.top, MassMatesSpacing.md)
    }

    private func handleBack() {
        onBack()
    }
}
