import SwiftUI

struct CreateGroupFormTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: CreateJoinGroupViewModel
    private let onCreated: () -> Void
    private let saintOptions = ["Sta. Teresinha", "São José Operário", "São Bento", "N. Sra. Desatadora", "Outro"]

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel, onCreated: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCreated = onCreated
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            namingCard; patronSaintCard; collectiveGoalTypeCard
            CreateGroupRulesAndLimitsView(viewModel: viewModel)
            createActionSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var namingCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("Nome da Fraternidade").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Escolha uma invocação fraterna ou nome paroquial.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                HStack(spacing: MassMatesSpacing.xs) {
                    Image(systemName: "building.columns").foregroundStyle(MassMatesPalette.textTertiary)
                    TextField("Ex: Fraternidade São José", text: $viewModel.draft.name).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                }
                .padding(MassMatesSpacing.sm).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            }
        }
    }

    private var patronSaintCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Padroeiro & Intercessor").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                        Text("O modelo espiritual que guiará este círculo.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles").foregroundStyle(theme.tint)
                }
                saintShowcaseRow; saintChipsRow
            }
        }
    }

    private var saintShowcaseRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "cross.fill").font(MassMatesFont.title).foregroundStyle(theme.tint)
                .frame(width: 44, height: 44).background(theme.tintSoft).clipShape(.rect(cornerRadius: MassMatesSpacing.xs))
            VStack(alignment: .leading, spacing: 2) {
                Text("Santa Teresinha do Menino Jesus").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Padroeira das Missões e Doutora do Amor").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.tint)
        }
        .padding(MassMatesSpacing.xs).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var saintChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xxs) {
                ForEach(saintOptions, id: \.self) { saint in
                    saintChipButton(saint)
                }
            }
        }
    }

    private func saintChipButton(_ saint: String) -> some View {
        let isSelected = viewModel.selectedPatronSaint == saint
        return Button {
            viewModel.selectedPatronSaint = saint
            viewModel.draft.parishOrCommunity = saint
        } label: {
            HStack(spacing: 4) {
                if saint == "Outro" {
                    Image(systemName: "magnifyingglass")
                        .font(MassMatesFont.caption)
                }
                Text(saint)
            }
            .font(MassMatesFont.caption)
            .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
            .padding(.horizontal, MassMatesSpacing.sm)
            .padding(.vertical, 6)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var collectiveGoalTypeCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("Tipo de Meta Coletiva").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Evite competição; promova união e perseverança fraterna.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                goalRadioRow(title: "Tesouro Coletivo", desc: "Soma conjunta das orações do grupo. Ex: 500 Terços ou 100 Horas de Adoração ao mês.", icon: "hourglass", mode: .collectiveTreasure, groupType: .fraternity)
                goalRadioRow(title: "Fidelidade Diária Silenciosa", desc: "Cada irmão pontua seus dias fiéis, sustentando os demais sem ranking de pontuação.", icon: "calendar", mode: .faithfulDays, groupType: .fraternity)
                goalRadioRow(title: "Desafio Sazonal Litúrgico", desc: "Penitência de Quaresma, Novena de Pentecostes ou Quaresma de São Miguel.", icon: "sparkles", mode: .customPoints, groupType: .challenge)
            }
        }
    }

    private func goalRadioRow(title: String, desc: String, icon: String, mode: GroupScoringMode, groupType: CommunityGroupType) -> some View {
        let isSelected = viewModel.draft.scoringMode == mode && viewModel.draft.type == groupType
        return Button {
            viewModel.draft.scoringMode = mode
            viewModel.draft.type = groupType
        } label: {
            HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle").foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Label(title, systemImage: icon).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
                    Text(desc).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(MassMatesSpacing.sm).background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        }
        .buttonStyle(.plain)
    }

    private var createActionSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(title: "Consagrar e Criar Fraternidade", systemImage: "hands.sparkles.fill") {
                if viewModel.submitCreateGroup() != nil { onCreated() }
            }
            Text("Você receberá um código e convite abençoado para repassar aos amigos.")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary).multilineTextAlignment(.center)
        }
    }
}

#Preview("Create Group Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in CreateGroupFormTabView(viewModel: CreateJoinGroupViewModel(initialTab: .createNew), onCreated: {}) }
}
