import SwiftUI

struct DiaryEntryImmersiveFooterView: View {
    // MARK: - Dependencies & State
    private let previousLabel: String?
    private let nextLabel: String?
    private let onPrevious: () -> Void
    private let onNext: () -> Void

    // MARK: - Init
    init(
        previousLabel: String? = nil,
        nextLabel: String? = nil,
        onPrevious: @escaping () -> Void = {},
        onNext: @escaping () -> Void = {}
    ) {
        self.previousLabel = previousLabel
        self.nextLabel = nextLabel
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: MassMatesSpacing.md) {
            if previousLabel != nil || nextLabel != nil {
                navigationChevronsRow
            }
            hairlineDivider
            privacyConfirmation
        }
        .padding(.top, MassMatesSpacing.sm)
        .padding(.bottom, MassMatesSpacing.xl)
    }

    // MARK: - Subviews / Private Helpers
    private var navigationChevronsRow: some View {
        HStack {
            if let previousLabel {
                Button(action: onPrevious) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(previousLabel)
                            .font(MassMatesFont.callout)
                    }
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reflexão anterior: \(previousLabel)")
            }

            Spacer()

            if let nextLabel {
                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text(nextLabel)
                            .font(MassMatesFont.callout)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Próxima reflexão: \(nextLabel)")
            }
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private var privacyConfirmation: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
            Text("Somente neste dispositivo")
                .font(MassMatesFont.caption)
        }
        .foregroundStyle(MassMatesPalette.textSecondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("Immersive Reader Footer — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryImmersiveFooterView(
            previousLabel: "20 Out",
            nextLabel: "22 Out"
        )
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .background(MassMatesPalette.bg)
    }
}
