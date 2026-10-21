import SwiftUI

struct MyPathDiaryPreviewAndPrivacySectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let onOpenDiary: () -> Void
    private let onOpenSettings: () -> Void

    // MARK: - Init
    init(
        onOpenDiary: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.onOpenDiary = onOpenDiary
        self.onOpenSettings = onOpenSettings
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
            recentFruitsSection
            sacredPrivacyCard
            closingSaintQuoteSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var recentFruitsSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(theme.tint)
                    Text("Frutos Recentes da Oração")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(MassMatesFont.caption)
                    Text("PRIVADO")
                        .font(MassMatesFont.caption)
                }
                .foregroundStyle(MassMatesPalette.textTertiary)
            }
            intimateNotePreviewCard(
                dateLabel: "12 de Outubro",
                quote: "“No silêncio da manhã, senti profunda consolação diante do Evangelho dos talentos. A confiança do Pai me basta.”"
            )
            intimateNotePreviewCard(
                dateLabel: "08 de Outubro",
                quote: "“Ofereci o terço pelas aflições do meu irmão fraterno Mateus. Senti grande paz ao rezar a Salve Rainha por sua família.”"
            )
            MassMatesSecondaryButton(
                title: "Ver Todo o Diário de Graças (42 registros)",
                systemImage: "book.closed.fill",
                action: onOpenDiary
            )
        }
    }

    private func intimateNotePreviewCard(dateLabel: String, quote: String) -> some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
                HStack {
                    Text(dateLabel)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 10))
                        Text("Neste aparelho")
                            .font(MassMatesFont.caption)
                    }
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 2)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                }
                Text(quote)
                    .font(MassMatesFont.customScripture(size: 16, italic: true))
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
        }
    }

    private var sacredPrivacyCard: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
                    Image(systemName: "shield.fill")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(theme.tint)
                        .frame(width: 40, height: 40)
                        .background(theme.tintSoft)
                        .clipShape(.circle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sigilo Sagrado por Padrão")
                            .font(MassMatesFont.headline)
                            .foregroundStyle(MassMatesPalette.textPrimary)
                        Text("Seus registros íntimos estão criptografados na memória deste celular. Nenhuma reflexão ou confissão é transmitida para nuvens externas.")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(MassMatesPalette.textSecondary)
                    }
                }
                VStack(spacing: MassMatesSpacing.xs) {
                    faceIdStatusRow
                    privacyActionButton(icon: "square.and.arrow.up", title: "Exportar Diário em PDF ou Texto", action: onOpenDiary)
                    privacyActionButton(icon: "icloud.and.arrow.down", title: "Gerenciar Backup Local", action: onOpenSettings)
                }
            }
        }
    }

    private var faceIdStatusRow: some View {
        HStack {
            Label("Autenticação por Face ID", systemImage: "faceid")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            Text("Ativada")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .padding(.horizontal, MassMatesSpacing.xs)
                .padding(.vertical, 2)
                .background(theme.tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func privacyActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .padding(MassMatesSpacing.sm)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        }
        .buttonStyle(.plain)
    }

    private var closingSaintQuoteSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "quote.opening")
                .font(MassMatesFont.title)
                .foregroundStyle(theme.tint)
            Text("“A perseverança não é uma virtude que se improvisa, mas um dom que se pede a cada manhã.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
            Text("— SÃO JOSEMARIA ESCRIVÁ")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MassMatesSpacing.sm)
    }
}

#Preview("My Path Diary Preview & Privacy — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathDiaryPreviewAndPrivacySectionView(onOpenDiary: {}, onOpenSettings: {})
    }
}
