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
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            cardHeader
            hairlineDivider
            latestCheckInRow
        }
        .padding(MassMatesSpacing.md)
        .background(MassMatesPalette.surface)
        .clipShape(.rect(cornerRadius: MassMatesRadius.card))
        .overlay(cardBorder)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectGroup(group)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var cardHeader: some View {
        HStack(alignment: .center, spacing: MassMatesSpacing.sm) {
            groupAvatar
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name.isEmpty ? "Cenáculo N. Sra. de Fátima" : group.name)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                    .lineLimit(2)
                Text("\(group.memberCount) membros · Dias Fiéis")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var groupAvatar: some View {
        ZStack {
            Circle()
                .fill(MassMatesPalette.surfaceMuted)
                .frame(width: 36, height: 36)
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(theme.tint)
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
    }

    private var latestCheckInRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            checkInAvatar
            VStack(alignment: .leading, spacing: 1) {
                Text("**Gabriel** cumpriu o Terço")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                Text("há 20 minutos")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            likeButton
        }
    }

    private var checkInAvatar: some View {
        Text("G")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(MassMatesPalette.textSecondary)
            .frame(width: 28, height: 28)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(Circle())
            .overlay(Circle().stroke(MassMatesPalette.line, lineWidth: 1))
    }

    private var likeButton: some View {
        Button {
            isLiked.toggle()
        } label: {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(MassMatesFont.callout)
                .foregroundStyle(isLiked ? Theme(season: .red).tint : MassMatesPalette.textTertiary)
                .frame(width: MassMatesLayout.minTapTarget, height: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: MassMatesRadius.card)
            .stroke(MassMatesPalette.line, lineWidth: 1)
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
