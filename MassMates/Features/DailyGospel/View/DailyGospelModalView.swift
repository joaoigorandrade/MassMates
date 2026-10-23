import Navigation
import SwiftUI

struct DailyGospelModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: DailyGospelViewModel
    @State private var isShowingLectio = false

    // MARK: - Init
    init(viewModel: DailyGospelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            if isShowingLectio {
                lectioView
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            } else {
                pagedReadingView
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: isShowingLectio)
    }

    // MARK: - Subviews / Private Helpers
    private var pagedReadingView: some View {
        VStack(spacing: 0) {
            DailyGospelSubHeaderView(viewModel: viewModel) {
                navigator?.dismiss()
            }
            .equatable()
            readingTabView
            bottomBar
        }
    }

    private var readingTabView: some View {
        TabView(selection: $viewModel.selectedSection) {
            ForEach(DailyReadingSection.allCases) { section in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                        pericopeHeader(for: section)
                        articleContent(for: section)
                        sacredAcclamation(for: section)
                    }
                    .padding(.horizontal, MassMatesLayout.readingMargin)
                    .padding(.vertical, MassMatesSpacing.md)
                    .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .tag(section)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func pericopeHeader(for section: DailyReadingSection) -> some View {
        let reference = switch section {
        case .firstReading: viewModel.reading.firstReadingReference.uppercased()
        case .psalm: viewModel.reading.psalmReference.uppercased()
        case .gospel: viewModel.reading.gospelReference.uppercased()
        }
        let title = switch section {
        case .firstReading: viewModel.reading.firstReadingTitle
        case .psalm: viewModel.reading.psalmRefrain
        case .gospel: viewModel.reading.gospelTitle
        }
        return VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Rectangle().fill(theme.tint).frame(width: 32, height: 1)
                .padding(.bottom, 2)
            Text(reference).font(MassMatesFont.caption).tracking(1.0).foregroundStyle(MassMatesPalette.textSecondary)
            Text(title).font(MassMatesFont.displayMobile).foregroundStyle(MassMatesPalette.textPrimary)
            if section == .gospel {
                Text("Proclamação do Evangelho de Jesus Cristo").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func articleContent(for section: DailyReadingSection) -> some View {
        switch section {
        case .firstReading:
            scriptureText(viewModel.reading.firstReadingText)
        case .psalm:
            Text(viewModel.reading.psalmRefrain)
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize, italic: true))
                .lineSpacing(viewModel.scriptureFontSize * 0.42)
                .foregroundStyle(MassMatesPalette.textPrimary)
            scriptureText(viewModel.reading.psalmVerses)
        case .gospel:
            scriptureText(viewModel.reading.gospelText)
        }
    }

    private func scriptureText(_ text: String) -> some View {
        Text(text)
            .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize))
            .lineSpacing(viewModel.scriptureFontSize * 0.42)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sacredAcclamation(for section: DailyReadingSection) -> some View {
        let isGospel = section == .gospel
        return VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Rectangle().fill(MassMatesPalette.line.opacity(0.5)).frame(height: 1)
            Text(isGospel ? "— Palavra da Salvação." : "— Palavra do Senhor.")
                .font(MassMatesFont.customScripture(size: 16, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(isGospel ? "— Glória a Vós, Senhor." : "— Graças a Deus.")
                .font(MassMatesFont.customScripture(size: 16))
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .padding(.top, MassMatesSpacing.sm)
    }

    private var bottomBar: some View {
        HStack {
            pageIndicators
            Spacer()
            lectioButton
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .frame(height: MassMatesLayout.minRowHeight)
    }

    private var pageIndicators: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            ForEach(DailyReadingSection.allCases) { section in
                let isCurrent = viewModel.selectedSection == section
                Capsule()
                    .fill(isCurrent ? theme.tint : MassMatesPalette.line)
                    .frame(width: isCurrent ? 18 : 6, height: 6)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75),
                        value: viewModel.selectedSection
                    )
            }
        }
    }

    private var lectioButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) { isShowingLectio = true }
        } label: {
            HStack(spacing: MassMatesSpacing.xxs) {
                Text("Lectio Divina")
                Text("→")
            }
            .font(MassMatesFont.callout)
            .fontWeight(.medium)
            .foregroundStyle(theme.tint)
            .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .buttonStyle(MassMatesPressableButtonStyle())
    }

    private var lectioView: some View {
        LectioDivinaAccordionSectionView(viewModel: viewModel) {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) { isShowingLectio = false }
        }
    }
}

#Preview("Daily Gospel Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DailyGospelModalView(viewModel: DailyGospelViewModel(reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime)))
    }
}
