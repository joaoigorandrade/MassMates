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
            topBar
            if viewModel.isAudioPlayerVisible {
                audioPlayerBanner
            }
            readingNavigationTabs
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")

            Spacer()

            trailingControls
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.vertical, MassMatesSpacing.xxs)
    }

    private var trailingControls: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Button {
                viewModel.cycleFontSizePreset()
            } label: {
                Text("Aa")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajustar tamanho da fonte")

            Button {
                viewModel.toggleAudioPlayerBanner()
            } label: {
                Image(systemName: viewModel.isAudioPlaying ? "waveform" : "speaker.wave.2")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(viewModel.isAudioPlayerVisible ? theme.tint : MassMatesPalette.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Áudio da Palavra")
        }
    }

    private var readingNavigationTabs: some View {
        HStack(spacing: MassMatesSpacing.lg) {
            ForEach(DailyReadingSection.allCases) { section in
                navigationTabItem(for: section)
            }
        }
        .padding(.top, MassMatesSpacing.xs)
        .padding(.bottom, MassMatesSpacing.sm)
        .frame(maxWidth: .infinity)
    }

    private func navigationTabItem(for section: DailyReadingSection) -> some View {
        let isSelected = viewModel.selectedSection == section
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSection = section
            }
        } label: {
            VStack(spacing: 4) {
                Text(section.rawValue)
                    .font(MassMatesFont.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                    .padding(.bottom, 2)
                Rectangle()
                    .fill(isSelected ? theme.tint : Color.clear)
                    .frame(height: 2)
                    .clipShape(.rect(cornerRadius: 1))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
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
            Button {
                viewModel.toggleAudioPlayerBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.bottom, MassMatesSpacing.xs)
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
