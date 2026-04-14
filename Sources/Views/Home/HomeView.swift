import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.started, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query(sort: \CustomTemplate.order) private var customTemplates: [CustomTemplate]
    @Query(filter: #Predicate<ExerciseInfo> { $0.isFavorite }) private var favoriteExercises: [ExerciseInfo]

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4
    @State private var activeSession: WorkoutSession?
    @State private var showTemplateList = false
    @State private var newTemplate: CustomTemplate?
    @State private var showAIImport = false
    @State private var templateToDelete: CustomTemplate?

    private var weekSessions: [WorkoutSession] {
        let week = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { $0.started > week }
    }
    private var recentGroups: [MuscleGroup] {
        Array(Set(weekSessions.flatMap { $0.activeGroups }))
    }
    private var lastWeight: WeightEntry? { weights.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("READY TO LIFT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundStyle(.secondary)
                            Text(userName.isEmpty ? "Salut\u{00A0}!" : userName)
                                .font(.largeTitle)
                                .fontWeight(.black)
                        }
                        Spacer()
                        // Session goal + rank
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Text("\(weekSessions.count)/\(weeklyGoal)")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundStyle(weekSessions.count >= weeklyGoal ? .green : theme.color.accent)
                                Image(systemName: weekSessions.count >= weeklyGoal ? "checkmark.seal.fill" : "flame.fill")
                                    .font(.caption)
                                    .foregroundStyle(weekSessions.count >= weeklyGoal ? .green : theme.color.accent)
                            }
                            Text("séances")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(theme.color.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    // XP / Rank bar
                    HomeRankBar(totalXP: totalXP)
                        .padding(.horizontal)

                    // Streak + week days
                    HomeStreakCard(sessions: Array(sessions), weeklyGoal: weeklyGoal)
                        .padding(.horizontal)

                    // Body stats card with body map
                    HomeBodyStatsCard(lastWeight: lastWeight, recentGroups: recentGroups)

                    // Favorites section
                    HomeFavoritesSection(favoriteExercises: Array(favoriteExercises))

                    // Free session button
                    Button {
                        startFreeSession()
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Séance libre")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .tutorialTag("free_session")

                    // Custom templates section — always visible
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("MES SÉANCES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2.5)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                showAIImport = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Importer (IA)")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(theme.color.accent)
                            }
                            .tutorialTag("ai_import")
                            if !customTemplates.isEmpty {
                                NavigationLink {
                                    TemplateListView()
                                } label: {
                                    Text("Modifier")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(theme.color.accent)
                                }
                            }
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: [.init(), .init()], spacing: 12) {
                            ForEach(customTemplates) { tpl in
                                CustomTemplateCard(template: tpl)
                                    .onTapGesture {
                                        startSession(fromCustom: tpl)
                                    }
                                    .contextMenu {
                                        ShareLink(item: shareText(for: tpl)) {
                                            Label("Partager", systemImage: "square.and.arrow.up")
                                        }
                                        Button {
                                            tpl.isFavorite.toggle()
                                        } label: {
                                            Label(tpl.isFavorite ? "Retirer des favoris" : "Mettre en favori",
                                                  systemImage: tpl.isFavorite ? "star.slash" : "star")
                                        }
                                        Button {
                                            duplicateCustomTemplate(tpl)
                                        } label: {
                                            Label("Dupliquer", systemImage: "doc.on.doc")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            templateToDelete = tpl
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                            }
                            // "+" create card
                            Button {
                                let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
                                let tpl = CustomTemplate(name: "", subtitle: "", order: nextOrder)
                                context.insert(tpl)
                                newTemplate = tpl
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(theme.color.accent)
                                    if customTemplates.isEmpty {
                                        Text("Créer un programme")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 110)
                                .background(theme.color.accent.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(theme.color.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                    .tutorialTag("my_sessions")

                    // Bibliothèque link
                    NavigationLink {
                        ProgramLibraryView()
                    } label: {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .font(.title3)
                                .foregroundStyle(theme.color.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bibliothèque de programmes")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Text("\(WorkoutTemplate.all.count) programmes prêts à l'emploi")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Last session
                    if let last = sessions.first {
                        HomeLastSessionCard(session: last)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionView(session: session)
        }
        .sheet(item: $newTemplate) { tpl in
            NavigationStack {
                TemplateEditorView(template: tpl, isNew: true)
            }
        }
        .sheet(isPresented: $showAIImport) {
            AIImportSheet()
        }
        .alert("Supprimer ce programme\u{00A0}?", isPresented: Binding(
            get: { templateToDelete != nil },
            set: { if !$0 { templateToDelete = nil } }
        )) {
            Button("Annuler", role: .cancel) { templateToDelete = nil }
            Button("Supprimer", role: .destructive) {
                if let tpl = templateToDelete {
                    context.delete(tpl)
                    templateToDelete = nil
                }
            }
        } message: {
            Text("Cette action est irréversible.")
        }
    }

    // MARK: - Session Launching

    private func startSession(from template: WorkoutTemplate) {
        let session = WorkoutSession(templateId: template.id, templateName: template.name)

        let lastOfTemplate = sessions.first { $0.templateId == template.id && $0.finished != nil }

        for (index, exTemplate) in template.exercises.enumerated() {
            let entry = ExerciseEntry(
                name: exTemplate.name,
                muscleGroup: exTemplate.group,
                equipment: exTemplate.equipment,
                scheme: exTemplate.scheme,
                restSeconds: 90,
                order: index
            )

            let previousExercise = lastOfTemplate?.exercisesArray.first { $0.name == exTemplate.name }
            let previousSets = previousExercise?.setsArray.sorted { $0.order < $1.order } ?? []

            for (setIndex, defaultSet) in exTemplate.defaultSets.enumerated() {
                let prefillKg: Double
                if setIndex < previousSets.count, previousSets[setIndex].kg > 0 {
                    prefillKg = previousSets[setIndex].kg
                } else {
                    prefillKg = defaultSet.kg
                }
                let newSet = WorkoutSet(
                    kg: prefillKg,
                    reps: defaultSet.reps,
                    done: false,
                    order: setIndex
                )
                if entry.sets == nil { entry.sets = [] }
                entry.sets?.append(newSet)
            }
            if session.exercises == nil { session.exercises = [] }
            session.exercises?.append(entry)
        }

        activeSession = session
    }

    private func startSession(fromCustom template: CustomTemplate) {
        let session = WorkoutSession(templateId: nil, templateName: template.name.isEmpty ? "Séance perso" : template.name)

        let lastOfName = sessions.first { $0.templateName == template.name && $0.finished != nil }

        let sortedExercises = template.exercisesArray.sorted { $0.order < $1.order }
        for (index, exTemplate) in sortedExercises.enumerated() {
            let entry = ExerciseEntry(
                name: exTemplate.name,
                muscleGroup: exTemplate.group,
                equipment: exTemplate.equipment,
                scheme: exTemplate.scheme,
                restSeconds: exTemplate.restSeconds,
                order: index
            )

            let previousExercise = lastOfName?.exercisesArray.first { $0.name == exTemplate.name }
            let previousSets = previousExercise?.setsArray.sorted { $0.order < $1.order } ?? []

            for setIndex in 0..<exTemplate.defaultSets {
                let prefillKg: Double
                if setIndex < previousSets.count, previousSets[setIndex].kg > 0 {
                    prefillKg = previousSets[setIndex].kg
                } else {
                    prefillKg = 0
                }
                let newSet = WorkoutSet(
                    kg: prefillKg,
                    reps: exTemplate.defaultReps,
                    done: false,
                    order: setIndex
                )
                if entry.sets == nil { entry.sets = [] }
                entry.sets?.append(newSet)
            }
            if session.exercises == nil { session.exercises = [] }
            session.exercises?.append(entry)
        }

        activeSession = session
    }

    private func startFreeSession() {
        let session = WorkoutSession(templateName: "Séance libre")
        activeSession = session
    }

    // MARK: - Duplicate Functions

    private func duplicateAsCustom(_ template: WorkoutTemplate) {
        let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
        let custom = CustomTemplate(name: template.name, subtitle: template.subtitle, order: nextOrder)
        context.insert(custom)
        for (i, ex) in template.exercises.enumerated() {
            let cex = CustomTemplateExercise(
                name: ex.name,
                muscleGroup: ex.group,
                equipment: ex.equipment,
                scheme: ex.scheme,
                restSeconds: 90,
                defaultSets: ex.defaultSets.count,
                defaultReps: ex.defaultSets.first?.reps ?? 10,
                order: i
            )
            if custom.exercises == nil { custom.exercises = [] }
            custom.exercises?.append(cex)
        }
    }

    private func shareText(for template: CustomTemplate) -> String {
        let name = template.name.isEmpty ? "Programme" : template.name
        var lines: [String] = []
        lines.append(unicodeBold(name))
        lines.append("")
        for ex in template.exercisesArray.sorted(by: { $0.order < $1.order }) {
            let detail = ex.scheme.isEmpty ? "\(ex.defaultSets)×\(ex.defaultReps)" : ex.scheme
            lines.append("▸ \(ex.name) — \(unicodeBold(detail))")
        }
        return lines.joined(separator: "\n")
    }

    private func unicodeBold(_ text: String) -> String {
        text.unicodeScalars.map { scalar in
            switch scalar.value {
            case 0x41...0x5A: // A-Z
                return String(UnicodeScalar(0x1D5D4 + scalar.value - 0x41)!)
            case 0x61...0x7A: // a-z
                return String(UnicodeScalar(0x1D5EE + scalar.value - 0x61)!)
            case 0x30...0x39: // 0-9
                return String(UnicodeScalar(0x1D7EC + scalar.value - 0x30)!)
            default:
                return String(scalar)
            }
        }.joined()
    }

    private func duplicateCustomTemplate(_ template: CustomTemplate) {
        let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
        let copy = CustomTemplate(name: template.name, subtitle: template.subtitle, order: nextOrder)
        context.insert(copy)
        for ex in template.exercisesArray.sorted(by: { $0.order < $1.order }) {
            let cex = CustomTemplateExercise(
                name: ex.name,
                muscleGroup: ex.group,
                equipment: ex.equipment,
                scheme: ex.scheme,
                restSeconds: ex.restSeconds,
                defaultSets: ex.defaultSets,
                defaultReps: ex.defaultReps,
                order: ex.order
            )
            if copy.exercises == nil { copy.exercises = [] }
            copy.exercises?.append(cex)
        }
    }

}

// MARK: - Template Card
struct TemplateCard: View {
    @Environment(ThemeManager.self) private var theme
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(template.name)
                .font(.headline)
                .fontWeight(.bold)
            Text(template.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text("\(template.exercises.count) exos")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(theme.color.accent.gradient.opacity(0.1))
        .overlay(alignment: .top) {
            theme.color.gradient
                .frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

// MARK: - Custom Template Card

struct CustomTemplateCard: View {
    @Environment(ThemeManager.self) private var theme
    let template: CustomTemplate

    private var muscleGroups: [MuscleGroup] {
        Array(Set(template.exercisesArray.compactMap { MuscleGroup(rawValue: $0.muscleGroup) }))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(template.name.isEmpty ? "Sans nom" : template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                if template.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
            if !template.subtitle.isEmpty {
                Text(template.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                ForEach(muscleGroups.prefix(3)) { group in
                    Image(systemName: group.icon)
                        .font(.caption2)
                        .foregroundStyle(theme.color.accent)
                }
                Spacer()
                Text("\(template.exercisesArray.count) exos")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            theme.color.gradient
                .frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

