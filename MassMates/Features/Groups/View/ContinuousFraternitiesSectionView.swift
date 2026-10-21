import SwiftUI

struct ContinuousFraternitiesSectionView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    private let groups: [CommunityGroup]
    private let onSelectGroup: (CommunityGroup) -> Void

    // MARK: - Init
    init(groups: [CommunityGroup], onSelectGroup: @escaping (CommunityGroup) -> Void) {
        self.groups = groups
        self.onSelectGroup = onSelectGroup
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader
            primaryFraternityCard(group: groups.first ?? CommunitySampleData.parishFraternity)
            CenaculoFatimaCardView(
                group: groups.dropFirst().first ?? CommunitySampleData.directoryGroups[0],
                onSelectGroup: onSelectGroup
            )
        }
    }

    // MARK: - Subviews / Private Helpers
    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Fraternidades Contínuas")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Text("(2 ativas)")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            Button("Organizar") {}
                .font(MassMatesFont.caption)
                .foregroundStyle(theme.tint)
                .buttonStyle(.plain)
        }
    }

    private func primaryFraternityCard(group: CommunityGroup) -> some View {
        Button { onSelectGroup(group) } label: {
            MassMatesCard {
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    primaryCardHeader(group: group)
                    weeklyRosaryGoalBox
                    guardianAngelFooterRow
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func primaryCardHeader(group: CommunityGroup) -> some View {
        HStack(alignment: .top, spacing: MassMatesSpacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "briefcase.fill")
                    .font(MassMatesFont.title)
                    .foregroundStyle(theme.tint)
                    .frame(width: 48, height: 48)
                    .background(theme.tintSoft)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.button))
                Image(systemName: "shield.fill")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(Theme(season: .white).tint)
                    .frame(width: 20, height: 20)
                    .background(MassMatesPalette.surface)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
                HStack(spacing: MassMatesSpacing.xs) {
                    Text(group.name).font(MassMatesFont.headline).foregroundStyle(MassMatesPalette.textPrimary)
                    Text("ATIVO").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(theme.tintSoft).clipShape(Capsule())
                }
                HStack(spacing: MassMatesSpacing.xs) {
                    Label("\(group.memberCount) irmãos", systemImage: "person.2.fill").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                    Text("•").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textTertiary)
                    Label("Rezei hoje", systemImage: "checkmark.circle.fill").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.success)
                }
            }
            Spacer()
            Image(systemName: "ellipsis").foregroundStyle(MassMatesPalette.textTertiary)
        }
    }

    private var weeklyRosaryGoalBox: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            HStack {
                Label("Meta Semanal de Terços", systemImage: "smallcircle.filled.circle")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                Spacer()
                Text("68% (34/50)")
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textPrimary)
            }
            MassMatesProgressBar(progress: 0.68)
        }
        .padding(MassMatesSpacing.sm)
        .background(MassMatesPalette.surfaceMuted)
        .clipShape(.rect(cornerRadius: MassMatesRadius.photo))
    }

    private var guardianAngelFooterRow: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Text("MS")
                .font(MassMatesFont.caption).foregroundStyle(theme.tint)
                .frame(width: 24, height: 24).background(theme.tintSoft).clipShape(Circle())
            Text("Seu anjo da semana é Mateus Silva")
                .font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
            Spacer()
            HStack(spacing: 2) {
                Text("Enviar Paz")
                Image(systemName: "chevron.right")
            }
            .font(MassMatesFont.caption).foregroundStyle(theme.tint)
        }
    }
}

#Preview("Continuous Fraternities — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        ContinuousFraternitiesSectionView(
            groups: [CommunitySampleData.parishFraternity],
            onSelectGroup: { _ in }
        )
    }
}
