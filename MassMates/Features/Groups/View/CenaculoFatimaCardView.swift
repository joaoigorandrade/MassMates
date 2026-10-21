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
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    cenaculoHeader
                    latestCheckInRow
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews / Private Helpers
    private var cenaculoHeader: some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            Image(systemName: "sparkles")
                .font(MassMatesFont.title)
                .foregroundStyle(Theme(season: .white).tint)
                .frame(width: 48, height: 48)
                .background(Theme(season: .white).tintSoft)
                .clipShape(.rect(cornerRadius: MassMatesRadius.button))
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                Text(group.name.isEmpty ? "Cenáculo N. Sra. de Fátima" : group.name)
                    .font(MassMatesFont.headline)
                    .foregroundStyle(MassMatesPalette.textPrimary)
                HStack(spacing: MassMatesSpacing.xs) {
                    Label("\(group.memberCount) irmãos", systemImage: "person.2.fill")
                    Text("•")
                    Text("Modo: Dias Fiéis").foregroundStyle(Theme(season: .white).tint)
                }
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "ellipsis").foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var latestCheckInRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("G")
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .frame(width: 28, height: 28)
                .background(theme.tintSoft)
                .clipShape(Circle())
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
                    .font(MassMatesFont.caption)
                    .foregroundStyle(isLiked ? Theme(season: .red).tint : MassMatesPalette.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(MassMatesPalette.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
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
