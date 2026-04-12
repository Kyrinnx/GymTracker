import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var selectedTab: Tab = .home
    @AppStorage("tutorialCompleted") private var tutorialCompleted: Bool = false
    @State private var showTutorial = false

    enum Tab: String, CaseIterable {
        case home, records, history, settings
        var label: String {
            switch self {
            case .home: "Accueil"
            case .records: "Records"
            case .history: "Historique"
            case .settings: "Réglages"
            }
        }
        var icon: String {
            switch self {
            case .home: "house.fill"
            case .records: "trophy.fill"
            case .history: "clock.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabContent(for: tab)
                        .tabItem {
                            Label(tab.label, systemImage: tab.icon)
                        }
                        .tag(tab)
                }
            }

            if showTutorial {
                SpotlightTutorial(isPresented: $showTutorial)
                    .onChange(of: showTutorial) { _, shown in
                        if !shown {
                            tutorialCompleted = true
                        }
                    }
            }
        }
        .onAppear {
            if !tutorialCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                }
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .records:
            RecordsView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
