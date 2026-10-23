import SwiftUI

struct LiturgicalSeasonPreviewMatrix<Content: View>: View {
    // MARK: - Dependencies & State
    private let content: (LiturgicalColor) -> Content

    // MARK: - Init
    init(@ViewBuilder content: @escaping (LiturgicalColor) -> Content) {
        self.content = content
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                sectionBlock(title: "Light", scheme: .light, sizeCategory: .large)
                sectionBlock(title: "Dark", scheme: .dark, sizeCategory: .large)
                sectionBlock(title: "AX3 Dynamic Type", scheme: .light, sizeCategory: .accessibilityExtraExtraExtraLarge)
            }
            .padding(MassMatesLayout.screenMargin)
        }
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private func sectionBlock(
        title: String,
        scheme: ColorScheme,
        sizeCategory: ContentSizeCategory
    ) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text(title)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            ForEach(LiturgicalColor.allCases) { season in
                seasonRow(for: season)
            }
        }
        .padding(MassMatesSpacing.md)
        .environment(\.colorScheme, scheme)
        .environment(\.sizeCategory, sizeCategory)
        .background(MassMatesPalette.bg)
    }

    private func seasonRow(for season: LiturgicalColor) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text(season.defaultSeasonName)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            content(season)
                .environment(\.liturgicalTheme, Theme(season: season))
        }
    }
}
