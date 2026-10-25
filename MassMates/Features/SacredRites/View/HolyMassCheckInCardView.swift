import SwiftUI

struct HolyMassCheckInCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.sharedCheckInEngine) private var sharedCheckInEngine
    @Environment(\.onCompleteSpiritualPractice) private var onCompletePractice
    @Bindable private var viewModel: HolyMassGuideViewModel

    // MARK: - Init
    init(viewModel: HolyMassGuideViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        MassMatesCard {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                header
                registerButton
                if viewModel.isMassCheckedIn { successBanner }
                diaryToggleButton
                if viewModel.isHomilyDiaryExpanded { homilyDiaryCard }
                if let message = viewModel.diarySavedMessage {
                    Text(message)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(MassMatesPalette.textSecondary)
                }
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var header: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(theme.onTint)
                .frame(width: 40, height: 40)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text("Fruto Espiritual da Missa")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Consagre sua participação eucarística deste domingo.")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
    }

    private var registerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { viewModel.celebrateMassCheckIn() }
            onCompletePractice(.holyMass)
        } label: {
            Label(viewModel.registerMassButtonTitle, systemImage: viewModel.registerMassButtonIcon)
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.onTint)
                .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
                .background(theme.tint)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isMassCheckedIn)
        .opacity(viewModel.isMassCheckedIn ? 0.5 : 1)
    }

    private var successBanner: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Label("Presença Registrada com Graça!", systemImage: "face.smiling")
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.tint)
            Text("+1 Domingo na sua Regra de Vida. Permanência em Cristo renovada.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
        }
        .padding(MassMatesSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tintSoft)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
    }

    private var diaryToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggleDiaryModal() }
        } label: {
            HStack {
                Label("Salvar reflexão da homilia no Diário", systemImage: "square.and.pencil")
                    .font(MassMatesFont.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: MassMatesSpacing.xs)
                Label("Sigilo", systemImage: "lock.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(MassMatesPalette.textPrimary)
            .padding(.horizontal, MassMatesSpacing.md)
            .frame(maxWidth: .infinity, minHeight: MassMatesLayout.primaryButtonHeight)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        }
        .buttonStyle(.plain)
    }

    private var homilyDiaryCard: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Text("Reflexão Pessoal da Homilia")
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Button { viewModel.toggleDiaryModal() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MassMatesPalette.textTertiary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fechar")
            }
            Text("O que o Senhor falou ao seu coração através do Evangelho ou da homilia hoje?")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            homilyEditor
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.button))
        .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.button).stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var homilyEditor: some View {
        VStack(alignment: .trailing, spacing: MassMatesSpacing.xs) {
            TextField("Escreva com serenidade seus propósitos da semana...", text: $viewModel.homilyNoteText, axis: .vertical)
                .lineLimit(3...6)
                .font(MassMatesFont.callout)
                .padding(MassMatesSpacing.sm)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            Button { Task { await viewModel.saveDiaryNote(checkInEngine: sharedCheckInEngine) } } label: {
                Label("Salvar no Diário", systemImage: "square.and.arrow.down")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(theme.onTint)
                    .padding(.horizontal, MassMatesSpacing.md)
                    .frame(minHeight: MassMatesLayout.minTapTarget)
                    .background(theme.tint)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Holy Mass Check-In — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassCheckInCardView(viewModel: HolyMassGuideViewModel())
            .padding()
    }
}
