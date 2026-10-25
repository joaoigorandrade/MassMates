import SwiftUI

struct GroupPrayerWallTabView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Binding private var newIntentionDraft: String
    private let intentions: [PrayerIntention]
    private let errorMessage: String?
    private let onSubmitIntention: () -> Void
    private let onTogglePrayed: (String) -> Void

    // MARK: - Init
    init(
        newIntentionDraft: Binding<String>,
        intentions: [PrayerIntention],
        errorMessage: String?,
        onSubmitIntention: @escaping () -> Void,
        onTogglePrayed: @escaping (String) -> Void
    ) {
        self._newIntentionDraft = newIntentionDraft
        self.intentions = intentions
        self.errorMessage = errorMessage
        self.onSubmitIntention = onSubmitIntention
        self.onTogglePrayed = onTogglePrayed
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            SponsoredBannerView(
                sponsorTitle: "Apostolado da Oração",
                message: "Intenções mensais do Papa e subsídios para os grupos paroquiais."
            )
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            composerCard
            intentionsListSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var composerCard: some View {
        let isDraftEmpty = newIntentionDraft.trimmingCharacters(in: .whitespaces).isEmpty
        return MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Text("Confiar intenção à comunidade • \(theme.season.defaultSeasonName)")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                TextField("Escreva seu pedido de oração com serenidade", text: $newIntentionDraft)
                    .padding(MassMatesSpacing.sm)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                if let errorMessage {
                    Text(errorMessage)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.danger)
                }
                MassMatesPrimaryButton(
                    title: "Publicar no Mural de Intenções",
                    systemImage: "hands.sparkles"
                ) {
                    guard !isDraftEmpty else { return }
                    onSubmitIntention()
                }
                .disabled(isDraftEmpty)
                .opacity(isDraftEmpty ? 0.5 : 1.0)
            }
        }
    }

    private var intentionsListSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Mural de Orações")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(intentions) { intention in
                GroupPrayerIntentionRowView(intention: intention) {
                    onTogglePrayed(intention.id)
                }
            }
        }
    }
}

struct GroupPrayerIntentionRowView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let intention: PrayerIntention
    private let onTogglePrayed: () -> Void

    // MARK: - Init
    init(intention: PrayerIntention, onTogglePrayed: @escaping () -> Void) {
        self.intention = intention
        self.onTogglePrayed = onTogglePrayed
    }

    nonisolated static func == (lhs: GroupPrayerIntentionRowView, rhs: GroupPrayerIntentionRowView) -> Bool {
        lhs.intention == rhs.intention
    }

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                authorHeader
                Text(intention.intentionText)
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                reactionRow
                if let comfort = intention.lastComfortNotificationText {
                    Text(comfort)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var authorHeader: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text(intention.authorInitials)
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 32, height: 32)
                .background(theme.tintSoft)
                .clipShape(Circle())
            Text(intention.authorName)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(intention.relativeTimeLabel)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
    }

    private var reactionRow: some View {
        HStack {
            ReactionPillButton(
                title: "Rezei por você",
                systemImage: "hands.sparkles",
                count: intention.prayedCount,
                isActive: intention.hasCurrentUserPrayed,
                action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onTogglePrayed()
                }
            )
            Spacer()
        }
    }
}

#Preview("Group Prayer Wall Tab — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupPrayerWallTabView(
            newIntentionDraft: .constant(""),
            intentions: CommunitySampleData.initialPrayerIntentions(for: "frat-sao-jose"),
            errorMessage: nil,
            onSubmitIntention: {},
            onTogglePrayed: { _ in }
        )
    }
}
