import SwiftUI

/// The content of a feed post: caption, spiritual reflection in book serif,
/// and optional witness photo with 12px corner radius.
struct GroupFeedPostMediaView: View, Equatable {
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

    nonisolated static func == (lhs: GroupFeedPostMediaView, rhs: GroupFeedPostMediaView) -> Bool {
        lhs.caption == rhs.caption &&
        lhs.fruitOfPrayer == rhs.fruitOfPrayer &&
        lhs.witnessPhotoURL == rhs.witnessPhotoURL
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
                reflectionView(fruitOfPrayer)
            }
            if let witnessPhotoURL {
                witnessPhotoView(witnessPhotoURL)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private func reflectionView(_ text: String) -> some View {
        Text("“\(text)”")
            .font(.system(size: 17, weight: .regular, design: .serif))
            .foregroundStyle(MassMatesPalette.textPrimary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func witnessPhotoView(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                    .overlay(photoBorder)
            case .failure:
                EmptyView()
            case .empty:
                Rectangle()
                    .fill(MassMatesPalette.surfaceMuted)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                    .overlay(photoBorder)
            @unknown default:
                EmptyView()
            }
        }
    }

    private var photoBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.photo)
            .stroke(MassMatesPalette.line, lineWidth: 1)
    }
}

#Preview("Group Feed Post Media — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        GroupFeedPostMediaView(
            caption: "Hoje rezamos o Santo Terço em comunidade.",
            fruitOfPrayer: "A paz que excede todo o entendimento guardará os vossos corações.",
            witnessPhotoURL: nil
        )
        .padding()
    }
}
