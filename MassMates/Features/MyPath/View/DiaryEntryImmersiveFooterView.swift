import SwiftUI

struct DiaryEntryImmersiveFooterView: View {
    // MARK: - Dependencies & State
    private let virtues: [String]
    private let onShareFruit: () -> Void
    private let onAddToExamen: () -> Void
    private let onAddNote: () -> Void

    // MARK: - Init
    init(
        virtues: [String] = [],
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
        VStack(spacing: MassMatesSpacing.md) {
            hairlineDivider
            privacyConfirmation
        }
        .padding(.top, MassMatesSpacing.md)
        .padding(.bottom, 40)
    }

    // MARK: - Subviews / Private Helpers
    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private var privacyConfirmation: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .regular))
            Text("Somente neste dispositivo")
                .font(MassMatesFont.caption)
        }
        .foregroundStyle(MassMatesPalette.textSecondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("Immersive Reader Footer — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryImmersiveFooterView()
            .padding(.horizontal, MassMatesLayout.readingMargin)
            .background(MassMatesPalette.bg)
    }
}
