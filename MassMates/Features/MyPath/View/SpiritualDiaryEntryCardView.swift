import SwiftUI

struct SpiritualDiaryEntryCardView: View, Equatable {
    // MARK: - Dependencies & State
    private let entry: PrivateDiaryCheckInEntry
    private let onSelectEntry: (PrivateDiaryCheckInEntry) -> Void
    private let dayString: String

    // MARK: - Init
    init(
        entry: PrivateDiaryCheckInEntry,
        onSelectEntry: @escaping (PrivateDiaryCheckInEntry) -> Void
    ) {
        self.entry = entry
        self.onSelectEntry = onSelectEntry
        self.dayString = String(Calendar.current.component(.day, from: entry.createdAt))
    }

    nonisolated static func == (lhs: SpiritualDiaryEntryCardView, rhs: SpiritualDiaryEntryCardView) -> Bool {
        lhs.entry == rhs.entry
    }

    // MARK: - Body / Public API
    var body: some View {
        Button {
            onSelectEntry(entry)
        } label: {
            HStack(alignment: .center, spacing: MassMatesSpacing.xs) {
                dayNumeral
                practiceBadge
                dashSeparator
                snippetText
                Spacer(minLength: 4)
                chevronIndicator
            }
            .frame(height: MassMatesLayout.minRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var dayNumeral: some View {
        Text(dayString)
            .font(MassMatesFont.headline)
            .fontWeight(.medium)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .frame(width: 24, alignment: .leading)
    }

    private var practiceBadge: some View {
        HStack(spacing: 3) {
            Text(practiceShortTitle)
                .font(MassMatesFont.callout)
                .fontWeight(.semibold)
                .foregroundStyle(MassMatesPalette.textPrimary)
            if entry.practice.isStrictlyPrivate {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private var dashSeparator: some View {
        Text("—")
            .font(MassMatesFont.callout)
            .foregroundStyle(MassMatesPalette.textTertiary)
    }

    private var snippetText: some View {
        Text(reflectionSnippet)
            .font(MassMatesFont.customScripture(size: 15, italic: true))
            .foregroundStyle(isPrivateBlank ? MassMatesPalette.textTertiary : MassMatesPalette.textSecondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var chevronIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(MassMatesPalette.textTertiary)
    }

    private var isPrivateBlank: Bool {
        entry.practice.isStrictlyPrivate && (entry.reflectionOrNotes == nil || entry.reflectionOrNotes?.isEmpty == true)
    }

    private var reflectionSnippet: String {
        if isPrivateBlank {
            return "Privado"
        }
        if let notes = entry.reflectionOrNotes, !notes.isEmpty {
            return notes.replacingOccurrences(of: "\n", with: " ")
        }
        return "Sem anotações"
    }

    private var practiceShortTitle: String {
        switch entry.practice {
        case .dailyGospel: "Evangelho"
        case .rosary: "Terço"
        case .mentalPrayer: "Oração"
        case .confession: "Confissão"
        case .holyMass: "Santa Missa"
        case .adoration: "Adoração"
        case .spiritualReading: "Leitura"
        case .fasting: "Jejum"
        }
    }
}

#Preview("Spiritual Diary Entry Row — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryEntryCardView(
            entry: SpiritualDiaryViewModel.defaultSampleEntries()[0],
            onSelectEntry: { _ in }
        )
        .padding()
    }
}
