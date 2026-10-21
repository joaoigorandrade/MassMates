import SwiftUI

struct HolyMassEucharisticAndFinalRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            offertoryCard
            sanctusCard
            consecrationCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var offertoryCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    cardTitleBar("Apresentação das Oferendas")
                    Spacer()
                    postureBadge(.seated, isHighlighted: false)
                }
                ForEach(HolyMassRitesCatalog.offertoryTurns) { turn in
                    offertoryTurnBox(turn)
                }
            }
        }
    }

    private func offertoryTurnBox(_ turn: MassDialogueTurn) -> some View {
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

    private var sanctusCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    Text("O Santo (Sanctus)").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Text("Louvor Celeste").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                Text("«Santo, Santo, Santo, Senhor, Deus do universo!\nO céu e a terra estão cheios da vossa glória.\nHosana nas alturas!\nBendito o que vem em nome do Senhor!\nHosana nas alturas!»")
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(MassMatesSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
        }
    }

    private var consecrationCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                HStack {
                    cardTitleBar("Consagração Eucarística")
                    Spacer()
                    postureBadge(.kneeling, isHighlighted: true)
                }
                consecrationWordsBox
                HStack(spacing: MassMatesSpacing.xs) {
                    Image(systemName: "heart.fill")
                    Text("«Meu Senhor e meu Deus!»").font(MassMatesFont.scriptureEmphasis)
                }
                .foregroundStyle(theme.tint)
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
        }
    }

    private var consecrationWordsBox: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Text("MOMENTO SOLENE DE ADORAÇÃO SILENCIOSA")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«TOMAI, TODOS, E COMEI: ISTO É O MEU CORPO, QUE SERÁ ENTREGUE POR VÓS.»")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            Text("«TOMAI, TODOS, E BEBEI: ESTE É O CÁLICE DO MEU SANGUE, O SANGUE DA NOVA E ETERNA ALIANÇA... FAZEI ISTO EM MEMÓRIA DE MIM.»")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private func postureBadge(_ posture: LiturgicalPosture, isHighlighted: Bool) -> some View {
        Label(posture.rawValue, systemImage: posture.systemImage)
            .font(MassMatesFont.caption)
            .foregroundStyle(isHighlighted ? theme.tint : MassMatesPalette.textSecondary)
            .padding(.horizontal, MassMatesSpacing.xs)
            .padding(.vertical, 2)
            .background(isHighlighted ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
    }

    private func cardTitleBar(_ title: String) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            RoundedRectangle(cornerRadius: 3).fill(theme.tint).frame(width: 6, height: 16)
            Text(title).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
        }
    }
}

#Preview("Holy Mass Eucharistic Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassEucharisticAndFinalRitesView()
    }
}
