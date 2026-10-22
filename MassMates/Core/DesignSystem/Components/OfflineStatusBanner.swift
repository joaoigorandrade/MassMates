import SwiftUI

/// The slim banner that tells the user the app is running on the in-memory
/// fallback because the backend is not configured.
struct OfflineStatusBanner: View {
    // MARK: - Dependencies & State
    let message: String

    // MARK: - Init
    init(message: String) {
        self.message = message
    }

    // MARK: - Body / Public API
    var body: some View {
        Text(message)
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
            .padding(.horizontal, MassMatesSpacing.md)
            .padding(.vertical, MassMatesSpacing.xs)
            .frame(maxWidth: .infinity)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.bottom, 72)
    }

    // MARK: - Subviews / Private Helpers
}
