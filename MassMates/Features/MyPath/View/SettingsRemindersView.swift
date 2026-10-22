import SwiftUI

struct SettingsRemindersView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let viewModel: SettingsViewModel
    private let onBack: () -> Void

    // MARK: - Init
    init(viewModel: SettingsViewModel, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topNavigationArea
            hairline
            remindersList
            Spacer(minLength: 0)
            bottomNoteSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(MassMatesFont.headline)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                        .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)

            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Lembretes")
                    .font(MassMatesFont.display)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("Toques discretos para recolhimento e oração diária.")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)
            .padding(.top, MassMatesSpacing.xs)
            .padding(.bottom, MassMatesSpacing.md)
        }
    }

    private var remindersList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.reminders) { item in
                reminderRow(item: item)
            }
        }
    }

    private func reminderRow(item: LiturgicalReminderItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: MassMatesSpacing.sm) {
                Text(item.title)
                    .font(MassMatesFont.body)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Spacer()
                Text(item.timeLabel)
                    .font(MassMatesFont.callout.monospacedDigit())
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Toggle("", isOn: Binding(
                    get: { item.isEnabled },
                    set: { _ in viewModel.toggleReminder(item.id) }
                ))
                .labelsHidden()
                .tint(theme.tint)
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .padding(.horizontal, MassMatesLayout.screenMargin)
            hairline
        }
    }

    private var bottomNoteSection: some View {
        VStack(spacing: MassMatesSpacing.sm) {
            Text("Notificações respeitam os modos Foco e Silencioso.")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .padding(.bottom, MassMatesSpacing.lg)
    }

    private var hairline: some View {
        Rectangle().fill(MassMatesPalette.line).frame(height: 1)
    }
}

#Preview("Settings Reminders — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        SettingsRemindersView(viewModel: SettingsViewModel(), onBack: {})
    }
}
