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
            AutoBackupService.runDailyBackupIfNeeded(context: context)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                AutoBackupService.runDailyBackupIfNeeded(context: context)
            }
        }
    }
}
