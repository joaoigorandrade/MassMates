import Navigation
import SwiftUI

struct DailyGospelModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: DailyGospelViewModel

    // MARK: - Init
    init(viewModel: DailyGospelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            DailyGospelSubHeaderView(viewModel: viewModel) {
                navigator?.dismiss()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                    pericopeHeaderBlock
                    scriptureArticleSection
                    if viewModel.selectedSection == .gospel {
                        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
                        LectioDivinaAccordionSectionView(viewModel: viewModel)
                    }
                    completionFooterSection
                }
                .padding(MassMatesLayout.readingMargin)
                .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isCompletionToastVisible { completionToastBanner }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var pericopeHeaderBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text(citationCategoryText)
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(currentPericopeTitle)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var citationCategoryText: String {
        switch viewModel.selectedSection {
        case .firstReading: "1ª LEITURA • \(viewModel.reading.firstReadingReference.uppercased())"
        case .psalm: "SALMO • \(viewModel.reading.psalmReference.uppercased())"
        case .gospel: "EVANGELHO • \(viewModel.reading.gospelReference.uppercased())"
        }
    }

    private var currentPericopeTitle: String {
        switch viewModel.selectedSection {
        case .firstReading: viewModel.reading.firstReadingTitle
        case .psalm: viewModel.reading.psalmReference
        case .gospel: viewModel.reading.gospelTitle
        }
    }

    private var scriptureArticleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            switch viewModel.selectedSection {
            case .firstReading:
                ForEach(scriptureParagraphs(for: viewModel.reading.firstReadingText), id: \.self) {
                    scriptureParagraphView(text: $0)
                }
            case .psalm:
                Text(viewModel.reading.psalmRefrain)
                    .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize, italic: true))
                    .lineSpacing(viewModel.scriptureFontSize * 0.42)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                ForEach(scriptureParagraphs(for: viewModel.reading.psalmVerses), id: \.self) {
                    scriptureParagraphView(text: $0)
                }
            case .gospel:
                gospelContent
            }
        }
    }

    private var gospelContent: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            ForEach(scriptureParagraphs(for: viewModel.reading.gospelText), id: \.self) {
                scriptureParagraphView(text: $0)
            }
            if !viewModel.reading.gospelCalloutQuote.isEmpty {
                keyVerseCallout
            }
        }
    }

    private func scriptureParagraphs(for text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func scriptureParagraphView(text: String) -> some View {
        Text(text)
            .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize))
            .lineSpacing(viewModel.scriptureFontSize * 0.42)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyVerseCallout: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Rectangle().fill(MassMatesPalette.line).frame(width: 32, height: 1)
            Text(viewModel.reading.gospelCalloutQuote)
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize, italic: true))
                .lineSpacing(viewModel.scriptureFontSize * 0.42)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle().fill(MassMatesPalette.line).frame(width: 32, height: 1)
        }
        .padding(.vertical, MassMatesSpacing.xs)
    }

    private var completionFooterSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: viewModel.hasCompletedFruitRegistration ? "Fruto Registrado!" : "Concluir & Registrar Fruto",
                systemImage: viewModel.hasCompletedFruitRegistration ? "checkmark" : "checkmark.circle"
            ) {
                viewModel.completeAndReflect()
                navigator?.present(.newCheckIn(preselectedPractice: .dailyGospel, season: theme.season))
            }
            Text("Registra a leitura na Regra de Vida")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, MassMatesSpacing.xs)
    }

    private var completionToastBanner: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark")
                .font(MassMatesFont.callout)
                .foregroundStyle(theme.onTint)
                .frame(width: 36, height: 36)
                .background(MassMatesPalette.success)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text("Leitura Sagrada Concluída").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.surface)
                Text("Hábito registrado • Regra de Vida atualizada").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
            }
            Spacer()
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.textPrimary)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.bottom, MassMatesSpacing.lg)
    }
}

#Preview("Daily Gospel Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DailyGospelModalView(viewModel: DailyGospelViewModel(reading: LiturgicalReadingsCatalog.reading(for: .ordinaryTime)))
    }
}
