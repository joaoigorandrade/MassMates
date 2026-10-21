import SwiftUI

struct HolyMassInitialRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            initialGreetingCard
            penitentialActCard
            gloriaCard
            collectPrayerCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var initialGreetingCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                cardHeader(title: "Saudação Inicial", posture: .standing)
                ForEach(HolyMassRitesCatalog.initialGreetingTurns) { turn in
                    dialogueBlock(turn)
                }
            }
        }
    }

    private var penitentialActCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    cardTitleBar("Ato Penitencial")
                    Spacer()
                    Text("CONFISSÃO COMUNITÁRIA")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                confiteorBox
                ForEach(HolyMassRitesCatalog.kyrieTurns) { turn in
                    compactDialogueRow(turn)
                }
            }
        }
    }

    private var confiteorBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("FÓRMULA TRADICIONAL • TODOS")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«Confesso a Deus todo-poderoso e a vós, irmãos e irmãs, que pequei muitas vezes por pensamentos e palavras, atos e omissões, por minha culpa, minha tão grande culpa...»")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var gloriaCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    cardTitleBar("Glória a Deus nas Alturas")
                    Spacer()
                    Text("Hino de Louvor").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                Text("«Glória a Deus nas alturas, e paz na terra aos homens por Ele amados. Senhor Deus, Rei dos céus, Deus Pai todo-poderoso: nós vos louvamos, nós vos bendizemos, nós vos adoramos, nós vos glorificamos, nós vos damos graças por vossa imensa glória...»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
    }

    private var collectPrayerCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Text("ORAÇÃO DA COLETA").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                Spacer()
                Text("Conclusão dos Ritos Iniciais").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Text("«Ó Deus, cuja providência jamais falha em seus desígnios, afastai de nós todo mal e concedei-nos tudo o que for de proveito para a nossa salvação...»")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Todos: Amém.")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private func dialogueBlock(_ turn: MassDialogueTurn) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(turn.speaker.uppercased())
                .font(MassMatesFont.caption)
                .foregroundStyle(turn.isAssembly ? theme.tint : MassMatesPalette.textSecondary)
            Text(turn.text)
                .font(turn.isAssembly ? MassMatesFont.scriptureEmphasis : MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(turn.isAssembly ? theme.tintSoft : MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private func compactDialogueRow(_ turn: MassDialogueTurn) -> some View {
        HStack {
            Text(turn.speaker)
                .font(MassMatesFont.callout)
                .foregroundStyle(turn.isAssembly ? theme.tint : MassMatesPalette.textSecondary)
            Spacer()
            Text(turn.text)
                .font(MassMatesFont.callout)
                .foregroundStyle(turn.isAssembly ? theme.tint : MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.xs)
        .background(turn.isAssembly ? theme.tintSoft : MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private func cardHeader(title: String, posture: LiturgicalPosture) -> some View {
        HStack {
            cardTitleBar(title)
            Spacer()
            Label(posture.rawValue, systemImage: posture.systemImage)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, 2)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private func cardTitleBar(_ title: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            RoundedRectangle(cornerRadius: 3).fill(theme.tint).frame(width: 6, height: 16)
            Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}

#Preview("Holy Mass Initial Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassInitialRitesView()
    }
}
