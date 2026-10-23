import Navigation
import SwiftUI

struct SettingsAppearanceView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator
    private let viewModel: SettingsViewModel
    private let onBack: () -> Void

    // MARK: - Init
    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topNavigationArea
            ScrollView(showsIndicators: false) {
                VStack(spacing: MassMatesSpacing.md) {
                    themeSection.padding(.horizontal, MassMatesLayout.screenMargin)
                    appIconSection.padding(.horizontal, MassMatesLayout.screenMargin)
                    languageSection.padding(.horizontal, MassMatesLayout.screenMargin)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: handleBack) {
                    HStack(spacing: MassMatesSpacing.xxs) {
                        Image(systemName: "chevron.left").font(MassMatesFont.headline)
                        Text("Ajustes").font(MassMatesFont.callout)
                    }
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(minHeight: MassMatesLayout.minTapTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voltar")
                Spacer()
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)

            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Aparência e Liturgia").font(MassMatesFont.display).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Personalize seu recolhimento e idioma.").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.top, MassMatesSpacing.xs)
            .padding(.bottom, MassMatesSpacing.md)
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("TEMA").font(MassMatesFont.caption).tracking(0.6).foregroundStyle(MassMatesPalette.textSecondary)
            HStack(spacing: 4) {
                ForEach(AppThemeMode.allCases) { mode in
                    let isSelected = viewModel.selectedThemeMode == mode
                    Button { viewModel.selectThemeMode(mode) } label: {
                        Text(mode.displayName).font(MassMatesFont.callout).fontWeight(isSelected ? .semibold : .medium)
                            .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(isSelected ? MassMatesPalette.surface : Color.clear)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("ÍCONE DO APP").font(MassMatesFont.caption).tracking(0.6).foregroundStyle(MassMatesPalette.textSecondary)
            HStack(spacing: MassMatesSpacing.lg) {
                iconOption(icon: .classicLiturgical, label: "Verde comum", tint: theme.tint, bg: MassMatesPalette.bg)
                iconOption(icon: .ourLadyOfAparecida, label: "Ouro sagrado", tint: Theme(season: .white).tint, bg: theme.tintSoft)
                iconOption(icon: .stMichael, label: "Noite", tint: MassMatesPalette.textPrimary, bg: MassMatesPalette.surfaceMuted)
            }
            .frame(maxWidth: .infinity, alignment: .center).padding(.top, MassMatesSpacing.xs)
        }
    }

    private func iconOption(icon: SaintAppIconOption, label: String, tint: Color, bg: Color) -> some View {
        let isSelected = viewModel.activeAppIcon == icon
        return Button { viewModel.selectOrUnlockAppIcon(icon) } label: {
            VStack(spacing: MassMatesSpacing.xs) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14).fill(bg)
                        .overlay(Image(systemName: "cross.fill").font(MassMatesFont.title).foregroundStyle(tint))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: isSelected ? 2 : 1))
                        .frame(width: 56, height: 56)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(theme.tint)
                            .background(Circle().fill(MassMatesPalette.surface)).offset(x: 4, y: -4)
                    }
                }
                Text(label).font(MassMatesFont.caption).foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("IDIOMA").font(MassMatesFont.caption).tracking(0.6).foregroundStyle(MassMatesPalette.textSecondary).padding(.bottom, MassMatesSpacing.xs)
            hairline
            ForEach(AppLanguage.allCases) { lang in
                let isSelected = viewModel.selectedLanguage == lang
                Button { viewModel.selectLanguage(lang) } label: {
                    HStack {
                        Text(lang.displayName).font(MassMatesFont.body).foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                        Spacer()
                        ZStack {
                            Circle().stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1.5).frame(width: 20, height: 20)
                            if isSelected { Circle().fill(theme.tint).frame(width: 10, height: 10) }
                        }
                    }
                    .frame(minHeight: MassMatesLayout.minRowHeight)
                }
                .buttonStyle(.plain)
                hairline
            }
        }
    }

    private func handleBack() {
        onBack()
        if let navigator, navigator.canPop() {
            navigator.pop()
        }
    }

    private var hairline: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }
}

#Preview("Settings Appearance — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsAppearanceView(viewModel: SettingsViewModel(), onBack: {})
    }
}
