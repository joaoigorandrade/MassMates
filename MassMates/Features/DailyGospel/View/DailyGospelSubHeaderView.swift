import SwiftUI

struct DailyGospelSubHeaderView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: DailyGospelViewModel
    private let onClose: () -> Void

    // MARK: - Init
    init(viewModel: DailyGospelViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            subHeaderBar
            if viewModel.isAudioPlayerVisible {
                audioPlayerBanner
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var subHeaderBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
            Spacer()
            VStack(spacing: 4) {
                Text("Liturgia Diária")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Capsule()
                    .fill(theme.tint)
                    .frame(width: 28, height: 2)
            }
            Spacer()
            trailingControls
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.vertical, MassMatesSpacing.xs)
        .background(MassMatesPalette.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
    }

    private var trailingControls: some View {
        HStack(spacing: MassMatesSpacing.xxs) {
            Button {
                viewModel.cycleFontSizePreset()
            } label: {
                Text("AA")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajustar tamanho da fonte")
            Button {
                viewModel.toggleAudioPlayerBanner()
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.tint)
                    .frame(width: 40, height: 40)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ouvir leitura")
        }
    }

    private var audioPlayerBanner: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Button {
                viewModel.toggleAudioPlayback()
            } label: {
                Image(systemName: viewModel.isAudioPlaying ? "pause.fill" : "play.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.onTint)
                    .frame(width: 32, height: 32)
                    .background(theme.tint)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text("Áudio da Palavra")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Voz serena • 03:15")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            Spacer()
            Text("0:42 / 3:15")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Button {
                viewModel.toggleAudioPlayerBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.top, MassMatesSpacing.sm)
    }
}

#Preview("Daily Gospel Sub-Header — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DailyGospelSubHeaderView(
            viewModel: DailyGospelViewModel(
                reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime)
            ),
            onClose: {}
        )
    }
}
