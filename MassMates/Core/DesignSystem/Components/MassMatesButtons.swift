import SwiftUI

struct MassMatesPrimaryButton: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    // MARK: - Init
    init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: action) {
            buttonLabel
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.onTint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                .padding(.horizontal, MassMatesSpacing.md)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

struct MassMatesSecondaryButton: View {
    // MARK: - Dependencies & State
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    // MARK: - Init
    init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: action) {
            buttonLabel
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.minTapTarget)
                .padding(.horizontal, MassMatesSpacing.md)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

struct MassMatesTextButton: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let title: String
    private let action: () -> Void

    // MARK: - Init
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    // MARK: - Body / Public API
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
}

#Preview("Buttons — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(title: "Concluir e refletir", systemImage: "checkmark") {}
            MassMatesSecondaryButton(title: "Pausar oração") {}
            MassMatesTextButton(title: "Fechar") {}
        }
    }
}
