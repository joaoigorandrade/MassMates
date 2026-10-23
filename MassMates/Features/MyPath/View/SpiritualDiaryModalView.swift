import Navigation
import SwiftUI

struct SpiritualDiaryModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator private var navigator: Navigator<AppRoute>?
    @Bindable private var viewModel: SpiritualDiaryViewModel
    @State private var selectedEntryForReading: PrivateDiaryCheckInEntry?
    @State private var selectedMonth: Date = Date()
    @State private var isSearchActive: Bool = false
    @State private var displayedEntries: [PrivateDiaryCheckInEntry] = []

    // MARK: - Init
    init(viewModel: SpiritualDiaryViewModel = SpiritualDiaryViewModel()) {
        self.viewModel = viewModel
        let initial = Self.computeDisplayed(entries: viewModel.filteredEntries, month: Date(), query: viewModel.searchQuery)
        self._displayedEntries = State(initialValue: initial)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topNavigationBar
            monthSwitcher
            hairlineDivider.padding(.top, MassMatesSpacing.xs)
            if viewModel.isDiaryUnlocked {
                entriesSection
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            } else {
                lockedBiometricGate
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            }
            Spacer(minLength: MassMatesSpacing.xs)
            bottomBiometricPill
        }
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isDiaryUnlocked)
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .sheet(item: $selectedEntryForReading) {
            DiaryEntryImmersiveReaderView(entry: $0, allEntries: displayedEntries).environment(\.liturgicalTheme, theme)
        }
        .onChange(of: viewModel.filteredEntries) { updateDisplayedEntries() }
        .onChange(of: viewModel.searchQuery) { updateDisplayedEntries() }
        .onAppear { updateDisplayedEntries() }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button { navigator?.dismiss() ?? dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
            }.buttonStyle(.plain)
            Spacer()
            Text("Diário").font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Button { toggleSearch() } label: {
                Image(systemName: isSearchActive ? "xmark" : "magnifyingglass").font(.system(size: 17, weight: .medium))
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .trailing)
            }.buttonStyle(.plain)
        }
        .frame(height: 52)
    }

    private var monthSwitcher: some View {
        HStack(spacing: MassMatesSpacing.lg) {
            monthChevron(icon: "chevron.left") { changeMonth(by: -1) }
            Text(monthYearLabel).font(MassMatesFont.callout).fontWeight(.medium)
                .foregroundStyle(MassMatesPalette.textPrimary).contentTransition(.numericText())
            monthChevron(icon: "chevron.right") { changeMonth(by: 1) }
        }
    }

    private func monthChevron(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }.buttonStyle(.plain)
    }

    private var entriesSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if isSearchActive {
                    searchField.padding(.vertical, MassMatesSpacing.xs)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                }
                if displayedEntries.isEmpty {
                    Text("Nenhum registro encontrado").font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textSecondary).frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    ForEach(displayedEntries) { entry in
                        SpiritualDiaryEntryCardView(entry: entry) { selectedEntryForReading = $0 }
                        hairlineDivider
                    }
                }
            }
            .padding(.bottom, MassMatesSpacing.lg)
        }
    }

    private var searchField: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(MassMatesPalette.textTertiary)
            TextField("Buscar no diário...", text: $viewModel.searchQuery).font(MassMatesFont.callout)
        }
        .padding(.horizontal, MassMatesSpacing.md).frame(height: 44)
        .background(MassMatesPalette.surfaceMuted).clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var bottomBiometricPill: some View {
        Button {
            if viewModel.isDiaryUnlocked { viewModel.lockDiaryNow() } else { _ = viewModel.unlockWithBiometrics() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 13))
                Text("Protegido por Face ID").font(MassMatesFont.caption)
            }
            .foregroundStyle(MassMatesPalette.textSecondary).padding(.vertical, 8).padding(.horizontal, MassMatesSpacing.md)
            .background(MassMatesPalette.surfaceMuted.opacity(0.8)).clipShape(Capsule())
        }
        .buttonStyle(.plain).padding(.bottom, MassMatesSpacing.sm)
    }

    private var lockedBiometricGate: some View {
        VStack(spacing: MassMatesSpacing.md) {
            Image(systemName: "faceid").font(.system(size: 40)).foregroundStyle(MassMatesPalette.textSecondary)
            Text("Diário Protegido").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            MassMatesPrimaryButton(title: "Desbloquear com Biometria", systemImage: "lock.open") {
                _ = viewModel.unlockWithBiometrics(simulateSuccess: true)
            }
        }.frame(maxWidth: .infinity).padding(.vertical, MassMatesSpacing.xl)
    }

    private var hairlineDivider: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }

    private var monthYearLabel: String {
        selectedMonth.formatted(.dateTime.month(.wide).year()).capitalized
    }

    private static func computeDisplayed(
        entries: [PrivateDiaryCheckInEntry], month: Date, query: String
    ) -> [PrivateDiaryCheckInEntry] {
        let cal = Calendar.current
        let matching = entries.filter { cal.isDate($0.createdAt, equalTo: month, toGranularity: .month) }
        return !matching.isEmpty ? Array(matching.prefix(5)) : (query.isEmpty ? Array(entries.prefix(5)) : [])
    }

    private func updateDisplayedEntries() {
        displayedEntries = Self.computeDisplayed(
            entries: viewModel.filteredEntries, month: selectedMonth, query: viewModel.searchQuery
        )
    }

    private func changeMonth(by value: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) else { return }
        withAnimation(reduceMotion ? .none : .snappy(duration: 0.2)) {
            selectedMonth = next
            displayedEntries = Self.computeDisplayed(entries: viewModel.filteredEntries, month: next, query: viewModel.searchQuery)
        }
    }

    private func toggleSearch() {
        withAnimation(reduceMotion ? .none : .snappy(duration: 0.2)) {
            isSearchActive.toggle()
            if !isSearchActive { viewModel.searchQuery = "" }
            updateDisplayedEntries()
        }
    }
}

#Preview("Spiritual Diary Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in SpiritualDiaryModalView(viewModel: SpiritualDiaryViewModel()) }
}
