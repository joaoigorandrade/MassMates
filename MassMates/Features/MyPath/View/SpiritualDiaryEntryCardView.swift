import SwiftUI

struct SpiritualDiaryEntryCardView: View {
    // MARK: - Dependencies & State
    private let entry: PrivateDiaryCheckInEntry
    private let onSelectEntry: (PrivateDiaryCheckInEntry) -> Void

    // MARK: - Init
    init(
        entry: PrivateDiaryCheckInEntry,
        onSelectEntry: @escaping (PrivateDiaryCheckInEntry) -> Void
    ) {
        self.entry = entry
        self.onSelectEntry = onSelectEntry
    }

    // MARK: - Body / Public API
    var body: some View {
        Button {
            onSelectEntry(entry)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                metaHeaderRow
                reflectionBody
                confessorNotesRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, MassMatesSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var metaHeaderRow: some View {
        HStack(spacing: 6) {
            Text("\(dateLabel) · \(practiceHeaderLabel)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)

            if entry.practice.isStrictlyPrivate {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var reflectionBody: some View {
        if entry.practice.isStrictlyPrivate && (entry.reflectionOrNotes == nil || entry.reflectionOrNotes?.isEmpty == true) {
            Text("Registro sob sigilo sacramental")
                .font(MassMatesFont.customScripture(size: 16, italic: true))
                .foregroundStyle(MassMatesPalette.textSecondary)
        } else if let reflection = entry.reflectionOrNotes, !reflection.isEmpty {
            Text(reflection)
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var confessorNotesRow: some View {
        if let penance = entry.confessorOrPenanceNotes, !penance.isEmpty {
            Text("Penitência: \(penance)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(.top, 2)
        }
    }

    private var dateLabel: String {
        Self.dateFormatter.string(from: entry.createdAt).lowercased()
    }

    private var practiceHeaderLabel: String {
        switch entry.practice {
        case .dailyGospel: "Lectio Divina"
        case .rosary: "Santo Terço"
        case .mentalPrayer: "Oração Mental"
        case .confession: "Confissão"
        case .holyMass: "Santa Missa"
        case .adoration: "Adoração"
        case .spiritualReading: "Leitura Espiritual"
        case .fasting: "Jejum"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd MMM"
        return formatter
    }()
}

#Preview("Spiritual Diary Entry Card — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryEntryCardView(
            entry: SpiritualDiaryViewModel.defaultSampleEntries()[1],
            onSelectEntry: { _ in }
        )
        .padding()
    }
}
