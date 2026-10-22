import Navigation
import SwiftUI

struct SpiritualDiaryModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: SpiritualDiaryViewModel
    @State private var selectedEntryForReading: PrivateDiaryCheckInEntry?
    @State private var selectedCategory: DiaryCategoryFilter = .all

    // MARK: - Init
    init(viewModel: SpiritualDiaryViewModel = SpiritualDiaryViewModel()) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                topNavigationBar
                headerSection
                if viewModel.isDiaryUnlocked {
                    unlockedDiaryContent
                } else {
                    lockedBiometricGate
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
    private var topNavigationBar: some View {
        HStack {
            Button {
                navigator?.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            if viewModel.isDiaryUnlocked {
                Button {
                    viewModel.lockDiaryNow()
                } label: {
                    Image(systemName: "lock")
                        .font(.system(size: 16))
                        .foregroundStyle(MassMatesPalette.textSecondary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .trailing)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("Diário Espiritual")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)

            Label("Privado · Apenas neste dispositivo", systemImage: "lock.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var unlockedDiaryContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            searchField
            categoryFilterChips
            entriesListSection
            SpiritualDiaryFooterView(viewModel: viewModel)
        }
    }

    private var searchField: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(MassMatesPalette.textTertiary)
            TextField("Buscar no diário...", text: $viewModel.searchQuery)
                .font(MassMatesFont.callout)
        }
        .padding(.horizontal, MassMatesSpacing.md)
        .frame(height: 52)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(DiaryCategoryFilter.allCases) { category in
                    categoryChip(for: category)
                }
            }
        }
    }

    private func categoryChip(for category: DiaryCategoryFilter) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectCategory(category)
        } label: {
            Text(category.rawValue)
                .font(MassMatesFont.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? MassMatesPalette.bg : MassMatesPalette.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.surfaceMuted)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func selectCategory(_ category: DiaryCategoryFilter) {
        selectedCategory = category
        viewModel.selectedPracticeFilter = category.practice
    }

    private var entriesListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if displayedEntries.isEmpty {
                Text("Nenhum registro encontrado")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, MassMatesSpacing.xl)
            } else {
                ForEach(Array(displayedEntries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Rectangle()
                            .fill(MassMatesPalette.line)
                            .frame(height: 1)
                    }
                    SpiritualDiaryEntryCardView(entry: entry) { chosen in
                        selectedEntryForReading = chosen
                    }
                }
            }
        }
    }

    private var displayedEntries: [PrivateDiaryCheckInEntry] {
        let entries = viewModel.filteredEntries
        if selectedCategory == .examen {
            return entries.filter {
                ($0.reflectionOrNotes ?? "").localizedCaseInsensitiveContains("exame") ||
                ($0.confessorOrPenanceNotes ?? "").localizedCaseInsensitiveContains("exame") ||
                $0.practice == .confession
            }
        }
        return entries
    }

    private var lockedBiometricGate: some View {
        VStack(spacing: MassMatesSpacing.md) {
            Image(systemName: "faceid")
                .font(.system(size: 40))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.top, MassMatesSpacing.xl)

            Text("Diário Protegido")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)

            Text("Autentique-se com Face ID para acessar suas anotações íntimas.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)

            if let error = viewModel.securityErrorMessage {
                Text(error)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.danger)
            }

            MassMatesPrimaryButton(title: "Desbloquear com Biometria", systemImage: "lock.open") {
                _ = viewModel.unlockWithBiometrics(simulateSuccess: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MassMatesSpacing.lg)
    }
}

#Preview("Spiritual Diary Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryModalView(viewModel: SpiritualDiaryViewModel())
    }
}
