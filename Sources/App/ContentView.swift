import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @State private var selectedTab: Tab = .home
    @AppStorage("tutorialCompleted") private var tutorialCompleted: Bool = false
    @State private var showTutorial = false

    enum Tab: String, CaseIterable {
        case home, stats, xp, history, settings
        var label: String {
            switch self {
            case .home: "Accueil"
            case .stats: "Stats"
            case .xp: "XP"
            case .history: "Historique"
            case .settings: "Réglages"
            }
        }
        var icon: String {
            switch self {
            case .home: "house.fill"
            case .stats: "chart.bar.fill"
            case .xp: "trophy.fill"
            case .history: "clock.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(tab)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .overlayPreferenceValue(SpotlightBoundsKey.self) { anchors in
            if showTutorial {
                TutorialOverlay(isPresented: $showTutorial, anchors: anchors)
            }
        }
        .onChange(of: showTutorial) { _, shown in
            if !shown && !tutorialCompleted {
                tutorialCompleted = true
            }
        }
        .task {
            if !tutorialCompleted {
                try? await Task.sleep(for: .milliseconds(600))
                showTutorial = true
            }
        }
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                            Text(tab.label)
                                .font(.caption2)
                        }
                        .tutorialTag("tab_\(tab.rawValue)")
                        .foregroundStyle(selectedTab == tab ? theme.color.accent : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(.bar)
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .stats:
            RecordsView()
        case .xp:
            XPView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
