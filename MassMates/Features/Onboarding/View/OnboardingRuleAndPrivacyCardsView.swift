import SwiftUI

struct OnboardingRuleAndPrivacyCardsView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: OnboardingViewModel
    @State private var isCustomizing: Bool = false
    private let onBack: (() -> Void)?
    private let onNext: (() -> Void)?

    // MARK: - Init
    init(viewModel: OnboardingViewModel, onBack: (() -> Void)? = nil, onNext: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onBack = onBack
        self.onNext = onNext
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topNavigationBar
            titleHeader
                .padding(.top, MassMatesSpacing.md)
                .padding(.bottom, MassMatesSpacing.lg)
            presetRowsSection
            personalizeButton
                .padding(.top, MassMatesSpacing.md)
            Spacer()
            continueButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $isCustomizing) { customizationSheet }
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button(action: { onBack?() ?? viewModel.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: MassMatesSpacing.xs) {
                ForEach(1...3, id: \.self) { step in
                    Circle()
                        .fill(step == 2 ? theme.tint : MassMatesPalette.line)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(height: MassMatesLayout.minTapTarget)
    }

    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("Escolha sua Regra de Vida")
                .font(MassMatesFont.displayMobile)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Um compromisso sóbrio para orientar seu ritmo espiritual diário.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var presetRowsSection: some View {
        VStack(spacing: 0) {
            ForEach(RuleOfLifePreset.allCases, id: \.self) { preset in
                presetRow(for: preset)
                Rectangle().fill(MassMatesPalette.line).frame(height: 1)
            }
        }
    }

    private func presetRow(for preset: RuleOfLifePreset) -> some View {
        let isSelected = viewModel.selectedPreset == preset
        let content = presetContent(preset)
        return Button {
            viewModel.selectedPreset = preset
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text(content.subtitle)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                radioIndicator(isSelected: isSelected)
            }
            .frame(minHeight: 68)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func radioIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? theme.tint : MassMatesPalette.line, lineWidth: isSelected ? 2 : 1.5)
                .frame(width: 20, height: 20)
            if isSelected {
                Circle().fill(theme.tint).frame(width: 10, height: 10)
            }
        }
    }

    private func presetContent(_ preset: RuleOfLifePreset) -> (title: String, subtitle: String) {
        switch preset {
        case .essentialDaily: ("Essencial diária", "Oferecimento · Evangelho · Exame")
        case .devotionalClassic: ("Devocional clássica", "Missa · Terço · Angelus")
        case .asceticLenten: ("Ascética / Quaresmal", "Jejum · Adoração · Leitura")
        }
    }

    private var personalizeButton: some View {
        Button {
            isCustomizing = true
        } label: {
            Text("Personalizar")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        MassMatesPrimaryButton(title: "Continuar") {
            viewModel.acknowledgedLocalDiaryWarning = true
            onNext?()
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private var customizationSheet: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Práticas Incluídas")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(viewModel.practicePreviewItems) { item in
                Button {
                    viewModel.togglePracticePreview(id: item.id)
                } label: {
                    HStack {
                        Image(systemName: item.systemImage)
                            .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.textSecondary)
                        Text(item.title)
                            .font(MassMatesFont.body)
                            .foregroundStyle(MassMatesPalette.textPrimary)
                        Spacer()
                        Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isEnabled ? theme.tint : MassMatesPalette.line)
                    }
                    .frame(minHeight: MassMatesLayout.minTapTarget)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            MassMatesPrimaryButton(title: "Pronto") { isCustomizing = false }
        }
        .padding(MassMatesSpacing.lg)
        .background(MassMatesPalette.bg)
    }
}

#Preview("Onboarding Rule Cards — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        OnboardingRuleAndPrivacyCardsView(
            viewModel: OnboardingViewModel(initialStep: .profileAndRuleSetup)
        )
    }
}
