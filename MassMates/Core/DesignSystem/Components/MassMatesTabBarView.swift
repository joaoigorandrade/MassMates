import Navigation
import SwiftUI

struct MassMatesTabBarView: View {
    // MARK: - Dependencies & State
    @ObservedObject var tabNavigator: TabNavigator<AppTab, AppRoute>
    private let onCenterAction: () -> Void
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init
    init(
        tabNavigator: TabNavigator<AppTab, AppRoute>,
        onCenterAction: @escaping () -> Void
    ) {
        self.tabNavigator = tabNavigator
        self.onCenterAction = onCenterAction
    }

    // MARK: - Body / Public API
    var body: some View {
        HStack(spacing: 0) {
            tabItemView(tab: .today, title: "Hoje", icon: "sun.max")
            tabItemView(tab: .groups, title: "Grupos", icon: "person.2")
            centerActionButton
            tabItemView(tab: .myPath, title: "Meu Caminho", icon: "person.crop.circle")
            tabItemView(tab: .sacredRites, title: "Mais", icon: "book.closed")
        }
        .frame(height: 56)
        .padding(.horizontal, MassMatesSpacing.xs)
        .background(barBackground.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    // MARK: - Subviews / Private Helpers
    private var barBackground: some View {
        MassMatesPalette.surface
            .opacity(colorScheme == .dark ? 0.92 : 0.94)
            .background(.ultraThinMaterial)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04),
                radius: 8,
                x: 0,
                y: -2
            )
    }

    private func tabItemView(tab: AppTab, title: String, icon: String) -> some View {
        let isSelected = tabNavigator.selectedTab == tab
        let iconName = isSelected ? "\(icon).fill" : icon
        return Button {
            tabNavigator.handleSelection(tab)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                Text(title)
                    .font(MassMatesFont.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? theme.tint : MassMatesPalette.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var centerActionButton: some View {
        Button(action: onCenterAction) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(theme.onTint)
                .frame(
                    width: MassMatesLayout.minRowHeight,
                    height: MassMatesLayout.minRowHeight
                )
                .background(theme.tint)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            colorScheme == .dark ? MassMatesPalette.line : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark ? .clear : theme.tint.opacity(0.35),
                    radius: 10,
                    x: 0,
                    y: 6
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .offset(y: -14)
        .accessibilityLabel("Novo check-in espiritual")
    }
}

#Preview("MassMates Tab Bar — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        MassMatesTabBarView(
            tabNavigator: TabNavigator(initialTab: .today),
            onCenterAction: {}
        )
    }
}
