import SwiftUI

struct HolyMassCommunionAndFinalRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            ourFatherAndPeaceCard
            agnusDeiCard
            silentThanksgivingCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var ourFatherAndPeaceCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    cardTitleBar("Oração do Senhor (Pai Nosso)")
                    Spacer()
                    Label("De pé", systemImage: "figure.stand")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .padding(.horizontal, MassMatesSpacing.xs)
                        .padding(.vertical, 2)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                }
                Text("«Pai nosso que estais nos céus, santificado seja o vosso nome; venha a nós o vosso reino, seja feita a vossa vontade assim na terra como no céu. O pão nosso de cada dia nos dai hoje; perdoai-nos as nossas ofensas assim como nós perdoamos a quem nos tem ofendido; e não nos deixeis cair em tentação, mas livrai-nos do mal.»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                peaceDialogueBox
            }
        }
    }

    private var peaceDialogueBox: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            HStack {
                Text("Celebrante:").foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("A paz do Senhor esteja sempre convosco.").foregroundStyle(MassMatesPalette.textPrimary)
            }
            HStack {
                Text("Todos:")
                Spacer()
                Text("O amor de Cristo nos uniu.")
            }
            .foregroundStyle(theme.tint)
        }
        .font(MassMatesFont.callout)
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var agnusDeiCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    Text("Cordeiro de Deus").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text("Fração do Pão").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                agnusDeiLinesBox
                humilityPrayerBox
            }
        }
    }

    private var agnusDeiLinesBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            ForEach(Array(HolyMassRitesCatalog.agnusDeiLines.enumerated()), id: \.offset) { _, line in
                Text(line.lead + line.response)
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var humilityPrayerBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("ORAÇÃO DE HUMILDADE • TODOS").font(MassMatesFont.caption).foregroundStyle(theme.tint)
            Text("«Senhor, eu não sou digno de que entreis em minha morada, mas dizei uma palavra e serei salvo.»")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var silentThanksgivingCard: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(theme.tint)
                .frame(width: 40, height: 40)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            Text("Ação de Graças & Silêncio").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            Text("«Alma de Cristo, santificai-me. Corpo de Cristo, salvai-me. Sangue de Cristo, inebriai-me. Água do lado de Cristo, lavai-me. Paixão de Cristo, confortai-me. Ó bom Jesus, ouvi-me...»")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private func cardTitleBar(_ title: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            RoundedRectangle(cornerRadius: 3).fill(theme.tint).frame(width: 6, height: 16)
            Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}

#Preview("Holy Mass Communion & Final Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassCommunionAndFinalRitesView()
    }
}
