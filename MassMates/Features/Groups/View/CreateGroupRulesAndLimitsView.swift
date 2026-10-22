import SwiftUI

struct CreateGroupRulesAndLimitsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: CreateJoinGroupViewModel

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sharingRequirementCard
            rulesAndIntercessionCard
            pilgrimLimitCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sharingRequirementCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("Exigência de Partilha")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Defina como os irmãos registram seus frutos de oração.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                ForEach(GroupSharingRequirement.allCases) { requirement in
                    sharingRequirementOptionRow(requirement)
                }
            }
        }
    }

    private func sharingRequirementOptionRow(_ requirement: GroupSharingRequirement) -> some View {
        let isSelected = viewModel.draft.sharingRequirement == requirement
        return Button {
            viewModel.draft.sharingRequirement = requirement
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(requirement.title)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(requirement.badgeText)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(MassMatesSpacing.sm)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        }
        .buttonStyle(.plain)
    }

    private var rulesAndIntercessionCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text("Regras & Intercessão Secreta").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Tradições espirituais para dinamizar a caridade mútua.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                Toggle(isOn: $viewModel.isSecretGuardianAngelEnabled) {
                    ruleToggleLabel("Anjo da Guarda Secreto", "Sorteio semanal anônimo: você reza e oferece sacrifícios por um irmão específico, revelado no domingo.")
                }
                .tint(theme.tint).padding(MassMatesSpacing.xs).background(Theme(season: .purple).tintSoft).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                Toggle(isOn: $viewModel.isPhotoCheckInEnabled) {
                    ruleToggleLabel("Comprovação com Foto Respeitosa", "Permite anexar o altar pessoal, vela ou oratório nos registros de hábitos.")
                }
                .tint(theme.tint).padding(MassMatesSpacing.xs).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                sacredSealCallout
            }
        }
    }

    private func ruleToggleLabel(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
            Text(subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var sacredSealCallout: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
            Image(systemName: "lock.fill").font(MassMatesFont.caption).foregroundStyle(Theme(season: .white).tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Garantia do Sigilo Sagrado").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
                Text("Exames de consciência, diários íntimos e anotações sacramentais permanecem estritamente no seu aparelho e nunca são compartilhados em fraternidades.")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .padding(MassMatesSpacing.xs).background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var pilgrimLimitCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Limite de Peregrinos").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                        Text("Grupos menores favorecem intimidade real e acolhimento.").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(viewModel.pilgrimLimit)) Irmãos").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                        .padding(.horizontal, MassMatesSpacing.sm).padding(.vertical, 4).background(theme.tintSoft).clipShape(Capsule())
                }
                Slider(value: $viewModel.pilgrimLimit, in: 3...30, step: 1).tint(theme.tint)
                pilgrimScaleRow
            }
        }
    }

    private var pilgrimScaleRow: some View {
        HStack {
            Text("3 (Célula)"); Spacer()
            Text("12 (Cenáculo Apostólico)").foregroundStyle(theme.tint); Spacer()
            Text("30 (Capela)")
        }
        .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
    }
}

#Preview("Create Group Rules & Limits — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateGroupRulesAndLimitsView(viewModel: CreateJoinGroupViewModel(initialTab: .createNew))
            .padding()
    }
}
