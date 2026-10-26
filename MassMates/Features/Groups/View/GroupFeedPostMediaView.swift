import SwiftUI

/// The content of a feed post: caption, spiritual reflection in book serif,
/// and optional witness photo with 12px corner radius.
struct GroupFeedPostMediaView: View, Equatable {
    // MARK: - Dependencies & State
    @State private var isShowingFullPhoto: Bool = false
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
        Button {
            withAnimation(.snappy) { isShowingFullPhoto = true }
        } label: {
            photoThumbnail(url)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ver foto do testemunho")
        .overlay {
            if isShowingFullPhoto { fullPhotoLightbox(url) }
        }
        .animation(.snappy, value: isShowingFullPhoto)
    }

    private func photoThumbnail(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill().frame(maxHeight: 180).frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo)).overlay(photoBorder)
            case .empty:
                Rectangle().fill(MassMatesPalette.surfaceMuted).frame(height: 180).frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo)).overlay(photoBorder)
            default:
                EmptyView()
            }
        }
        .contentShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private func fullPhotoLightbox(_ url: URL) -> some View {
        ZStack(alignment: .topTrailing) {
            MassMatesPalette.bg.ignoresSafeArea()
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().padding()
                default:
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                withAnimation(.snappy) {
                    isShowingFullPhoto = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
            .padding(MassMatesSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
