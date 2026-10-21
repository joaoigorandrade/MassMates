import SwiftUI

struct HolyMassWordRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            firstReadingCard
            responsorialPsalmCard
            secondReadingCard
            holyGospelCard
            creedCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var firstReadingCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    cardTitleBar("Primeira Leitura")
                    Spacer()
                    Label("Sentados", systemImage: "chair.lounge")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .padding(.horizontal, MassMatesSpacing.xs)
                        .padding(.vertical, 2)
                        .background(MassMatesPalette.surfaceMuted)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                }
                Label("Sabedoria 7, 7-11", systemImage: "bookmark.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.tint)
                Text("«Supliquei e foi-me dada a prudência; invoquei a Deus e veio a mim o espírito da sabedoria. Preferi a sabedoria aos cetros e tronos e tive as riquezas em nada comparadas a ela...»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                acclamationFooterRow(lead: "Palavra do Senhor.", response: "Todos: Graças a Deus.")
            }
        }
    }

    private var responsorialPsalmCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Label("Salmo Responsorial 89 (90)", systemImage: "music.note")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("Meditação").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("RESPOSTA DE TODOS").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                Text("«Saciai-nos, ó Senhor, com vossa graça, e exultaremos de alegria!»")
                    .font(MassMatesFont.scriptureEmphasis)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            .padding(MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            Text("«Ensinai-nos a contar os nossos dias, para que alcancemos um coração sábio. Voltai-vos, Senhor! Até quando? Tende piedade de vossos servos!»")
                .font(MassMatesFont.customScripture(size: 15, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var secondReadingCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    cardTitleBar("Segunda Leitura")
                    Spacer()
                    Text("Hebreus 4, 12-13").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Text("«A Palavra de Deus é viva, eficaz e mais cortante do que qualquer espada de dois gumes... Nenhuma criatura fica oculta aos olhos de Deus; tudo está descoberto perante Ele.»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                acclamationFooterRow(lead: "Palavra do Senhor.", response: "Todos: Graças a Deus.")
            }
        }
    }

    private var holyGospelCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                gospelHeaderAndAcclamation
                ForEach(HolyMassRitesCatalog.gospelDialogueTurns) { turn in
                    acclamationFooterRow(lead: turn.speaker, response: turn.text, isAssembly: turn.isAssembly)
                }
                gospelBodyBox
                acclamationFooterRow(lead: "Palavra da Salvação.", response: "Todos: Glória a vós, Senhor.")
            }
        }
    }

    private var gospelHeaderAndAcclamation: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                cardTitleBar("Santo Evangelho")
                Spacer()
                Label("De pé", systemImage: "figure.stand")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 2)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            HStack {
                Text("Aclamação:").font(MassMatesFont.callout).foregroundStyle(theme.tint)
                Spacer()
                Text("«Aleluia, Aleluia, Aleluia!»").font(MassMatesFont.scriptureEmphasis).foregroundStyle(theme.tint)
            }
            .padding(MassMatesSpacing.xs)
            .background(theme.tintSoft)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
    }

    private var gospelBodyBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("SÃO MARCOS 10, 17-30")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«Naquele tempo, Jesus se pôs a caminho, quando um homem correu ao seu encontro, ajoelhou-se e perguntou: “Bom Mestre, que devo fazer para ganhar a vida eterna?” Jesus respondeu: “Por que me chamas de bom? Só Deus é bom... Só te falta uma coisa: vai, vende tudo o que tens e dá aos pobres, e terás um tesouro no céu. Depois, vem e segue-me!”»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var creedCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text("Profissão de Fé (Credo)").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text("Símbolo dos Apóstolos").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Text("«Creio em Deus Pai todo-poderoso, Criador do céu e da terra. E em Jesus Cristo, seu único Filho, nosso Senhor, que foi concebido pelo poder do Espírito Santo, nasceu da Virgem Maria... Ressuscitou ao terceiro dia; subiu aos céus; está sentado à direita de Deus Pai todo-poderoso...»")
                    .font(MassMatesFont.scriptureEmphasis)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
    }

    private func acclamationFooterRow(lead: String, response: String, isAssembly: Bool = false) -> some View {
        HStack {
            Text(lead).font(MassMatesFont.callout).foregroundStyle(isAssembly ? theme.tint : MassMatesPalette.textSecondary)
            Spacer()
            Text(response).font(MassMatesFont.callout).foregroundStyle(isAssembly ? theme.tint : MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.xs)
        .background(isAssembly ? theme.tintSoft : MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private func cardTitleBar(_ title: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            RoundedRectangle(cornerRadius: 3).fill(theme.tint).frame(width: 6, height: 16)
            Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}

#Preview("Holy Mass Word Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassWordRitesView()
    }
}
