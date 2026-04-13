import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.started, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \CustomTemplate.order) private var customTemplates: [CustomTemplate]

    private var weekSessions: [WorkoutSession] {
        let week = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { $0.started > week }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Week summary
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("\(weekSessions.count)")
                                .font(.title2).fontWeight(.black)
                            Text("séances / 7j")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        Divider().frame(height: 36)
                        VStack(spacing: 4) {
                            Text("\(Int(weekSessions.reduce(0) { $0 + $1.totalVolume }))")
                                .font(.title2).fontWeight(.black)
                            Text("kg vol / 7j")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(18)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    if sessions.isEmpty {
                        VStack(spacing: 10) {
                            Text("🏋️").font(.system(size: 50))
                            Text("Aucune séance").font(.headline)
                            Text("Lance ta première séance !").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 50)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(sessions) { session in
                                sessionCard(session)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Historique")
        }
    }

    private func sessionCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.started.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.subheadline).fontWeight(.bold)
                Spacer()
                Text(session.templateName)
                    .font(.caption).foregroundStyle(.secondary)
                if session.durationMinutes > 0 {
                    Text("· \(session.durationMinutes) min").font(.caption).foregroundStyle(.secondary)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(session.exercisesArray) { ex in
                        Text(ex.name)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(theme.color.accent.opacity(0.1))
                            .foregroundStyle(theme.color.accent)
                            .clipShape(Capsule())
                    }
                }
            }
            HStack(spacing: 8) {
                Text("\(session.totalSets) séries")
                Text("·").foregroundStyle(.tertiary)
                Text("\(Int(session.totalVolume)) kg")
                if session.caloriesBurned > 0 {
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(session.caloriesBurned) kcal")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contextMenu {
            if session.finished != nil {
                Button {
                    saveSessionAsTemplate(session)
                } label: {
                    Label("Sauvegarder comme programme", systemImage: "square.and.arrow.down")
                }
            }
            Button(role: .destructive) { context.delete(session) } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    private func shareText(for session: WorkoutSession) -> String {
        var lines: [String] = []
        lines.append("GymTracker — \(session.templateName)")
        lines.append(session.started.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))

        var stats: [String] = []
        if session.durationMinutes > 0 { stats.append("\(session.durationMinutes) min") }
        stats.append("\(session.totalSets) séries")
        stats.append("\(Int(session.totalVolume)) kg")
        lines.append(stats.joined(separator: " · "))

        lines.append("")
        for ex in session.exercisesArray.sorted(by: { $0.order < $1.order }) {
            let doneSets = ex.setsArray.filter(\.done).sorted(by: { $0.order < $1.order })
            if doneSets.isEmpty { continue }
            let detail = doneSets.map { "\(String(format: "%.0f", $0.kg))kg x\($0.reps)" }.joined(separator: ", ")
            lines.append("• \(ex.name) — \(detail)")
        }

        if session.caloriesBurned > 0 {
            lines.append("")
            lines.append("\(session.caloriesBurned) kcal estimées")
        }
        return lines.joined(separator: "\n")
    }

    private func saveSessionAsTemplate(_ session: WorkoutSession) {
        let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
        let custom = CustomTemplate(name: session.templateName, subtitle: "", order: nextOrder)
        context.insert(custom)
        for ex in session.exercisesArray.sorted(by: { $0.order < $1.order }) {
            let doneSetsCount = ex.setsArray.filter(\.done).count
            let firstReps = ex.setsArray.sorted(by: { $0.order < $1.order }).first?.reps ?? 10
            let cex = CustomTemplateExercise(
                name: ex.name,
                muscleGroup: ex.group,
                scheme: ex.scheme,
                restSeconds: ex.restSeconds,
                defaultSets: max(doneSetsCount, 1),
                defaultReps: firstReps,
                order: ex.order
            )
            if custom.exercises == nil { custom.exercises = [] }
            custom.exercises?.append(cex)
        }
    }
}
