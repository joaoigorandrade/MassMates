import SwiftUI

struct HolyMassEucharisticAndFinalRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            offertorySection
            hairlineDivider
            prefaceSection
            hairlineDivider
            sanctusSection
            hairlineDivider
            consecrationSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var offertorySection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Apresentação das Oferendas", posture: .seated)
            ForEach(HolyMassRitesCatalog.offertoryTurns) { turn in
                dialogueTurnView(turn: turn)
            }
        }
    }

    private var prefaceSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Diálogo do Prefácio", posture: .standing)
            ForEach(HolyMassRitesCatalog.prefaceDialogueTurns) { turn in
                dialogueTurnView(turn: turn)
            }
        }
    }

    private var sanctusSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Santo", posture: .kneeling)
            dialogueTurnView(turn: MassDialogueTurn(
                id: "sanc-1",
                speaker: "Sacerdote",
                text: "Santo, Santo, Santo, Senhor Deus do universo. O céu e a terra proclamam a vossa glória. Hosana nas alturas!",
                latinText: "Sanctus, Sanctus, Sanctus Dóminus Deus Sábaoth...",
                isAssembly: false
            ))
            dialogueTurnView(turn: MassDialogueTurn(
                id: "sanc-2",
                speaker: "Assembleia",
                text: "Bendito o que vem em nome do Senhor. Hosana nas alturas!",
                latinText: "Benedíctus qui venit in nómine Dómini. Hosánna in excélsis.",
                isAssembly: true
            ))
            hairlineDivider
            latinSanctusBlock
        }
    }

    private var latinSanctusBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("LATIM")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text("Sanctus, Sanctus, Sanctus Dóminus Deus Sábaoth. Pleni sunt cæli et terra glória tua. Hosánna in excélsis. Benedíctus qui venit in nómine Dómini. Hosánna in excélsis.")
                .font(MassMatesFont.customScripture(size: 17, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineSpacing(5)
        }
    }

    private var consecrationSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Consagração Eucarística", posture: .kneeling)
            consecrationWordsBlock
            acclamationMyLordAndMyGod
        }
    }

    private var consecrationWordsBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("MOMENTO SOLENE DE ADORAÇÃO SILENCIOSA")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«TOMAI, TODOS, E COMEI: ISTO É O MEU CORPO, QUE SERÁ ENTREGUE POR VÓS.»")
                .font(Font.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            Text("«TOMAI, TODOS, E BEBEI: ESTE É O CÁLICE DO MEU SANGUE, O SANGUE DA NOVA E ETERNA ALIANÇA... FAZEI ISTO EM MEMÓRIA DE MIM.»")
                .font(Font.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private var acclamationMyLordAndMyGod: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("ACLAMAÇÃO • TODOS")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(theme.tint)
            Text("«Meu Senhor e meu Deus!»")
                .font(Font.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(theme.tint)
        }
    }

    private func dialogueTurnView(turn: MassDialogueTurn) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(turn.speaker.replacingOccurrences(of: ":", with: "").uppercased())
                .font(MassMatesFont.caption).tracking(0.5).foregroundStyle(MassMatesPalette.textSecondary)
            Text(turn.text)
                .font(turn.isAssembly ? Font.system(size: 19, weight: .semibold, design: .serif) : MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary).lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            if let latin = turn.latinText {
                Text(latin)
                    .font(MassMatesFont.customScripture(size: 14, italic: true))
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(title: String, posture: LiturgicalPosture? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: MassMatesSpacing.xs)
            if let posture {
                Label(posture.rawValue, systemImage: posture.systemImage)
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    .padding(.horizontal, MassMatesSpacing.xs).padding(.vertical, 2)
                    .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                    .fixedSize(horizontal: true, vertical: false)
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

#Preview("Holy Mass Eucharistic Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassEucharisticAndFinalRitesView()
    }
}
