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
                    liturgicalTitleBlock
                    sacredArtBanner
                    scriptureArticleSection
                    Rectangle().fill(MassMatesPalette.line).frame(height: 1)
                    LectioDivinaAccordionSectionView(viewModel: viewModel)
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
    private var liturgicalTitleBlock: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            HStack(spacing: 6) {
                Circle().fill(theme.tint).frame(width: 6, height: 6)
                Text(viewModel.reading.liturgicalDateLabel).font(MassMatesFont.caption).foregroundStyle(theme.tint)
            }
            .padding(.horizontal, MassMatesSpacing.sm)
            .padding(.vertical, 4)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            Text(viewModel.reading.dateHeaderLabel).font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
            Text(viewModel.reading.gospelTitle)
                .font(MassMatesFont.display)
                .multilineTextAlignment(.center)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("(\(viewModel.reading.gospelReference))").font(MassMatesFont.callout).foregroundStyle(MassMatesPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var sacredArtBanner: some View {
        ZStack(alignment: .bottomLeading) {
            MassMatesPalette.surfaceMuted
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Image(systemName: "book.pages.fill").font(MassMatesFont.title).foregroundStyle(theme.tint)
                Text("A comunhão dos discípulos na caridade").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(MassMatesSpacing.md)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 176)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay { RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1) }
    }

    private var scriptureArticleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            Text("Naquele tempo, disse Jesus aos seus discípulos: \(Text("“Se o teu irmão pecar contra ti, vai corrigi-lo a sós com ele!”").foregroundStyle(theme.tint).fontWeight(.semibold)) Se ele te ouvir, terás ganho o teu irmão. Se não te ouvir, toma contigo mais uma ou duas pessoas, para que toda a questão seja decidida sob a palavra de duas ou três testemunhas.\n\n“Se ele não lhes der ouvido, dize-o à Igreja. Se nem mesmo à Igreja ele ouvir, seja tratado como se fora um pagão ou um cobrador de impostos. Em verdade vos digo: tudo o que ligardes na terra será ligado no céu, e tudo o que desligardes na terra será desligado no céu.”")
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize))
                .lineSpacing(8)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            scriptureCalloutBox
            psalmResponseBox
        }
    }

    private var scriptureCalloutBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("“De novo vos digo: se dois de vós estiverem de acordo na terra sobre qualquer coisa que quiserem pedir, isso lhes será concedido por meu Pai que está nos céus. \(Text("Pois onde dois ou três estiverem reunidos em meu nome, eu estou aí, no meio deles.”").foregroundStyle(theme.tint))")
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize))
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
        .lineSpacing(8)
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay { RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1) }
    }

    private var psalmResponseBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(viewModel.reading.psalmReference.uppercased()).font(MassMatesFont.caption).foregroundStyle(theme.tint)
            Text(viewModel.reading.psalmRefrain)
                .font(MassMatesFont.customScripture(size: viewModel.scriptureFontSize, italic: true))
                .foregroundStyle(MassMatesPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MassMatesSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft.opacity(0.7))
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay { RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(theme.tint.opacity(0.2), lineWidth: 1) }
    }

    private var completionFooterSection: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            MassMatesPrimaryButton(
                title: viewModel.hasCompletedFruitRegistration ? "Fruto Registrado!" : "Concluir & Registrar Fruto",
                systemImage: viewModel.hasCompletedFruitRegistration ? "checkmark" : "checkmark.circle"
            ) {
                viewModel.completeAndReflect()
            }
            Text("Marca a prática na sua Regra de Vida e abre o registro de fruto.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
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
