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
    init(viewModel: NewCheckInViewModel, activeStreakDays: Int) {
        self.viewModel = viewModel
        self.activeStreakDays = activeStreakDays
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            if viewModel.isDestinationLockedToPrivateDiary {
                confessionSafeguardBanner
                sacredQuoteBanner
            }
            fruitAndWitnessInputSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var confessionSafeguardBanner: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.shield.fill")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.tint)
                .frame(width: 28, height: 28)
                .background(theme.tintSoft)
                .clipShape(.circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sigilo Sacramental & Intimidade")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Ao selecionar Confissão, a partilha pública é desativada automaticamente. Este registro fica salvo exclusivamente no seu Diário Espiritual protegido no aparelho.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var sacredQuoteBanner: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "flame.fill").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                Text("RECOLHIMENTO SACRAMENTAL").font(MassMatesFont.caption).foregroundStyle(theme.tint).tracking(0.5)
            }
            Text("“A paz esteja convosco. Aqueles a quem perdoardes os pecados ser-lhes-ão perdoados.” • Jo 20, 21-23")
                .font(MassMatesFont.customScripture(size: 14, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var fruitAndWitnessInputSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Text("FRUTO DA ORAÇÃO OU PENITÊNCIA").font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary).tracking(0.5)
                Spacer()
                Text(viewModel.isDestinationLockedToPrivateDiary ? "Apenas Local" : "Reflexão")
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
            inputCardContainer
        }
    }

    private var inputCardContainer: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            TextField("Notas de exame de consciência, data, penitência recebida ou graça do sacramento...",
                      text: $viewModel.fruitOfPrayer, axis: .vertical)
                .font(MassMatesFont.customScripture(size: 16))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineLimit(3...6)

            if viewModel.isDestinationLockedToPrivateDiary {
                TextField("Penitência ou orientação do confessor (opcional)", text: $viewModel.confessorOrPenanceNotes)
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            } else {
                TextField("Legenda de memória / testemunho (opcional)", text: $viewModel.photoCaption)
                    .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            attachmentFooterRow
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var attachmentFooterRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            if let photoData = viewModel.selectedPhotoData, let uiImage = UIImage(data: photoData) {
                photoThumbnailView(uiImage: uiImage)
            } else {
                photoPickerButton
            }
            Spacer()
            deviceOnlyBadge
        }
    }

    private func photoThumbnailView(uiImage: UIImage) -> some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(uiImage: uiImage).resizable().scaledToFill()
                .frame(width: 36, height: 36).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            Button {
                viewModel.selectedPhotoData = nil
                selectedPickerItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPickerItem, matching: .images) {
            HStack(spacing: MassMatesSpacing.xxs) {
                Image(systemName: "camera.badge.ellipsis")
                Text("Anexar memória")
            }
            .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            .padding(.horizontal, MassMatesSpacing.xs).padding(.vertical, 6)
            .background(MassMatesPalette.surface).clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        }
        .onChange(of: selectedPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.selectedPhotoData = data
                }
            }
        }
    }

    private var deviceOnlyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.shield")
            Text("Exclusivo para este dispositivo")
        }
        .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
    }
}

#Preview("Check-In Safeguard & Note Section — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        CheckInSafeguardAndNoteSectionView(
            viewModel: NewCheckInViewModel(preselectedPractice: .confession),
            activeStreakDays: 14
        )
    }
}
