import SwiftUI

struct ConfessionHeaderAndStepsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: ConfessionPrepViewModel

    // MARK: - Init
    init(viewModel: ConfessionPrepViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            privacyGuaranteeCard
            scriptureAndPrayerCard
            fiveStepsSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var privacyGuaranteeCard: some View {
        MassMatesCard {
            HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(theme.tint)
                    .frame(width: 36, height: 36)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                    privacyHeaderRow
                    Text("Suas faltas, notas e exame nunca saem deste aparelho. Criptografadas com chave biométrica segura. Nem os servidores têm acesso.")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                    privacyActionsRow
                }
            }
        }
    }

    private var privacyHeaderRow: some View {
        HStack {
            Text("SIGILO SAGRADO LOCAL")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
            Spacer()
            Label("Face ID Ativo", systemImage: "faceid")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, 2)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private var privacyActionsRow: some View {
        HStack {
            Button {
                viewModel.openConfessionalMode()
            } label: {
                Label("Modo Confessionário", systemImage: "eye.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                viewModel.clearAllNotes()
            } label: {
                Label("Limpar anotações", systemImage: "trash")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.danger)
            }
            .buttonStyle(.plain)
        }
    }

    private var scriptureAndPrayerCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Label(viewModel.lastConfessionBadgeText, systemImage: "calendar")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, MassMatesSpacing.xxs)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Text("\"Se confessarmos os nossos pecados, Ele é fiel e justo para nos perdoar e nos purificar de toda a injustiça.\"")
                    .font(MassMatesFont.scriptureEmphasis)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text("1 João 1, 9")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                holySpiritAccordionBox
            }
        }
    }

    private var holySpiritAccordionBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Button {
                viewModel.toggleHolySpiritPrayer()
            } label: {
                HStack {
                    Label("Oração ao Espírito Santo", systemImage: "flame.fill")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Spacer()
                    Image(systemName: viewModel.isHolySpiritPrayerExpanded ? "chevron.up" : "chevron.down")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
            .buttonStyle(.plain)
            if viewModel.isHolySpiritPrayerExpanded {
                Text("\"Vinde, Espírito Santo, enchei o meu coração com a Vossa luz. Dai-me a graça de conhecer com sinceridade as minhas fraquezas e pecados, a dor humilde e confiante do arrependimento, e a coragem de me acusar sem escrúpulos ou vergonha no Sacramento da Vossa infinita misericórdia. Por Cristo, Nosso Senhor. Amém.\"")
                    .font(MassMatesFont.customScripture(size: 14, italic: true))
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var fiveStepsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Text("Os 5 Passos para uma Boa Confissão").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("Tradição da Igreja").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    ForEach(viewModel.fiveSteps) { stepRow($0) }
                }
            }
        }
    }

    private func stepRow(_ step: GoodConfessionStep) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Text("\(step.number)")
                .font(MassMatesFont.caption)
                .foregroundStyle(step.isCompleted ? theme.onTint : theme.tint)
                .frame(width: 24, height: 24)
                .background(step.isCompleted ? theme.tint : theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                Text(step.description).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            if step.isCompleted {
                Image(systemName: "checkmark.circle").foregroundStyle(theme.tint)
            }
        }
    }
}

#Preview("Confession Header & Steps — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ConfessionHeaderAndStepsView(viewModel: ConfessionPrepViewModel())
    }
}
