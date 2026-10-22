import SwiftUI

struct CenaculoFatimaCardView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @State private var isLiked = false
    private let group: CommunityGroup
    private let onSelectGroup: (CommunityGroup) -> Void

    // MARK: - Init
    init(group: CommunityGroup, onSelectGroup: @escaping (CommunityGroup) -> Void) {
        self.group = group
        self.onSelectGroup = onSelectGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        Button { onSelectGroup(group) } label: {
            VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                cardHeader
                Rectangle()
                    .fill(MassMatesPalette.line)
                    .frame(height: 1)
                latestCheckInRow
            }
            .padding(MassMatesSpacing.md)
            .background(MassMatesPalette.surface)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: MassMatesRadius.card)
                    .stroke(MassMatesPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text(group.name.isEmpty ? "Cenáculo N. Sra. de Fátima" : group.name)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("\(group.memberCount) membros · Dias Fiéis")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .foregroundStyle(MassMatesPalette.textTertiary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget, alignment: .trailing)
        }
    }

    private var latestCheckInRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("G")
                .font(Font.system(size: 13, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(width: 32, height: 32)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(Circle())
                .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text("**Gabriel** cumpriu o Terço da Tarde")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("há 20 minutos")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Button {
                isLiked.toggle()
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(MassMatesFont.body)
                    .foregroundStyle(isLiked ? Theme(season: .red).tint : MassMatesPalette.textSecondary)
                    .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Cenaculo Fatima Card — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        CenaculoFatimaCardView(
            group: CommunitySampleData.directoryGroups[0],
            onSelectGroup: { _ in }
        )
        .padding()
    }
}
