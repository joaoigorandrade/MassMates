import SwiftUI

struct HolyMassWordRitesView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    nonisolated static func == (lhs: HolyMassWordRitesView, rhs: HolyMassWordRitesView) -> Bool {
        true
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            firstReadingSection
            hairlineDivider
            psalmSection
            hairlineDivider
            secondReadingSection
            hairlineDivider
            holyGospelSection
            hairlineDivider
            creedSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var firstReadingSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader(title: "Primeira Leitura", citation: "Sabedoria 7, 7-11", posture: .seated)
            Text("«Supliquei e foi-me dada a prudência; invoquei a Deus e veio a mim o espírito da sabedoria. Preferi a sabedoria aos cetros e tronos e tive as riquezas em nada comparadas a ela...»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            acclamationBlock(lead: "Palavra do Senhor.", response: "Graças a Deus.")
        }
    }

    private var psalmSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Salmo Responsorial 89 (90)")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("RESPOSTA DE TODOS")
                    .font(MassMatesFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Text("«Saciai-nos, ó Senhor, com vossa graça, e exultaremos de alegria!»")
                    .font(Font.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(6)
            }
            Text("«Ensinai-nos a contar os nossos dias, para que alcancemos um coração sábio. Voltai-vos, Senhor! Até quando? Tende piedade de vossos servos!»")
                .font(MassMatesFont.customScripture(size: 17, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineSpacing(5)
        }
    }

    private var secondReadingSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader(title: "Segunda Leitura", citation: "Hebreus 4, 12-13")
            Text("«A Palavra de Deus é viva, eficaz e mais cortante do que qualquer espada de dois gumes... Nenhuma criatura fica oculta aos olhos de Deus; tudo está descoberto perante Ele.»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            acclamationBlock(lead: "Palavra do Senhor.", response: "Graças a Deus.")
        }
    }

    private var holyGospelSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader(title: "Santo Evangelho", citation: "São Marcos 10, 17-30", posture: .standing)
            acclamationAlleluia
            ForEach(HolyMassRitesCatalog.gospelDialogueTurns) { turn in
                dialogueTurnView(turn: turn)
            }
            Text("«Naquele tempo, Jesus se pôs a caminho, quando um homem correu ao seu encontro, ajoelhou-se e perguntou: “Bom Mestre, que devo fazer para ganhar a vida eterna?” Jesus respondeu: “Por que me chamas de bom? Só Deus é bom... Só te falta uma coisa: vai, vende tudo o que tens e dá aos pobres, e terás um tesouro no céu. Depois, vem e segue-me!”»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            acclamationBlock(lead: "Palavra da Salvação.", response: "Glória a vós, Senhor.")
        }
    }

    private var acclamationAlleluia: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("ACLAMAÇÃO AO EVANGELHO")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«Aleluia, Aleluia, Aleluia!»")
                .font(Font.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(theme.tint)
        }
    }

    private var creedSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader(title: "Profissão de Fé (Credo)", citation: "Símbolo dos Apóstolos")
            Text("«Creio em Deus Pai todo-poderoso, Criador do céu e da terra. E em Jesus Cristo, seu único Filho, nosso Senhor, que foi concebido pelo poder do Espírito Santo, nasceu da Virgem Maria... Ressuscitou ao terceiro dia; subiu aos céus; está sentado à direita de Deus Pai todo-poderoso...»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private func acclamationBlock(lead: String, response: String) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(lead)
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(response)
                .font(Font.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    private func dialogueTurnView(turn: MassDialogueTurn) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(turn.speaker.replacingOccurrences(of: ":", with: "").uppercased())
                .font(MassMatesFont.caption).tracking(0.5).foregroundStyle(MassMatesPalette.textSecondary)
            Text(turn.text)
                .font(turn.isAssembly ? Font.system(size: 19, weight: .semibold, design: .serif) : MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary).fixedSize(horizontal: false, vertical: true)
            if let latin = turn.latinText {
                Text(latin)
                    .font(MassMatesFont.customScripture(size: 14, italic: true))
                    .foregroundStyle(MassMatesPalette.textTertiary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(title: String, citation: String? = nil, posture: LiturgicalPosture? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                if let citation {
                    Text(citation).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
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

#Preview("Holy Mass Word Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassWordRitesView()
    }
}
