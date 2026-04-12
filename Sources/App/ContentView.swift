import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var selectedTab: Tab = .home
    @AppStorage("tutorialCompleted") private var tutorialCompleted: Bool = false
    @State private var showTutorial = false
    @State private var spotlightFrames: [SpotlightItem] = []

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
        var spotlightKey: String {
            "tab_\(rawValue)"
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
            // Invisible anchors over tab bar area
            .overlay(alignment: .bottom) {
                GeometryReader { geo in
                    let tabCount = CGFloat(Tab.allCases.count)
                    let tabWidth = geo.size.width / tabCount
                    let tabBarHeight: CGFloat = 49
                    let bottomY = geo.size.height - geo.safeAreaInsets.bottom

                    ForEach(Array(Tab.allCases.enumerated()), id: \.element) { index, tab in
                        Color.clear
                            .frame(width: tabWidth, height: tabBarHeight)
                            .position(
                                x: tabWidth * CGFloat(index) + tabWidth / 2,
                                y: bottomY - tabBarHeight / 2
                            )
                            .spotlightTag(tab.spotlightKey)
                    }
                }
                .allowsHitTesting(false)
            }
            .onPreferenceChange(SpotlightPreferenceKey.self) { items in
                spotlightFrames = items
            }

            if showTutorial {
                SpotlightTutorial(isPresented: $showTutorial, spotlightFrames: spotlightFrames)
                    .onChange(of: showTutorial) { _, shown in
                        if !shown {
                            tutorialCompleted = true
                        }
                    }
            }
        }
        .onAppear {
            if !tutorialCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
