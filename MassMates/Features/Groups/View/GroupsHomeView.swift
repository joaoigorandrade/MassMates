import Navigation
import SwiftUI

struct GroupsHomeView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable private var viewModel: GroupsHomeViewModel

    // MARK: - Init
    init(viewModel: GroupsHomeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerSection
                quickActionButtonsRow
                contentForState
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.vertical, MassMatesSpacing.md)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .task {
            if case .idle = viewModel.viewState {
                viewModel.loadGroups()
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "person.3.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                Text("VIDA EM COMUNHÃO")
                    .font(MassMatesFont.caption)
                    .tracking(0.6)
                    .foregroundStyle(theme.tint)
            }
            Text("Fraternidades & Grupos")
                .font(MassMatesFont.display)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("Caminhar em comunhão fraterna e oração mútua no ritmo litúrgico.")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var quickActionButtonsRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            joinQuickActionButton
            createQuickActionButton
        }
    }

    private var joinQuickActionButton: some View {
        Button {
            navigator?.present(.createJoinGroup(initialTab: .joinByCode, prefilledInviteCode: nil, season: theme.season))
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "key.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Entrar com Código").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Código de 6 dígitos").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.button).stroke(MassMatesPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var createQuickActionButton: some View {
        Button {
            navigator?.present(.createJoinGroup(initialTab: .createNew, prefilledInviteCode: nil, season: theme.season))
        } label: {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.onTint)
                    .frame(width: 32, height: 32)
                    .background(theme.onTint.opacity(0.2))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Criar Fraternidade").font(MassMatesFont.caption).foregroundStyle(theme.onTint)
                    Text("Iniciar novo grupo").font(MassMatesFont.caption).foregroundStyle(theme.onTint.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(theme.tint)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            ProgressView().tint(theme.tint)
        case .loaded(let snapshot):
            loadedBody(snapshot: snapshot)
        case .error(let error):
            Text(error.userMessage).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.danger)
        }
    }

    private func loadedBody(snapshot: GroupsHomeSnapshot) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            if let feedback = viewModel.feedbackMessage {
                feedbackBanner(text: feedback)
            }
            GroupsCapacityCardView(capacity: snapshot.slotCapacity) {
                viewModel.unlockBonusPersonalSlot()
            }
            ContinuousFraternitiesSectionView(groups: snapshot.joinedGroups) { group in
                navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
            }
            FeaturedChallengesSectionView(
                challenges: snapshot.featuredChallenges,
                onJoinChallenge: { id in viewModel.joinFeaturedChallenge(id) },
                onOpenGroup: { group in
                    navigator?.navigate(to: .groupDetail(group: group, season: theme.season))
                }
            )
            ApostoladoSponsoredCardView()
        }
    }

    private func feedbackBanner(text: String) -> some View {
        MassMatesCard {
            HStack {
                Text(text).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Button("Fechar") { viewModel.clearFeedback() }
                    .font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
        }
    }
}

#Preview("Groups Home — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let vm = GroupsHomeViewModel()
        let _ = vm.loadGroups()
        GroupsHomeView(viewModel: vm)
    }
}
