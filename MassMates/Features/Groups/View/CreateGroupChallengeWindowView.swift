import SwiftUI

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
            datesRow
            if let message = viewModel.draft.challengeWindowErrorMessage {
                errorMessageText(message)
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private var datesRow: some View {
        HStack(spacing: MassMatesSpacing.sm) {
            dateField(title: "Início", date: dayBinding(\.startsOn))
            dateField(title: "Fim", date: dayBinding(\.endsOn))
        }
    }

    private func dateField(title: String, date: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            DatePicker(title, selection: date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
        .padding(.horizontal, MassMatesSpacing.sm)
        .frame(height: 44)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        .overlay(
            RoundedRectangle(cornerRadius: MassMatesRadius.photo)
                .strokeBorder(MassMatesPalette.line, lineWidth: 1)
        )
    }

    private func errorMessageText(_ message: String) -> some View {
        Text(message)
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.danger)
            .padding(.horizontal, MassMatesSpacing.xxs)
    }

    private func dayBinding(_ keyPath: WritableKeyPath<GroupCreationDraft, Date?>) -> Binding<Date> {
        Binding<Date>(
            get: { viewModel.draft[keyPath: keyPath] ?? Date() },
            set: { viewModel.draft[keyPath: keyPath] = $0 }
        )
    }
}

#Preview("Create Group Challenge Window — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        let vm = CreateJoinGroupViewModel(initialTab: .createNew)
        vm.selectType(.challenge)
        return CreateGroupChallengeWindowView(viewModel: vm)
            .padding()
    }
}
