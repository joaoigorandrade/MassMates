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
        MassMatesCard {
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
                    systemImage: "hands.sparkles",
                    action: onSubmitIntention
                )
            }
        }
    }

    private var intentionsListSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text("Mural de Orações")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            ForEach(intentions) { intention in
                intentionCard(intention)
            }
        }
    }

    private func intentionCard(_ intention: PrayerIntention) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
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
                    Spacer()
                    Text(intention.relativeTimeLabel)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Text(intention.intentionText)
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack {
                    ReactionPillButton(
                        title: "Rezei por você",
                        systemImage: "hands.sparkles",
                        count: intention.prayedCount,
                        isActive: intention.hasCurrentUserPrayed
                    ) {
                        onTogglePrayed(intention.id)
                    }
                    Spacer()
                }
                if let comfort = intention.lastComfortNotificationText {
                    Text(comfort)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                }
            }
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
