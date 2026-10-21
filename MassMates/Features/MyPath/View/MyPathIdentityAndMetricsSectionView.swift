import SwiftUI

struct MyPathIdentityAndMetricsSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let activeStreakDays: Int
    private let onOpenSettings: () -> Void

    // MARK: - Init
    init(activeStreakDays: Int, onOpenSettings: @escaping () -> Void) {
        self.activeStreakDays = activeStreakDays
        self.onOpenSettings = onOpenSettings
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            topNavigationBar
            identityHeaderSection
            devotionalMetricsGrid
        }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Text("Perfil & Histórico").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: 4) {
                    Circle().fill(theme.tint).frame(width: 6, height: 6)
                    Text(theme.season.defaultSeasonName.uppercased()).font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, 2)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            Spacer()
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                    .background(MassMatesPalette.surface)
                    .clipShape(.circle)
                    .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Configurações")
        }
    }

    private var identityHeaderSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            avatarWithHaloView
            Text("Maria Clara de Jesus").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            Label("Paróquia Sant'Ana — São Paulo, SP", systemImage: "mappin.and.ellipse")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, 4)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            Text("• Em caminhada comunitária há 142 dias")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            editRuleOfLifeButton
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarWithHaloView: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(theme.tintSoft).frame(width: 96, height: 96)
                Circle().fill(MassMatesPalette.surfaceMuted).frame(width: 88, height: 88)
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().frame(width: 84, height: 84).foregroundStyle(theme.tint)
            }
            Image(systemName: "building.columns.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.onTint)
                .frame(width: 24, height: 24)
                .background(theme.tint)
                .clipShape(.circle)
                .overlay(Circle().stroke(MassMatesPalette.surface, lineWidth: 2))
        }
    }

    private var editRuleOfLifeButton: some View {
        Button(action: onOpenSettings) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "book.pages").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                Text("Editar Regra de Vida").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
                Image(systemName: "chevron.right").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
            .padding(.horizontal, MassMatesSpacing.md)
            .padding(.vertical, MassMatesSpacing.xs)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private var devotionalMetricsGrid: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            currentConsistencyCard
            HStack(spacing: MassMatesSpacing.xs) {
                halfMetricCard(icon: "checkmark.seal.fill", iconTint: theme.tint, iconBg: theme.tintSoft, label: "PRÁTICAS TOTAIS", value: "384", subtitle: "leituras & orações")
                halfMetricCard(icon: "person.2.fill", iconTint: MassMatesPalette.textSecondary, iconBg: MassMatesPalette.surfaceMuted, label: "FRATERNIDADE", value: "2 Grupos", subtitle: "1 Anjo servido hoje")
            }
        }
    }

    private var currentConsistencyCard: some View {
        MassMatesCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONSTÂNCIA ATUAL").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary).tracking(0.5)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(activeStreakDays)").font(MassMatesFont.numeral).foregroundStyle(theme.tint)
                        Text("dias em oração contínua").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Label("Mais um dia renovado na graça", systemImage: "heart.fill")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
                Spacer()
                ZStack {
                    Circle().stroke(MassMatesPalette.line, lineWidth: 4)
                    Circle().trim(from: 0, to: 0.89).stroke(theme.tint, style: StrokeStyle(lineWidth: 4.5, lineCap: .round)).rotationEffect(.degrees(-90))
                    Image(systemName: "leaf.fill").font(MassMatesFont.headline).foregroundStyle(theme.tint)
                }
                .frame(width: 64, height: 64)
            }
        }
    }

    private func halfMetricCard(icon: String, iconTint: Color, iconBg: Color, label: String, value: String, subtitle: String) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Image(systemName: icon).font(MassMatesFont.callout).foregroundStyle(iconTint).frame(width: 32, height: 32).background(iconBg).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                Text(label).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                Text(value).font(MassMatesFont.title).foregroundStyle(MassMatesPalette.textPrimary)
                Text(subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }
}

#Preview("My Path Identity & Metrics — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathIdentityAndMetricsSectionView(activeStreakDays: 28, onOpenSettings: {})
    }
}
