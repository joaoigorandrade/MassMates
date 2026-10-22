import PhotosUI
import SwiftUI
import UIKit

struct CheckInSafeguardAndNoteSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable private var viewModel: NewCheckInViewModel
    @State private var selectedPickerItem: PhotosPickerItem?
    private let activeStreakDays: Int

    // MARK: - Init
    init(viewModel: NewCheckInViewModel, activeStreakDays: Int = 14) {
        self.viewModel = viewModel
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            sectionHeader
            textContainer
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack {
            Text("FRUTO DA ORAÇÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.5)
            Spacer()
            if viewModel.isDestinationLockedToPrivateDiary {
                Label("Sigilo", systemImage: "lock.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private var textContainer: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            TextField(
                "O que você ouviu ou sentiu na oração hoje? (opcional)",
                text: $viewModel.fruitOfPrayer,
                axis: .vertical
            )
            .font(MassMatesFont.callout)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .lineLimit(3...6)
            .frame(minHeight: 80, alignment: .topLeading)

            if viewModel.selectedPhotoData != nil {
                photoCaptionField
            }

            bottomToolsRow
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.button)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var photoCaptionField: some View {
        TextField("Legenda da foto (opcional)", text: $viewModel.photoCaption)
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textSecondary)
    }

    private var bottomToolsRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            if let photoData = viewModel.selectedPhotoData, let uiImage = UIImage(data: photoData) {
                photoThumbnail(uiImage: uiImage)
            }
            Spacer()
            photoPickerButton
        }
    }

    private func photoThumbnail(uiImage: UIImage) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(.rect(cornerRadius: 8))

            Button {
                viewModel.selectedPhotoData = nil
                selectedPickerItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remover foto")
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPickerItem, matching: .images) {
            Image(systemName: "camera")
                .font(.system(size: 18))
                .foregroundStyle(MassMatesPalette.textTertiary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Anexar foto")
        .onChange(of: selectedPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.selectedPhotoData = data
                }
            }
        }
    }
}

#Preview("Check-In Safeguard & Note Section — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CheckInSafeguardAndNoteSectionView(
            viewModel: NewCheckInViewModel(preselectedPractice: .confession),
            activeStreakDays: 14
        )
    }
}
