import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home, nutrition, records, history, settings
        var label: String {
            switch self {
            case .home: "Accueil"
            case .nutrition: "Nutrition"
            case .records: "Records"
            case .history: "Historique"
            case .settings: "Réglages"
            }
        }
        var icon: String {
            switch self {
            case .home: "house.fill"
            case .nutrition: "fork.knife"
            case .records: "trophy.fill"
            case .history: "clock.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.label, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .nutrition:
            NutritionView()
        case .records:
            RecordsView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
