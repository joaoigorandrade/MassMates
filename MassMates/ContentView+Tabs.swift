import Navigation
import SwiftUI

/// The tab interface of the app: the four tabs, the offline banner and the
/// floating check-in button.
extension ContentView {
    // MARK: - Subviews / Private Helpers
    var mainTabInterface: some View {
        ZStack(alignment: .bottom) {
            tabContentView
            offlineBanner
            MassMatesTabBarView(
                tabNavigator: tabNavigator,
                onCenterAction: {
                    presentNewCheckInModal()
                }
            )
        }
    }

    @ViewBuilder
    private var offlineBanner: some View {
        if let backendStatusText {
            OfflineStatusBanner(message: backendStatusText)
        }
    }

    private var tabContentView: some View {
        ZStack {
            ForEach(Array(AppTab.allCases), id: \.self) { tab in
                tabContent(for: tab)
            }
        }
    }

    private func tabContent(for tab: AppTab) -> some View {
        let navigator = tabNavigator.navigator(for: tab)
        return NavigationStackWrapper(navigator: navigator) {
            tab.tabContent
                .optionalNavigator(navigator)
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: 64)
                        .allowsHitTesting(false)
                }
        }
        .optionalNavigator(navigator)
        .environmentObject(navigator)
        .opacity(tabNavigator.selectedTab == tab ? 1 : 0)
        .allowsHitTesting(tabNavigator.selectedTab == tab)
    }

}
