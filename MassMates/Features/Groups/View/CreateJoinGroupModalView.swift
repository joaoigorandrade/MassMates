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
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                dragHandle
                modalHeader
                segmentedTabSelector
                seasonalCapacityPill
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }
                activeTabBody
                sacredQuoteFootnote
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var dragHandle: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(MassMatesPalette.line)
                .frame(width: 40, height: 4)
            Spacer()
        }
    }

    private var modalHeader: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.md) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: "hands.sparkles.fill")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Text("COMUNHÃO ESPIRITUAL")
                        .font(MassMatesFont.caption)
                        .tracking(0.6)
                        .foregroundStyle(theme.tint)
                }
                Text("Comunhão Fraterna")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Caminhe junto em oração diária, terço em comum ou propósitos sazonais com seus irmãos.")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer(minLength: 0)
            Button {
                navigator?.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var segmentedTabSelector: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            tabButton(for: .joinByCode, icon: "key.fill")
            tabButton(for: .createNew, icon: "plus.circle.fill")
        }
        .padding(MassMatesSpacing.xxs)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func tabButton(for tab: CreateJoinGroupTab, icon: String) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            viewModel.selectedTab = tab
        } label: {
            Label(tab.title, systemImage: icon)
                .font(MassMatesFont.caption)
                .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .background(isSelected ? MassMatesPalette.surface : Color.clear)
                .clipShape(.rect(cornerRadius: MassMatesSpacing.xs))
        }
        .buttonStyle(.plain)
    }

    private var seasonalCapacityPill: some View {
        HStack {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "person.2.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("Você possui **\(viewModel.slotCapacity.personalGroupCount) de \(viewModel.slotCapacity.maxAllowedPersonalGroups)** fraternidades ativas")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
            }
            Spacer()
            Text(theme.season.defaultSeasonName)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint.opacity(0.85))
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .padding(.vertical, MassMatesSpacing.xs)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func errorBanner(message: String) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                Text(message)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.danger)
                if !viewModel.slotCapacity.hasRewardedSlotUnlocked {
                    MassMatesSecondaryButton(title: "Liberar +1 vaga por 30 dias", systemImage: "play.rectangle") {
                        viewModel.unlockRewardedSlot()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var activeTabBody: some View {
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

    private var sacredQuoteFootnote: some View {
        VStack(spacing: MassMatesSpacing.xxs) {
            Text("“Onde dois ou três estiverem reunidos em meu nome, ali estou eu no meio deles.”")
                .font(MassMatesFont.customScripture(size: 14, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
            Text("SÃO MATEUS 18, 20")
                .font(MassMatesFont.caption)
                .tracking(0.6)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, MassMatesSpacing.xs)
    }
}

#Preview("Create / Join Group — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CreateJoinGroupModalView(
            viewModel: CreateJoinGroupViewModel(prefilledInviteCode: "ST1925")
        )
    }
}
