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
    @State private var activeSession: WorkoutSession?
    @State private var showTemplateList = false

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
                        // (top spacing handled by safeAreaInset below)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("READY TO LIFT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundStyle(.secondary)
                            Text(userName.isEmpty ? "Salut !" : userName)
                                .font(.largeTitle)
                                .fontWeight(.black)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("\(weekSessions.count)")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundStyle(theme.color.accent)
                            Text("séances / 7j")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(theme.color.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal)

                    // Body stats card with body map
                    bodyStatsCard

                    // Favorites section
                    favoritesSection

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

                    // Custom templates section
                    if !customTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("MES SÉANCES")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(2.5)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                NavigationLink {
                                    TemplateListView()
                                } label: {
                                    Text("Modifier")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(theme.color.accent)
                                }
                            }
                            .padding(.horizontal)

                            LazyVGrid(columns: [.init(), .init()], spacing: 12) {
                                ForEach(customTemplates) { tpl in
                                    CustomTemplateCard(template: tpl)
                                        .onTapGesture {
                                            startSession(fromCustom: tpl)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Built-in Templates
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PROGRAMMES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2.5)
                                .foregroundStyle(.secondary)
                            Spacer()
                            NavigationLink {
                                TemplateListView()
                            } label: {
                                Text("Modifier")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(theme.color.accent)
                            }
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: [.init(), .init()], spacing: 12) {
                            ForEach(WorkoutTemplate.all) { tpl in
                                TemplateCard(template: tpl)
                                    .onTapGesture {
                                        startSession(from: tpl)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Last session
                    if let last = sessions.first {
                        lastSessionCard(last)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionView(session: session)
        }
    }

    // MARK: - Session Launching

    private func startSession(from template: WorkoutTemplate) {
        let session = WorkoutSession(templateId: template.id, templateName: template.name)
        context.insert(session)

        let lastOfTemplate = sessions.first { $0.templateId == template.id && $0.finished != nil }

        for (index, exTemplate) in template.exercises.enumerated() {
            let entry = ExerciseEntry(
                name: exTemplate.name,
                muscleGroup: exTemplate.group,
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
        context.insert(session)

        let lastOfName = sessions.first { $0.templateName == template.name && $0.finished != nil }

        let sortedExercises = template.exercisesArray.sorted { $0.order < $1.order }
        for (index, exTemplate) in sortedExercises.enumerated() {
            let entry = ExerciseEntry(
                name: exTemplate.name,
                muscleGroup: exTemplate.group,
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
        context.insert(session)
        activeSession = session
    }

    // MARK: - Favorites Section
    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FAVORIS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2.5)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    Text("Voir tout")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.color.accent)
                }
            }
            .padding(.horizontal)

            if favoriteExercises.isEmpty {
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "star")
                            .font(.title3)
                            .foregroundStyle(theme.color.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aucun favori")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text("Explore la bibliothèque d'exercices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favoriteExercises) { info in
                            NavigationLink {
                                ExerciseLibraryView()
                            } label: {
                                favoriteCard(info)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func favoriteCard(_ info: ExerciseInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: info.group.icon)
                    .font(.caption2)
                    .foregroundStyle(theme.color.accent)
                    .frame(width: 22, height: 22)
                    .background(theme.color.accent.opacity(0.12))
                    .clipShape(Circle())
                Spacer()
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
            Text(info.name)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if info.personalRecord > 0 {
                Text("PR: \(Int(info.personalRecord))kg")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
            } else {
                Text(info.group.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 130, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }

    // MARK: - Body Stats Card
    private var bodyStatsCard: some View {
        HStack(spacing: 16) {
            // Body map
            BodyMapView(activeGroups: recentGroups)
                .frame(width: 140, height: 220)

            // Stats
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    statBox(value: lastWeight.map { String(format: "%.1f", $0.kg) } ?? "—", label: "KG")
                    statBox(value: lastWeight?.bodyFat.map { String(format: "%.1f", $0) } ?? "—", label: "% BF")
                }
                HStack(spacing: 10) {
                    statBox(value: lastWeight?.leanMass.map { String(format: "%.1f", $0) } ?? "—",
                            label: "MM", tooltip: "Masse maigre")
                    statBox(value: lastWeight?.bmr.map { "\(Int($0))" } ?? "—",
                            label: "MB", tooltip: "Métabolisme basal")
                }
                if !recentGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(recentGroups) { group in
                                Text(group.label)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.color.accent.opacity(0.12))
                                    .foregroundStyle(theme.color.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } else {
                    Text("Aucun muscle ces 7 derniers jours")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    private func statBox(value: String, label: String, tooltip: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3)
                .fontWeight(.black)
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(.secondary)
                if tooltip != nil {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .help(tooltip ?? "")
    }

    private func lastSessionCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DERNIÈRE SÉANCE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(session.started.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
            }
            Text(session.templateName)
                .font(.headline)
            HStack(spacing: 8) {
                Text("\(session.totalSets) séries")
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("\(Int(session.totalVolume)) kg")
                if session.durationMinutes > 0 {
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(session.durationMinutes) min")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
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
            Text(template.name.isEmpty ? "Sans nom" : template.name)
                .font(.headline)
                .fontWeight(.bold)
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
