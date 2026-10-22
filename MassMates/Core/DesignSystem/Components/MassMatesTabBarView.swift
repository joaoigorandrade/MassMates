import Navigation
import SwiftUI

private struct TabBarItemView: View, Equatable {
    let tab: AppTab
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated static func == (lhs: TabBarItemView, rhs: TabBarItemView) -> Bool {
        lhs.tab == rhs.tab &&
        lhs.title == rhs.title &&
        lhs.icon == rhs.icon &&
        lhs.isSelected == rhs.isSelected
    }

    var body: some View {
        let iconName = isSelected ? "\(icon).fill" : icon
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: reduceMotion ? false : isSelected)
                    .contentTransition(.symbolEffect(.replace))
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
}

struct MassMatesTabBarView: View {
    @ObservedObject var tabNavigator: TabNavigator<AppTab, AppRoute>
    private let onCenterAction: () -> Void
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    init(
        tabNavigator: TabNavigator<AppTab, AppRoute>,
        onCenterAction: @escaping () -> Void
    ) {
        self.tabNavigator = tabNavigator
        self.onCenterAction = onCenterAction
    }

    var body: some View {
        HStack(spacing: 0) {
            tabItem(tab: .today, title: "Hoje", icon: "sun.max")
            tabItem(tab: .groups, title: "Grupos", icon: "person.2")
            centerActionButton
            tabItem(tab: .myPath, title: "Meu Caminho", icon: "person.crop.circle")
        }
        .sensoryFeedback(.selection, trigger: tabNavigator.selectedTab)
        .frame(height: 56)
        .padding(.horizontal, MassMatesSpacing.xs)
        .background(barBackground.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MassMatesPalette.line)
                .frame(height: 1)
        }
    }

    private var barBackground: some View {
        MassMatesPalette.bg
            .opacity(0.95)
            .background(.ultraThinMaterial)
    }

    private func tabItem(tab: AppTab, title: String, icon: String) -> some View {
        TabBarItemView(
            tab: tab,
            title: title,
            icon: icon,
            isSelected: tabNavigator.selectedTab == tab,
            action: { tabNavigator.handleSelection(tab) }
        )
    }

    private var centerActionButton: some View {
        Button(action: onCenterAction) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(theme.onTint)
                .frame(width: MassMatesLayout.minRowHeight, height: MassMatesLayout.minRowHeight)
                .background(theme.tint)
                .clipShape(Circle())
                .overlay(Circle().stroke(colorScheme == .dark ? MassMatesPalette.line : Color.clear, lineWidth: 1))
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : theme.tint.opacity(0.28),
                    radius: 10, x: 0, y: 4
                )
        }
        .buttonStyle(MassMatesPressableButtonStyle())
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
