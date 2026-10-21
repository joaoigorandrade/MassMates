import SwiftUI

struct SpiritualDiaryEntryCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
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
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    topBadgeRow
                    contextCalloutRow
                    reflectionParagraph
                    bottomVirtuesAndActionsRow
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var topBadgeRow: some View {
        HStack {
            HStack(spacing: 6) {
                Label(practiceHeaderLabel, systemImage: entry.practice.systemImage)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(theme.tint)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 4)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
                Label("Privado", systemImage: "lock.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
            }
            Spacer()
            Text(timestampLabel)
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    @ViewBuilder
    private var contextCalloutRow: some View {
        if let penance = entry.confessorOrPenanceNotes {
            Text("Penitência / Orientação: \(penance)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(MassMatesSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        } else if entry.practice == .dailyGospel {
            Text("“Todo aquele que me reconhecer diante dos homens, também o Filho do Homem o reconhecerá diante dos anjos de Deus.”")
                .font(MassMatesFont.customScripture(size: 14))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(MassMatesSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        } else if entry.practice == .rosary {
            Label("Oferecido por Mateus Silva (Fraternidade São José)", systemImage: "heart.fill")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .padding(MassMatesSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
        }
    }

    private var reflectionParagraph: some View {
        Text("“\(entry.reflectionOrNotes ?? "No silêncio da manhã, senti profunda consolação diante da providência paternal. A confiança do Pai me basta.")”")
            .font(MassMatesFont.customScripture(size: 16, italic: true))
            .foregroundStyle(MassMatesPalette.textPrimary)
            .multilineTextAlignment(.leading)
    }

    private var bottomVirtuesAndActionsRow: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(virtueTags, id: \.self) { tag in
                    Text(tag)
                        .font(MassMatesFont.caption)
                        .foregroundStyle(theme.tint)
                        .padding(.horizontal, MassMatesSpacing.xs)
                        .padding(.vertical, 2)
                        .background(theme.tintSoft)
                        .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
                }
            }
            Spacer()
            HStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "star.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.warning)
                Image(systemName: "ellipsis")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textTertiary)
            }
        }
    }

    private var practiceHeaderLabel: String {
        switch entry.practice {
        case .dailyGospel: "Lectio Divina • Lc 12, 8-12"
        case .rosary: "Santo Terço • Mistérios Dolorosos"
        case .mentalPrayer: "Oração Mental • 20 min"
        case .confession: "Confissão • Sigilo Sacramental"
        default: entry.practice.title
        }
    }

    private var timestampLabel: String {
        switch entry.practice {
        case .dailyGospel: "12 Out • 06:40"
        case .rosary: "08 Out • 18:15"
        default: "03 Out • 21:30"
        }
    }

    private var virtueTags: [String] {
        switch entry.practice {
        case .dailyGospel: ["Paz interior", "Entrega filial"]
        case .rosary: ["Caridade fraterna", "Alívio interior"]
        default: ["Contrição serena", "Gratidão"]
        }
    }
}

#Preview("Spiritual Diary Entry Card — 5 Seasons") {
    LiturgicalSeasonPreviewMatrix { _ in
        SpiritualDiaryEntryCardView(
            entry: SpiritualDiaryViewModel.defaultSampleEntries()[1],
            onSelectEntry: { _ in }
        )
    }
}
