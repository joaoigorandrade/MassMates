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
                dialogueTurnView(speaker: turn.speaker, text: turn.text, isAssembly: turn.isAssembly)
            }
        }
    }

    private var sanctusSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Santo", posture: .kneeling)
            dialogueTurnView(
                speaker: "Sacerdote",
                text: "Santo, Santo, Santo, Senhor Deus do universo. O céu e a terra proclamam a vossa glória. Hosana nas alturas!",
                isAssembly: false
            )
            dialogueTurnView(
                speaker: "Assembleia",
                text: "Bendito o que vem em nome do Senhor. Hosana nas alturas!",
                isAssembly: true
            )
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

    private func sectionHeader(title: String, posture: LiturgicalPosture? = nil) -> some View {
        HStack {
            Text(title)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
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

#Preview("Holy Mass Eucharistic Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassEucharisticAndFinalRitesView()
    }
}
