import SwiftUI
import SwiftData

@main
struct GymTrackerApp: App {
    @State private var theme = ThemeManager()
    let container: ModelContainer

    init() {
        let schema = Schema([
            WorkoutSession.self,
            ExerciseEntry.self,
            WorkoutSet.self,
            WeightEntry.self,
            CustomTemplate.self,
            CustomTemplateExercise.self,
            ExerciseInfo.self,
        ])
        // Local-only configuration — works with a free Apple ID, no paid Developer Program required.
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        // swiftlint:disable:next force_try
        container = try! ModelContainer(for: schema, configurations: config)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(theme)
                .preferredColorScheme(theme.mode.colorScheme)
                .tint(theme.color.accent)
        }
        .modelContainer(container)
    }
}
