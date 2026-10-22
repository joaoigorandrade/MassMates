import Navigation
import SwiftUI

struct CreateJoinGroupModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: CreateJoinGroupViewModel

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                grabberBar
                headerCloseRow
                segmentedControl
                headerTitleSection
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }
                activeContent
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.bottom, MassMatesSpacing.xl)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var grabberBar: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(MassMatesPalette.line)
                .frame(width: 36, height: 4)
            Spacer()
        }
        .padding(.top, MassMatesSpacing.sm)
        .padding(.bottom, MassMatesSpacing.xs)
    }

    private var headerCloseRow: some View {
        HStack {
            Spacer()
            Button {
                navigator?.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(minWidth: MassMatesLayout.minTapTarget, minHeight: MassMatesLayout.minTapTarget)
        }
        .padding(.bottom, MassMatesSpacing.xs)
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
        .padding(.bottom, MassMatesSpacing.lg)
    }

    private func segmentButton(title: String, tab: CreateJoinGroupTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedTab = tab
            }
        } label: {
            Text(title)
                .font(MassMatesFont.callout.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? MassMatesPalette.surface : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.04) : Color.clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var headerTitleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(viewModel.selectedTab == .createNew ? "Criar Fraternidade" : "Entrar na Fraternidade")
                .font(MassMatesFont.customScripture(size: 26, italic: false).weight(.semibold))
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text(viewModel.selectedTab == .createNew ? "Um espaço de oração e perseverança mútua" : "Insira a chave recebida de um irmão")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(.bottom, MassMatesSpacing.lg)
    }

    private func errorBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(message)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.danger)
            if !viewModel.slotCapacity.hasRewardedSlotUnlocked {
                Button {
                    viewModel.unlockRewardedSlot()
                } label: {
                    Text("Liberar +1 vaga por 30 dias")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .padding(.bottom, MassMatesSpacing.md)
    }

    @ViewBuilder
    private var activeContent: some View {
        if viewModel.selectedTab == .joinByCode {
            JoinGroupByCodeTabView(viewModel: viewModel) {
                navigator?.dismiss()
            }
        } else {
            CreateGroupFormTabView(viewModel: viewModel) {
                navigator?.dismiss()
            }
        }
    }
}

#Preview("Create / Join Group — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateJoinGroupModalView(
            viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925")
        )
    }
}
