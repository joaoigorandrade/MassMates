import Navigation
import SwiftUI

struct DiaryEntryImmersiveReaderView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var currentEntry: PrivateDiaryCheckInEntry
    private let allEntries: [PrivateDiaryCheckInEntry]
    private let hasAttachedPhoto: Bool

    // MARK: - Init
    init(
        entry: PrivateDiaryCheckInEntry = SpiritualDiaryViewModel.defaultSampleEntries()[0],
        allEntries: [PrivateDiaryCheckInEntry] = SpiritualDiaryViewModel.defaultSampleEntries(),
        hasAttachedPhoto: Bool = true
    ) {
        self._currentEntry = State(initialValue: entry)
        self.allEntries = allEntries
        self.hasAttachedPhoto = hasAttachedPhoto
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topNavigationBar
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
                    metadataAndTitleSection
                    if hasAttachedPhoto { attachedPhotoProof }
                    DiaryEntryIlluminatingWordView()
                    reflectionArticle
                    footerWithChevrons
                }
                .padding(.horizontal, MassMatesLayout.readingMargin)
                .padding(.top, MassMatesSpacing.md)
                .frame(maxWidth: MassMatesLayout.readingMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden()
    }

    // MARK: - Subviews / Private Helpers
    private var topNavigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
            Spacer()
            ShareLink(item: exportText) {
                Image(systemName: "square.and.arrow.up")
                    .font(MassMatesFont.callout)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MassMatesLayout.readingMargin)
        .frame(height: MassMatesLayout.minRowHeight)
    }

    private var metadataAndTitleSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            Text(formattedMetadata).font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Text(entryTitle).font(MassMatesFont.title).foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    private var attachedPhotoProof: some View {
        ZStack {
            MassMatesPalette.surfaceMuted
            VStack(spacing: MassMatesSpacing.xs) {
                Image(systemName: "camera").font(MassMatesFont.title).foregroundStyle(MassMatesPalette.textTertiary)
                Text("Canto de oração • Recolhimento").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var reflectionArticle: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            ForEach(reflectionParagraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .font(MassMatesFont.scripture)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineSpacing(11)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: MassMatesLayout.readingMaxWidth, alignment: .leading)
    }

    private var footerWithChevrons: some View {
        DiaryEntryImmersiveFooterView(
            previousLabel: previousEntry.map(shortDateLabel),
            nextLabel: nextEntry.map(shortDateLabel),
            onPrevious: { flip(to: previousEntry) },
            onNext: { flip(to: nextEntry) }
        )
    }

    private var formattedMetadata: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d 'de' MMMM"
        return "\(formatter.string(from: currentEntry.createdAt)) · \(currentEntry.practice.title)"
    }

    private var entryTitle: String {
        switch currentEntry.practice {
        case .rosary: "Consolação ao pé da Cruz"
        case .dailyGospel: "Luz no Evangelho do Dia"
        case .mentalPrayer: "Recolhimento e Paz Interior"
        case .confession: "Reconciliação e Misericórdia"
        default: "Consolação e Recolhimento"
        }
    }

    private var reflectionParagraphs: [String] {
        if let notes = currentEntry.reflectionOrNotes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let split = notes.components(separatedBy: "\n\n").filter { !$0.isEmpty }
            return split.isEmpty ? [notes] : split
        }
        return [
            "Ofereci cada mistério pelas intenções e aflições da minha família. Durante a oração, veio-me ao coração uma viva consciência de que a cruz já foi redimida pelo amor de Nosso Senhor.",
            "Senti uma profunda paz no recolhimento interior, renovando o propósito de guardar a mansidão e fixar o olhar em Cristo."
        ]
    }

    private var previousEntry: PrivateDiaryCheckInEntry? {
        guard let idx = allEntries.firstIndex(where: { $0.id == currentEntry.id }), idx + 1 < allEntries.count else { return nil }
        return allEntries[idx + 1]
    }

    private var nextEntry: PrivateDiaryCheckInEntry? {
        guard let idx = allEntries.firstIndex(where: { $0.id == currentEntry.id }), idx > 0 else { return nil }
        return allEntries[idx - 1]
    }

    private func shortDateLabel(for entry: PrivateDiaryCheckInEntry) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: entry.createdAt).capitalized
    }

    private func flip(to entry: PrivateDiaryCheckInEntry?) {
        guard let entry else { return }
        withAnimation(.easeInOut(duration: 0.25)) { currentEntry = entry }
    }

    private var exportText: String {
        "[\(formattedMetadata)] \(entryTitle)\n\n\(reflectionParagraphs.joined(separator: "\n\n"))"
    }
}

#Preview("Immersive Diary Entry Reader — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryImmersiveReaderView()
    }
}
