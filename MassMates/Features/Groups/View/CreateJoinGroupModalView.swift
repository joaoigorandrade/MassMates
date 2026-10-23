import Navigation
import SwiftUI

enum CreateGroupStep: Sendable, Equatable {
    case identity
    case rules
}

struct CreateJoinGroupModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: CreateJoinGroupViewModel
    @State private var creationStep: CreateGroupStep = .identity

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabberBar
            headerNavigationRow
            if showSegmentedControl { segmentedControl }
            if viewModel.selectedTab == .createNew { headerTitleSection }
            if let error = viewModel.errorMessage { errorBanner(message: error) }
            activeContent
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.bottom, MassMatesSpacing.md)
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .task { await viewModel.load() }
        .onChange(of: viewModel.selectedTab) { _, _ in creationStep = .identity }
    }

    // MARK: - Subviews / Private Helpers
    private var showSegmentedControl: Bool {
        viewModel.selectedTab == .joinByCode || creationStep == .identity
    }

    private var grabberBar: some View {
        HStack {
            Spacer()
            Capsule().fill(MassMatesPalette.line).frame(width: 36, height: 4)
            Spacer()
        }
        .padding(.top, MassMatesSpacing.sm)
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private var headerNavigationRow: some View {
        HStack {
            if viewModel.selectedTab == .createNew && creationStep == .rules {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { creationStep = .identity }
                } label: {
                    Label("Identidade", systemImage: "chevron.left")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(theme.tint)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            closeButton
        }
    }

    private var closeButton: some View {
        Button {
            if let navigator { navigator.dismiss() } else { dismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 32, height: 32)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var segmentedControl: some View {
        HStack {
            Spacer()
            HStack(spacing: 0) {
                segmentButton(title: "Entrar", tab: .joinByCode)
                segmentButton(title: "Criar", tab: .createNew)
            }
            .padding(MassMatesSpacing.xxs)
            .frame(maxWidth: 280)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(Capsule())
            Spacer()
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private func segmentButton(title: String, tab: CreateJoinGroupTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectedTab = tab }
        } label: {
            Text(title)
                .font(MassMatesFont.callout.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(isSelected ? MassMatesPalette.surface : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var headerTitleSection: some View {
        let isIdentity = creationStep == .identity
        let title = isIdentity ? "Criar Fraternidade" : "Regras & Pontos"
        let sub = isIdentity ? "Passo 1 de 2 • Identidade" : "Passo 2 de 2 • Regras da fraternidade"
        return VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(title)
                .font(MassMatesFont.customScripture(size: 24, italic: false).weight(.semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(sub)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.bottom, MassMatesSpacing.sm)
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Text(message).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.danger)
            Spacer()
            if !viewModel.slotCapacity.hasRewardedSlotUnlocked {
                Button {
                    Task { await viewModel.unlockRewardedSlot() }
                } label: {
                    Text("+1 vaga").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .padding(.bottom, MassMatesSpacing.xs)
    }

    @ViewBuilder
    private var activeContent: some View {
        switch (viewModel.selectedTab, creationStep) {
        case (.joinByCode, _):
            JoinGroupByCodeTabView(viewModel: viewModel) {
                if let navigator { navigator.dismiss() } else { dismiss() }
            }
        case (.createNew, .identity):
            CreateGroupFormTabView(viewModel: viewModel, onAdvance: {
                withAnimation(.easeInOut(duration: 0.2)) { creationStep = .rules }
            })
        case (.createNew, .rules):
            CreateGroupRulesAndLimitsView(
                viewModel: viewModel,
                onBack: { withAnimation(.easeInOut(duration: 0.2)) { creationStep = .identity } },
                onCreated: {
                    if let navigator { navigator.dismiss() } else { dismiss() }
                }
            )
        }
    }
}

#Preview("Create / Join Group — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateJoinGroupModalView(viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925"))
    }
}
