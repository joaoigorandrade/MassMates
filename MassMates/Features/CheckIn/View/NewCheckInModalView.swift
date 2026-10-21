import Navigation
import SwiftUI

struct NewCheckInModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: NewCheckInViewModel
    private let activeStreakDays: Int

    private let chipColumns = [GridItem(.adaptive(minimum: 150), spacing: MassMatesSpacing.xs)]

    // MARK: - Init
    init(viewModel: NewCheckInViewModel, activeStreakDays: Int = 14) {
        self.viewModel = viewModel
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                topDismissRow
                headerSection
                atmosphericSeasonPill
                if let result = viewModel.submissionResult {
                    CheckInCelebrationCardView(
                        result: result,
                        activeStreakDays: activeStreakDays
                    ) {
                        navigator?.dismiss()
                    }
                } else {
                    practiceSelectorSection
                    CheckInSafeguardAndNoteSectionView(
                        viewModel: viewModel,
                        activeStreakDays: activeStreakDays
                    )
                    CheckInDestinationCardView(
                        isLockedToPrivateDiary: viewModel.isDestinationLockedToPrivateDiary,
                        destinationMode: viewModel.destinationMode,
                        availableGroups: viewModel.availableGroups,
                        selectedGroupIds: viewModel.selectedGroupIds,
                        activeStreakDays: activeStreakDays,
                        onSelectMode: { mode in viewModel.selectDestinationMode(mode) },
                        onToggleGroup: { id in viewModel.toggleGroupSelection(id) }
                    )
                    submitSection
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topDismissRow: some View {
        HStack {
            Color.clear.frame(width: 32, height: 32)
            Spacer()
            Capsule()
                .fill(MassMatesPalette.line)
                .frame(width: 40, height: 6)
            Spacer()
            Button { navigator?.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
        }
    }

    private var headerSection: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text("Novo Registro de Oração")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Text("Partilhe a graça ou guarde em seu diário íntimo.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var atmosphericSeasonPill: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Circle().fill(theme.tint).frame(width: 8, height: 8)
            Text("\(theme.season.defaultSeasonName.uppercased()) • DIA DE RECOLHIMENTO")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .tracking(0.5)
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, 6)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        .frame(maxWidth: .infinity)
    }

    private var practiceSelectorSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("SELECIONE A PRÁTICA")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)
            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: MassMatesSpacing.xs) {
                ForEach(SpiritualPractice.allCases) { practice in
                    practiceChip(practice)
                }
            }
        }
    }

    private func practiceChip(_ practice: SpiritualPractice) -> some View {
        let isSelected = viewModel.selectedPractice == practice
        return Button { viewModel.selectPractice(practice) } label: {
            HStack(spacing: 6) {
                Image(systemName: practice.isStrictlyPrivate ? "lock.fill" : practice.systemImage)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                Text(chipTitle(for: practice))
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                    .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.chip)
                    .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chipTitle(for practice: SpiritualPractice) -> String {
        switch practice {
        case .dailyGospel: "Evangelho do Dia"
        case .fasting: "Jejum & Penitência"
        case .confession: "Confissão Sacramental"
        default: practice.title
        }
    }

    private var submitSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            if let error = viewModel.errorMessage {
                Text(error).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.danger)
            }
            MassMatesPrimaryButton(
                title: viewModel.isDestinationLockedToPrivateDiary ? "Guardar com Segurança no Diário" : "Publicar e Atualizar Constância",
                systemImage: viewModel.isDestinationLockedToPrivateDiary ? "shield.fill" : "checkmark.circle.fill"
            ) { viewModel.submit() }
            Label("Criptografia em repouso no banco local • Zero sincronização pública", systemImage: "lock.rotation")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }
}

#Preview("New Check-In Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NewCheckInModalView(viewModel: NewCheckInViewModel())
    }
}
