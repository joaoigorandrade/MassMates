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
            rulesAndIntercessionCard
            pilgrimLimitCard
        }
    }

    // MARK: - Subviews / Private Helpers
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
