import Foundation
import Navigation
import Testing
@testable import MassMates

@MainActor
struct NavigationTabBarTests {
    // MARK: - AppTab & Routing Tests

    @Test("AppTab contains all 4 Stitch primary tabs in correct sequence")
    func appTabCasesAndSequencing() {
        let tabs = Array(AppTab.allCases)
        #expect(tabs.count == 4)
        #expect(tabs[0] == .today)
        #expect(tabs[1] == .groups)
        #expect(tabs[2] == .myPath)
        #expect(tabs[3] == .sacredRites)
    }

    @Test("TabNavigator switches between tabs and navigators properly")
    func tabNavigatorSwitching() {
        let navigator = TabNavigator<AppTab, AppRoute>(initialTab: .today)
        #expect(navigator.selectedTab == .today)

        navigator.switchTab(to: .groups)
        #expect(navigator.selectedTab == .groups)

        navigator.switchTab(to: .sacredRites)
        #expect(navigator.selectedTab == .sacredRites)

        navigator.switchTab(to: .myPath)
        #expect(navigator.selectedTab == .myPath)
    }

    @Test("TabNavigator handleSelection pops to root on re-selecting the same tab")
    func tabNavigatorPopToRootOnReselect() {
        let navigator = TabNavigator<AppTab, AppRoute>(initialTab: .today)
        let todayNav = navigator.navigator(for: .today)
        todayNav.navigate(to: .settings(season: .green))
        #expect(!todayNav.path.isEmpty)

        var reselectCalled = false
        navigator.handleSelection(.today, popToRootOnReselect: true) { reselectedTab in
            reselectCalled = true
            #expect(reselectedTab == .today)
        }

        #expect(reselectCalled)
        #expect(todayNav.path.isEmpty)
    }

    @Test("TabNavigator handleSelection switches tab when selecting different tab")
    func tabNavigatorSwitchesOnNewTabSelection() {
        let navigator = TabNavigator<AppTab, AppRoute>(initialTab: .today)
        var reselectCalled = false

        navigator.handleSelection(.groups, popToRootOnReselect: true) { _ in
            reselectCalled = true
        }

        #expect(!reselectCalled)
        #expect(navigator.selectedTab == .groups)
    }

    @Test("Liturgical seasons all supply accessible contrast tints for tab bar")
    func liturgicalSeasonsContrastForTabBar() {
        for season in LiturgicalColor.allCases {
            let theme = Theme(season: season)
            #expect(!season.defaultSeasonName.isEmpty)
            #expect(theme.tint != theme.onTint)
        }
    }
}
