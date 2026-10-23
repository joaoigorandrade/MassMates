import Navigation
import SwiftUI

struct GroupDetailView: View {
    // MARK: - Dependencies & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @Bindable var viewModel: GroupDetailViewModel

    static let publicPractices = SpiritualPractice.allCases.filter { !$0.isStrictlyPrivate }

    // MARK: - Init
    init(viewModel: GroupDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                    GroupIdentityBannerView(
                        group: viewModel.group,
                        scoringMode: viewModel.scoringSummary.scoringMode,
                        selectedSubTab: viewModel.selectedSubTab,
                        onSelectSubTab: { tab in viewModel.selectedSubTab = tab }
                    )
                    if viewModel.isShowingModerationPanel {
                        GroupSafetyModerationView(viewModel: viewModel)
                    }
                    activeSubTabContent
                }
                .padding(.horizontal, MassMatesLayout.screenMargin)
                .padding(.top, MassMatesSpacing.xs)
                .padding(.bottom, MassMatesSpacing.xl)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
            await viewModel.startRealtime()
        }
    }

    // MARK: - Subviews / Private Helpers
    private var navigationBar: some View {
        HStack {
            backButton
            Spacer()
            Text("MassMates").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            shareInviteButton
            optionsMenu
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .frame(height: 44)
    }

    private var backButton: some View {
        Button {
            if let navigator, navigator.canPop() {
                navigator.pop()
            } else if let navigator {
                navigator.dismiss()
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Voltar")
    }

    private var shareInviteButton: some View {
        Group {
            if let url = viewModel.group.inviteLinkURL, !viewModel.group.inviteCode.isEmpty {
                ShareLink(item: url, subject: Text(viewModel.group.name), message: Text("Participe do grupo \(viewModel.group.name) no MassMates:")) {
                    Image(systemName: "square.and.arrow.up").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                }
            } else {
                Button {
                    let text = viewModel.group.inviteCode.isEmpty ? (viewModel.inviteShareLabel ?? "") : viewModel.group.inviteCode
                    UIPasteboard.general.string = text
                } label: {
                    Image(systemName: "square.and.arrow.up").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compartilhar convite")
    }

    private var optionsMenu: some View {
        Menu {
            if !viewModel.group.inviteCode.isEmpty {
                Button("Copiar Código de Convite", systemImage: "doc.on.doc") { UIPasteboard.general.string = viewModel.group.inviteCode }
            }
            if let inviteLabel = viewModel.inviteShareLabel { Text(inviteLabel) }
            Button("Moderação & Segurança", systemImage: "shield.lefthalf.filled") { viewModel.isShowingModerationPanel.toggle() }
            if viewModel.canShareInvite {
                Button("Redefinir Código de Convite", systemImage: "arrow.clockwise") { Task { await viewModel.resetInviteCode() } }
            }
        } label: {
            Image(systemName: "ellipsis").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .trailing)
        }
        .accessibilityLabel("Mais opções")
    }

    @ViewBuilder
    private var activeSubTabContent: some View {
        switch viewModel.selectedSubTab {
        case .feed:
            quickWitnessCard
            feedSection
        case .progress:
            GroupProgressTabView(
                summary: viewModel.scoringSummary, guardianAngelState: viewModel.guardianAngelState,
                onOptInGuardianAngel: { Task { await viewModel.optInGuardianAngel() } },
                onSendGuardianAngelNudge: { Task { await viewModel.sendGuardianAngelPrayerNudge() } },
                onRevealGuardianAngelCycle: { Task { await viewModel.revealGuardianAngelCycle() } }
            )
            recentCommunionSection
        case .intentions:
            GroupPrayerWallTabView(
                newIntentionDraft: $viewModel.newPrayerIntentionDraft, intentions: viewModel.prayerIntentions,
                errorMessage: viewModel.errorMessage,
                onSubmitIntention: { Task { await viewModel.submitPrayerIntention() } },
                onTogglePrayed: { intentionId in Task { await viewModel.togglePrayedForIntention(intentionId) } }
            )
        case .chat:
            GroupChatTabView(
                pinnedNotice: viewModel.pinnedNotice, messages: viewModel.chatMessages,
                isEditingNotice: $viewModel.isEditingPinnedNotice, noticeDraft: $viewModel.pinnedNoticeDraft,
                messageDraft: $viewModel.chatMessageDraft, errorMessage: viewModel.errorMessage,
                onSaveNotice: { Task { await viewModel.savePinnedNotice() } },
                onSendMessage: { Task { await viewModel.sendChatMessage() } }
            )
        }
    }

    private var recentCommunionSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Text("Comunhão Recente").font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Button("Ver tudo") { viewModel.selectedSubTab = .feed }
                    .font(MassMatesFont.callout).foregroundStyle(theme.tint).buttonStyle(.plain)
            }
            ForEach(viewModel.feedItems.prefix(2)) { item in feedItemView(for: item, showsComments: false) }
            SponsoredNativeCardView(
                sponsorName: "Livraria Paulus", headline: "Livraria Paulus — Retiro Inaciano Guiado",
                bodyText: "Caderno de oração para 30 dias de discernimento e exercícios espirituais no lar.",
                couponCode: "Edição especial com capa em linho • Conhecer"
            )
        }
    }
}

#Preview("Group Detail — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupDetailView(viewModel: GroupDetailViewModel(group: CommunitySampleData.parishFraternity))
    }
}
