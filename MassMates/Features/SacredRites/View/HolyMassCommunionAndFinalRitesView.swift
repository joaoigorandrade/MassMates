import SwiftUI

struct HolyMassCommunionAndFinalRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            ourFatherAndPeaceSection
            hairlineDivider
            agnusDeiSection
            hairlineDivider
            thanksgivingAndDismissalSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var ourFatherAndPeaceSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Oração do Senhor (Pai Nosso)", posture: .standing)
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("TODOS")
                    .font(MassMatesFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("«Pai nosso que estais nos céus, santificado seja o vosso nome; venha a nós o vosso reino, seja feita a vossa vontade assim na terra como no céu. O pão nosso de cada dia nos dai hoje; perdoai-nos as nossas ofensas assim como nós perdoamos a quem nos tem ofendido; e não nos deixeis cair em tentação, mas livrai-nos do mal.»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(6)
            }
            peaceDialogueBlock
        }
    }

    private var peaceDialogueBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            dialogueTurnView(speaker: "Celebrante", text: "A paz do Senhor esteja sempre convosco.", isAssembly: false)
            dialogueTurnView(speaker: "Assembleia", text: "O amor de Cristo nos uniu.", isAssembly: true)
        }
    }

    private var agnusDeiSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Cordeiro de Deus", subtitle: "Fração do Pão")
            agnusDeiLinesBlock
            latinAgnusDeiBlock
            humilityPrayerBlock
        }
    }

    private var agnusDeiLinesBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            ForEach(Array(HolyMassRitesCatalog.agnusDeiLines.enumerated()), id: \.offset) { _, line in
                Text("\(Text(line.lead))\(Text(line.response).bold())")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(4)
            }
        }
    }

    private var latinAgnusDeiBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("LATIM")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("«Agnus Dei, qui tollis peccata mundi, miserere nobis... dona nobis pacem.»")
                .font(MassMatesFont.customScripture(size: 15, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var humilityPrayerBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("ORAÇÃO DE HUMILDADE • TODOS")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«Senhor, eu não sou digno de que entreis em minha morada, mas dizei uma palavra e serei salvo.»")
                .font(Font.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private var thanksgivingAndDismissalSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Ação de Graças & Silêncio", subtitle: "Pós-Comunhão")
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("ALMA DE CRISTO")
                    .font(MassMatesFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("«Alma de Cristo, santificai-me. Corpo de Cristo, salvai-me. Sangue de Cristo, inebriai-me. Água do lado de Cristo, lavai-me. Paixão de Cristo, confortai-me. Ó bom Jesus, ouvi-me...»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(6)
            }
            dialogueTurnView(speaker: "Celebrante", text: "Ide em paz e o Senhor vos acompanhe.", isAssembly: false)
            dialogueTurnView(speaker: "Assembleia", text: "Graças a Deus.", isAssembly: true)
        }
    }

    private func dialogueTurnView(speaker: String, text: String, isAssembly: Bool) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(speaker.replacingOccurrences(of: ":", with: "").uppercased())
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(text)
                .font(isAssembly ? Font.system(size: 19, weight: .semibold, design: .serif) : MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private func sectionHeader(title: String, subtitle: String? = nil, posture: LiturgicalPosture? = nil) -> some View {
        HStack {
            Text(title)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(MassMatesFont.caption)
                    .tracking(0.4)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            if let posture {
                Label(posture.rawValue, systemImage: posture.systemImage)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 2)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
            .padding(.vertical, MassMatesSpacing.xs)
    }
}

#Preview("Holy Mass Communion & Final Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassCommunionAndFinalRitesView()
    }
}
