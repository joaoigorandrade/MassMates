import SwiftUI

struct DiaryEntryImmersiveFooterView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let virtues: [String]
    private let onShareFruit: () -> Void
    private let onAddToExamen: () -> Void
    private let onAddNote: () -> Void

    private let virtueColumns = [
        GridItem(.adaptive(minimum: 120), spacing: 6)
    ]

    // MARK: - Init
    init(
        virtues: [String] = ["Paz interior", "Entrega filial", "Mansidão", "Fidelidade no oculto"],
        onShareFruit: @escaping () -> Void = {},
        onAddToExamen: @escaping () -> Void = {},
        onAddNote: @escaping () -> Void = {}
    ) {
        self.virtues = virtues
        self.onShareFruit = onShareFruit
        self.onAddToExamen = onAddToExamen
        self.onAddNote = onAddNote
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            practicalResolutionCard
            fraternalCommunionCard
            saintQuoteAndActionsFooter
        }
    }

    // MARK: - Subviews / Private Helpers
    private var practicalResolutionCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                Label("Resolução Prática do Dia", systemImage: "flag.fill")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text("Em curso")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 2)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            Text("“Guardar o recolhimento nas conversas de trabalho e não alimentar queixas nem murmurações.”")
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .padding(MassMatesSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surface)
                .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            Text("VIRTUDES CULTIVADAS NESTA ORAÇÃO:")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)
            LazyVGrid(columns: virtueColumns, alignment: .leading, spacing: 6) {
                ForEach(virtues, id: \.self) { virtue in
                    virtueChip(virtue)
                }
            }
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private func virtueChip(_ title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(theme.tint).frame(width: 6, height: 6)
            Text(title)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, MassMatesSpacing.xs)
        .padding(.vertical, 4)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
    }

    private var fraternalCommunionCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                Label("Comunhão e Partilha Fraterna", systemImage: "person.2")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("O texto do seu diário permanece permanentemente restrito e seguro. Se desejar edificar seus irmãos, você pode partilhar apenas o propósito ou uma intenção geral com seu círculo de oração.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                fraternityShareRow
            }
        }
    }

    private var fraternityShareRow: some View {
        HStack {
            Image(systemName: "building.columns.fill")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(width: 36, height: 36)
                .background(theme.tintSoft)
                .clipShape(.circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Fraternidade São José")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("5 membros em oração mútua")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            Spacer()
            Button(action: onShareFruit) {
                Label("Partilhar fruto", systemImage: "paperplane.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.sm)
                    .padding(.vertical, 6)
                    .background(MassMatesPalette.surface)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            }
            .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var saintQuoteAndActionsFooter: some View {
        VStack(spacing: MassMatesSpacing.md) {
            VStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "quote.opening")
                    .font(MassMatesFont.title)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                Text("“A oração mental não é outra coisa senão um trato de amizade, estando muitas vezes a sós com Quem sabemos que nos ama.”")
                    .font(MassMatesFont.customScripture(size: 16, italic: true))
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .multilineTextAlignment(.center)
                Text("— SANTA TERESA DE JESUS")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .tracking(0.5)
            }
            .padding(MassMatesSpacing.md)
            .frame(maxWidth: .infinity)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))

            VStack(spacing: MassMatesSpacing.xs) {
                MassMatesPrimaryButton(title: "Adicionar ao Exame da Noite", systemImage: "moon.stars.fill", action: onAddToExamen)
                MassMatesSecondaryButton(title: "Acrescentar Nova Nota", systemImage: "square.and.pencil", action: onAddNote)
            }
            Label("Última sincronização local: Hoje às 06:58", systemImage: "checkmark.icloud")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }
}

#Preview("Immersive Reader Footer — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryImmersiveFooterView()
    }
}
