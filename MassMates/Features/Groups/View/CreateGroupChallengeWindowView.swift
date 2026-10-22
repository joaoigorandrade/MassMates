import SwiftUI

/// The window of a **dated challenge**: the first and the last day. It is
/// only shown for the "Dated Challenge" type — a continuous fraternity has no
/// window.
struct CreateGroupChallengeWindowView: View {
    // MARK: - Dependencies & State
    @Bindable private var viewModel: CreateJoinGroupViewModel

    // MARK: - Init
    init(viewModel: CreateJoinGroupViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            startDateRow
            endDateRow
            if let message = viewModel.draft.challengeWindowErrorMessage {
                Text(message)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.danger)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var startDateRow: some View {
        dateRow(
            title: "Início do desafio",
            systemImage: "flag",
            date: dayBinding(\.startsOn)
        )
    }

    private var endDateRow: some View {
        dateRow(
            title: "Fim do desafio",
            systemImage: "flag.checkered",
            date: dayBinding(\.endsOn)
        )
    }

    private func dateRow(
        title: String,
        systemImage: String,
        date: Binding<Date>
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textTertiary)
            Text(title)
                .font(MassMatesFont.body)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            DatePicker(title, selection: date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
        }
        .frame(minHeight: MassMatesLayout.minRowHeight)
        .contentShape(Rectangle())
    }

    private func dayBinding(_ keyPath: WritableKeyPath<GroupCreationDraft, Date?>) -> Binding<Date> {
        Binding<Date>(
            get: { viewModel.draft[keyPath: keyPath] ?? Date() },
            set: { newValue in
                viewModel.draft[keyPath: keyPath] = newValue
            }
        )
    }
}

#Preview("Create Group Challenge Window — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let viewModel = CreateJoinGroupViewModel(initialTab: .createNew)
        viewModel.selectType(.challenge)
        return CreateGroupChallengeWindowView(viewModel: viewModel)
            .padding()
    }
}
