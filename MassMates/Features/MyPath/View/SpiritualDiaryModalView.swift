import Navigation
import SwiftUI

struct SpiritualDiaryModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: SpiritualDiaryViewModel
    @State private var selectedEntryForReading: PrivateDiaryCheckInEntry?

    // MARK: - Init
    init(viewModel: SpiritualDiaryViewModel = SpiritualDiaryViewModel()) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                editorialTopHeader
                if viewModel.isDiaryUnlocked {
                    unlockedDiaryContent
                } else {
                    lockedBiometricGateCard
                }
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .sheet(item: $selectedEntryForReading) { entry in
            DiaryEntryImmersiveReaderView(entry: entry)
                .environment(\.liturgicalTheme, theme)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var editorialTopHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Label("SIGILO PESSOAL", systemImage: "lock.shield.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, 4)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Spacer()
                Button { _ = viewModel.exportEncryptedBackup() } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                MassMatesTextButton(title: "Fechar") { navigator?.dismiss() }
            }
            Text("Diário de Graças")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("“Memória viva das consolações e frutos colhidos no recolhimento interior.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Label("\(viewModel.allEntries.count) registros íntimos protegidos neste aparelho • Criptografia ponta a ponta", systemImage: "lock.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        }
    }

    private var lockedBiometricGateCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                Label("Protegido por Face ID / Touch ID", systemImage: "faceid")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Desbloqueie seu Diário Espiritual para ler suas reflexões e registros de Confissão.")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                MassMatesPrimaryButton(title: "Desbloquear com Biometria", systemImage: "lock.open") {
                    _ = viewModel.unlockWithBiometrics(simulateSuccess: true)
                }
            }
        }
    }

    private var unlockedDiaryContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            searchAndFilterSection
            monthGroupSection(title: "OUTUBRO 2024", subtitle: "\(viewModel.filteredEntries.count) registros neste mês")
            SpiritualDiaryFooterView(viewModel: viewModel)
        }
    }

    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MassMatesPalette.textTertiary)
                TextField("Buscar palavra, passagem bíblica ou fruto...", text: $viewModel.searchQuery)
                    .font(MassMatesFont.callout)
            }
            .padding(MassMatesSpacing.sm)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MassMatesSpacing.xs) {
                    filterChip(title: "Todas as Práticas", practice: nil)
                    filterChip(title: "Lectio Divina", practice: .dailyGospel)
                    filterChip(title: "Santo Terço", practice: .rosary)
                    filterChip(title: "Oração Mental", practice: .mentalPrayer)
                    filterChip(title: "Exame", practice: .confession)
                    filterChip(title: "Graça Notável", practice: .adoration)
                }
            }
        }
    }

    private func filterChip(title: String, practice: SpiritualPractice?) -> some View {
        let isSelected = viewModel.selectedPracticeFilter == practice
        return Button { viewModel.selectedPracticeFilter = practice } label: {
            Text(title)
                .font(isSelected ? MassMatesFont.headline : MassMatesFont.callout)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .padding(.horizontal, MassMatesSpacing.sm)
                .frame(height: 36)
                .background(isSelected ? theme.tintSoft : MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .buttonStyle(.plain)
    }

    private func monthGroupSection(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Label(title, systemImage: "calendar")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text(subtitle)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            ForEach(viewModel.filteredEntries) { entry in
                SpiritualDiaryEntryCardView(entry: entry) { chosen in
                    selectedEntryForReading = chosen
                }
            }
        }
    }
}

#Preview("Spiritual Diary Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryModalView(viewModel: SpiritualDiaryViewModel())
    }
}
