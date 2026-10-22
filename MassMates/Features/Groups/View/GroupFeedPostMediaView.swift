import SwiftUI

/// The content of a feed post: the caption, the fruit of the prayer and the
/// witness photo (when the server signed one).
struct GroupFeedPostMediaView: View {
    // MARK: - Dependencies & State
    private let caption: String?
    private let fruitOfPrayer: String?
    private let witnessPhotoURL: URL?

    // MARK: - Init
    init(caption: String?, fruitOfPrayer: String?, witnessPhotoURL: URL? = nil) {
        self.caption = caption
        self.fruitOfPrayer = fruitOfPrayer
        self.witnessPhotoURL = witnessPhotoURL
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            if let fruitOfPrayer, !fruitOfPrayer.isEmpty {
                Text("“\(fruitOfPrayer)”")
                    .font(MassMatesFont.scriptureEmphasis)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            if let witnessPhotoURL {
                witnessPhotoView(witnessPhotoURL)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private func witnessPhotoView(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            case .failure:
                EmptyView()
            case .empty:
                Rectangle()
                    .fill(MassMatesPalette.surfaceMuted)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            @unknown default:
                EmptyView()
            }
        }
    }
}
