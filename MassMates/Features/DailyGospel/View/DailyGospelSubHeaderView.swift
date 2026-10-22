import SwiftUI

struct DailyGospelSubHeaderView: View, Equatable {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Bindable var viewModel: DailyGospelViewModel
    private let onClose: () -> Void

    // MARK: - Init
    init(viewModel: DailyGospelViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    nonisolated static func == (lhs: DailyGospelSubHeaderView, rhs: DailyGospelSubHeaderView) -> Bool {
        MainActor.assumeIsolated {
            lhs.viewModel === rhs.viewModel &&
            lhs.viewModel.selectedSection == rhs.viewModel.selectedSection
        }
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
        .background(MassMatesPalette.bg)
    }

    // MARK: - Subviews / Private Helpers
    private var topBar: some View {
        HStack(spacing: 0) {
            closeButton
            Spacer(minLength: MassMatesSpacing.xs)
            segmentedReadingSwitcher
            Spacer(minLength: MassMatesSpacing.xs)
            fontSizeButton
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .frame(height: MassMatesLayout.minRowHeight)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fechar Leitura")
    }

    private var fontSizeButton: some View {
        Button {
            viewModel.cycleFontSizePreset()
        } label: {
            Text("Aa")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ajustar Tipografia")
    }

    private var segmentedReadingSwitcher: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            readingSegment(for: .firstReading)
            dotSeparator
            readingSegment(for: .psalm)
            dotSeparator
            readingSegment(for: .gospel)
        }
    }

    private func readingSegment(for section: DailyReadingSection) -> some View {
        let isSelected = viewModel.selectedSection == section
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSection = section
            }
        } label: {
            VStack(spacing: 3) {
                Text(section.rawValue)
                    .font(isSelected ? MassMatesFont.headline : MassMatesFont.caption)
                    .foregroundStyle(isSelected ? MassMatesPalette.textPrimary : MassMatesPalette.textSecondary)
                    .padding(.horizontal, 2)
                    .padding(.top, 4)
                Rectangle()
                    .fill(isSelected ? theme.tint : Color.clear)
                    .frame(height: 1.5)
                    .clipShape(.rect(cornerRadius: 1))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var dotSeparator: some View {
        Text("·")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textTertiary)
            .accessibilityHidden(true)
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
