import Navigation
import SwiftUI

struct SacredRitesHomeView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                headerView
                ritesSection
                spiritualLifeSection
            }
            .padding(MassMatesLayout.screenMargin)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerView: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("RITOS SAGRADOS")
                .font(MassMatesFont.caption)
                .tracking(0.8)
                .foregroundStyle(theme.tint)
            Text("Liturgia & Oração")
                .font(MassMatesFont.title)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Guia prático para os sacramentos e a oração contemplativa da Igreja.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var ritesSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("SACRAMENTOS E CELEBRAÇÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)

            riteCard(
                title: "Santa Missa & Guia dos Ritos",
                subtitle: "Acompanhe as 4 partes da celebração, posturas corporais e orações.",
                icon: "cross.fill",
                action: { navigator?.present(.holyMassGuide(season: theme.season)) }
            )

            riteCard(
                title: "Preparação para a Confissão",
                subtitle: "Exame dos Dez Mandamentos com notas confidenciais e Modo Confessionário.",
                icon: "lock.shield.fill",
                action: { navigator?.present(.confessionPreparation(season: theme.season)) }
            )

            riteCard(
                title: "Exame de Consciência da Noite",
                subtitle: "5 passos da oração inaciana de revisão diária, gratidão e bênção da noite.",
                icon: "moon.stars.fill",
                action: { navigator?.present(.nightlyExamen(season: theme.season)) }
            )
        }
    }

    private var spiritualLifeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("REGRA & CONFIGURAÇÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)

            riteCard(
                title: "Regra de Vida e Práticas",
                subtitle: "Personalize suas práticas espirituais diárias e semanais.",
                icon: "slider.horizontal.3",
                action: { navigator?.present(.ruleOfLife(season: theme.season)) }
            )

            riteCard(
                title: "Segurança e Backup do Diário",
                subtitle: "Criptografia local e opções de proteção dos registros espirituais.",
                icon: "key.fill",
                action: { navigator?.present(.settings(season: theme.season)) }
            )
        }
    }

    private func riteCard(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            MassMatesCard {
                HStack(alignment: .top, spacing: MassMatesSpacing.md) {
                    Image(systemName: icon)
                        .font(MassMatesFont.title)
                        .foregroundStyle(theme.tint)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(MassMatesFont.headline)
                            .foregroundStyle(MassMatesPalette.textPrimary)
                        Text(subtitle)
                            .font(MassMatesFont.caption)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Sacred Rites Home — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SacredRitesHomeView()
    }
}
