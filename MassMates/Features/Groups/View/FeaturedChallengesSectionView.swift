import SwiftUI

struct FeaturedChallengesSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let challenges: [FeaturedChallenge]
    private let onJoinChallenge: (String) -> Void
    private let onOpenGroup: (CommunityGroup) -> Void
    private var redTheme: Theme { Theme(season: .red) }
    private var purpleTheme: Theme { Theme(season: .purple) }

    // MARK: - Init
    init(
        challenges: [FeaturedChallenge],
        onJoinChallenge: @escaping (String) -> Void,
        onOpenGroup: @escaping (CommunityGroup) -> Void
    ) {
        self.challenges = challenges
        self.onJoinChallenge = onJoinChallenge
        self.onOpenGroup = onOpenGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            seasonalChallengeSection
            archdioceseShowcaseSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var seasonalChallengeSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Label("Desafio Sazonal Ativo", systemImage: "flame.fill")
                    .font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("TEMPO FORTE").font(MassMatesFont.caption).foregroundStyle(redTheme.tint)
            }
            saintMichaelHeroCard
        }
    }

    private var saintMichaelHeroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            saintMichaelBanner
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Quaresma de São Miguel Arcanjo")
                    .font(MassMatesFont.title).foregroundStyle(MassMatesPalette.textPrimary)
                Text("15 de Agosto a 29 de Setembro • Combate e vigilância diária")
                    .font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
                saintMichaelProgressBlock
                saintMichaelQuoteBox
                saintMichaelActionRow
            }
            .padding(MassMatesSpacing.md)
        }
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var saintMichaelBanner: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                redTheme.tintSoft
                Image(systemName: "shield.checkered").font(MassMatesFont.display).foregroundStyle(redTheme.tint.opacity(0.35))
            }
            .frame(height: 104)
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "hourglass").font(MassMatesFont.caption).foregroundStyle(redTheme.tint)
                Text("Dia 4 de 40").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
            }
            .padding(.horizontal, MassMatesSpacing.xs).padding(.vertical, MassMatesSpacing.xxs)
            .background(MassMatesPalette.surface).clipShape(Capsule()).padding(MassMatesSpacing.sm)
        }
    }

    private var saintMichaelProgressBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Label("142 participantes paroquiais", systemImage: "person.3.fill")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("10% percorrido").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
            }
            MassMatesProgressBar(progress: 0.10).environment(\.liturgicalTheme, redTheme)
        }
    }

    private var saintMichaelQuoteBox: some View {
        Text("“Quem como Deus? Ninguém como Deus.”")
            .font(MassMatesFont.customScripture(size: 15, italic: true))
            .foregroundStyle(MassMatesPalette.textPrimary)
            .frame(maxWidth: .infinity).padding(MassMatesSpacing.sm)
            .background(redTheme.tintSoft).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var saintMichaelActionRow: some View {
        HStack {
            Button { onOpenGroup(CommunitySampleData.youthChallenge) } label: {
                Label("Fazer Check-in do Dia", systemImage: "checkmark")
                    .font(MassMatesFont.caption).foregroundStyle(redTheme.onTint)
                    .padding(.horizontal, MassMatesSpacing.md).frame(minHeight: 40)
                    .background(redTheme.tint).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            }
            .buttonStyle(.plain)
            Spacer()
            Button { onOpenGroup(CommunitySampleData.youthChallenge) } label: {
                HStack(spacing: 2) {
                    Text("Ver Diário")
                    Image(systemName: "chevron.right")
                }
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var archdioceseShowcaseSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Vitrine da Arquidiocese").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("Descoberta Comunitária").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            showcaseCard(
                eyebrow: "INSCRIÇÕES ABERTAS",
                title: "Novena de Nossa Senhora Aparecida",
                subtitle: "Início solene em 03 de Outubro. Oração oficial da Padroeira.",
                icon: "cross.fill",
                cta: "Participar",
                accent: theme,
                challengeId: challenges.first?.id ?? "chal-aparecida"
            )
            showcaseCard(
                eyebrow: "ORAÇÃO DA MANHÃ",
                title: "Jovens Sentinelas da Manhã",
                subtitle: "Lectio Divina comunitária diária às 05h45.",
                icon: "sunrise.fill",
                cta: "Conhecer",
                accent: purpleTheme,
                challengeId: challenges.dropFirst().first?.id ?? "chal-quaresma-jovem"
            )
        }
    }

    private func showcaseCard(
        eyebrow: String, title: String, subtitle: String, icon: String, cta: String, accent: Theme, challengeId: String
    ) -> some View {
        MassMatesCard {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: icon)
                    .font(MassMatesFont.title).foregroundStyle(accent.tint)
                    .frame(width: 48, height: 48).background(accent.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow).font(MassMatesFont.caption).foregroundStyle(accent.tint)
                    Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Text(subtitle).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                Button(cta) { onJoinChallenge(challengeId) }
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
                    .padding(.horizontal, MassMatesSpacing.sm).frame(minHeight: 36)
                    .background(MassMatesPalette.surfaceMuted).clipShape(Capsule()).buttonStyle(.plain)
            }
        }
    }
}

#Preview("Featured Challenges — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        FeaturedChallengesSectionView(
            challenges: LocalCommunityGroupsService().featuredChallenges(),
            onJoinChallenge: { _ in },
            onOpenGroup: { _ in }
        )
    }
}
