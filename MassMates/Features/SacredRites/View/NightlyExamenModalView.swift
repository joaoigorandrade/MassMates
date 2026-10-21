import Navigation
import SwiftUI

struct NightlyExamenModalView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @OptionalNavigator<AppRoute> private var navigator
    @State private var viewModel: NightlyExamenViewModel

    // MARK: - Init
    init(viewModel: NightlyExamenViewModel = NightlyExamenViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body / Public API
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MassMatesSpacing.lg) {
                headerToolbar
                nightContextSection
                invocationalScriptureFrame
                ignatianProgressSection
                NightlyExamenStepCardsView(viewModel: viewModel)
                NightlyExamenReviewAndClosingView(viewModel: viewModel)
                NightlyExamenFooterSectionView(viewModel: viewModel)
            }
            .padding(MassMatesLayout.readingMargin)
            .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var headerToolbar: some View {
        HStack {
            Button {
                navigator?.dismiss()
            } label: {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: "chevron.left")
                    Text("Concluir")
                }
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("Exame Da Noite")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: "lock.fill").foregroundStyle(theme.tint)
                    Text("Sigilo Sagrado Local").foregroundStyle(MassMatesPalette.textTertiary)
                }
                .font(MassMatesFont.caption)
            }
            Spacer()
            Image(systemName: "person.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.onTint)
                .frame(width: 32, height: 32)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
        }
    }

    private var nightContextSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            HStack {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: "moon.fill").foregroundStyle(theme.tint)
                    Text("COMPLETAS • SÁBADO, 12 DE OUTUBRO").foregroundStyle(MassMatesPalette.textSecondary)
                }
                .font(MassMatesFont.caption)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xxs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                Spacer()
                Text(theme.season.defaultSeasonName)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
            sacredSealConscienceCard
            durationAndAmbientAudioRow
        }
    }

    private var sacredSealConscienceCard: some View {
        MassMatesCard {
            HStack(alignment: .top, spacing: MassMatesSpacing.xs) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(theme.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sigilo Inviolável da Consciência")
                        .font(MassMatesFont.callout)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    Text("Suas orações e faltas são examinadas estritamente diante de Deus. Dados 100% locais, confidenciais e criptografados no aparelho.")
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    private var durationAndAmbientAudioRow: some View {
        HStack {
            Label("7 min de recolhimento", systemImage: "hourglass")
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Button {
                viewModel.toggleAmbientAudio()
            } label: {
                HStack(spacing: MassMatesSpacing.xxs) {
                    Image(systemName: viewModel.ambientAudioSystemImage)
                        .foregroundStyle(viewModel.isAmbientMusicPlaying ? MassMatesPalette.success : theme.tint)
                    Text(viewModel.ambientAudioLabel)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
                .font(MassMatesFont.caption)
                .padding(.horizontal, MassMatesSpacing.sm)
                .padding(.vertical, MassMatesSpacing.xs)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
            .buttonStyle(.plain)
        }
    }

    private var invocationalScriptureFrame: some View {
        VStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(theme.tint)
            Text("“Em paz me deito e logo adormeço, porque só vós, Senhor, me fazeis viver seguro.”")
                .font(MassMatesFont.scriptureEmphasis)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .multilineTextAlignment(.center)
            Text("SALMO 4, 9")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var ignatianProgressSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            HStack {
                Text("Itinerário de Santo Inácio")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text(viewModel.stepsIndicatorText)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(viewModel.isExamenConcluded ? MassMatesPalette.success : theme.tint)
            }
            MassMatesProgressBar(progress: viewModel.progressFraction)
        }
    }
}

#Preview("Nightly Examen Modal — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        NightlyExamenModalView(viewModel: NightlyExamenViewModel())
    }
}
