import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    var body: some View {
        Group {
            if onboardingCompleted {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .task {
            // Run on cold launch
            AutoBackupService.runDailyBackupIfNeeded(context: context)
        }
        .onChange(of: scenePhase) { _, phase in
            // Also run when the app comes back from background — covers users who never quit
            if phase == .active {
                AutoBackupService.runDailyBackupIfNeeded(context: context)
            }
        }
    }
}
