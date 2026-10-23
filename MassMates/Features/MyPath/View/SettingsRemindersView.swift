import Navigation
import SwiftUI

struct SettingsRemindersView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator
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
            ScrollView(showsIndicators: false) {
                remindersList
            }
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
                Button(action: handleBack) {
                    HStack(spacing: MassMatesSpacing.xxs) {
                        Image(systemName: "chevron.left").font(MassMatesFont.headline)
                        Text("Ajustes").font(MassMatesFont.callout)
                    }
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .frame(minHeight: MassMatesLayout.minTapTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voltar")
                Spacer()
            }
            .padding(.horizontal, MassMatesLayout.screenMargin)

            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text("Lembretes e Horários")
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(MassMatesFont.body).foregroundStyle(MassMatesPalette.textPrimary)
                    Text(item.subtitle).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                }
                Spacer()
                DatePicker("", selection: bindingForReminderTime(item), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(theme.tint)
                    .accessibilityLabel("Horário de \(item.title)")

                Toggle("", isOn: Binding(
                    get: { item.isEnabled },
                    set: { _ in viewModel.toggleReminder(item.id) }
                ))
                .labelsHidden()
                .tint(theme.tint)
                .accessibilityLabel("Ativar \(item.title)")
            }
            .frame(minHeight: MassMatesLayout.minRowHeight)
            .padding(.horizontal, MassMatesLayout.screenMargin)
            hairline
        }
    }

    private func bindingForReminderTime(_ item: LiturgicalReminderItem) -> Binding<Date> {
        Binding(
            get: { Self.dateFromTimeLabel(item.timeLabel) },
            set: { viewModel.updateReminderTime(item.id, timeLabel: Self.timeLabelFromDate($0)) }
        )
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "pt_BR"); f.dateFormat = "HH:mm"; return f
    }()

    private static func dateFromTimeLabel(_ label: String) -> Date {
        timeFormatter.date(from: label) ?? Date()
    }

    private static func timeLabelFromDate(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    private func handleBack() {
        onBack()
        if let navigator, navigator.canPop() {
            navigator.pop()
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
