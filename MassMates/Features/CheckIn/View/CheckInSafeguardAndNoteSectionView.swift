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
            cardContainer
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack {
            Text("FRUTO DA ORAÇÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .tracking(0.6)
            Spacer()
            if viewModel.isDestinationLockedToPrivateDiary {
                Label("Sigilo", systemImage: "lock.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private var cardContainer: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            TextField(
                "O que Deus falou ao seu coração?",
                text: $viewModel.fruitOfPrayer,
                axis: .vertical
            )
            .font(MassMatesFont.scripture)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .lineLimit(3...4)
            .frame(minHeight: 88, alignment: .topLeading)

            Divider()
                .overlay(MassMatesPalette.line)

            bottomActionRow
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.card)
                .stroke(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private var bottomActionRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            if let thumbnail = viewModel.selectedPhotoThumbnail {
                photoThumbnail(uiImage: thumbnail)
            } else {
                photoPickerButton
            }
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Group {
            if viewModel.isDestinationLockedToPrivateDiary {
                Text("Privado")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            } else {
                Text("Opcional")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private func photoThumbnail(uiImage: UIImage) -> some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(.rect(cornerRadius: 6))

            Button {
                viewModel.selectedPhotoData = nil
                selectedPickerItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remover foto")
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPickerItem, matching: .images) {
            HStack(spacing: 6) {
                Image(systemName: "camera")
                    .font(.system(size: 14))
                Text("Adicionar foto")
                    .font(MassMatesFont.caption)
            }
            .foregroundStyle(MassMatesPalette.textSecondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Adicionar foto")
        .onChange(of: selectedPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await viewModel.setPhotoData(data)
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
