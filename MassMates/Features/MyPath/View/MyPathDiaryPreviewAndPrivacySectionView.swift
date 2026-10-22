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
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            navigationRowsSection
            closingSaintQuoteSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var navigationRowsSection: some View {
        VStack(spacing: 0) {
            hairline
            diaryRow
            hairline
            mercyRow
            hairline
            themesRow
            hairline
        }
    }

    private var diaryRow: some View {
        Button(action: onOpenDiary) {
            HStack(spacing: MassMatesSpacing.sm) {
                Image(systemName: "lock")
                    .font(.system(size: 20))
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 24)
                Text("Diário Espiritual Protegido (Face ID)")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var mercyRow: some View {
        Button(action: onOpenSettings) {
            HStack(spacing: MassMatesSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Misericórdia da sequência")
                        .font(MassMatesFont.body)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Assista 1 vídeo")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var themesRow: some View {
        Button(action: onOpenSettings) {
            HStack(spacing: MassMatesSpacing.sm) {
                Text("Temas & Ícones")
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var closingSaintQuoteSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
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

    private var hairline: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }
}

#Preview("My Path Diary Preview & Privacy — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        MyPathDiaryPreviewAndPrivacySectionView(onOpenDiary: {}, onOpenSettings: {})
    }
}
