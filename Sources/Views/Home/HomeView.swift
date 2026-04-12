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
    @State private var newTemplate: CustomTemplate?
    @State private var showAIImport = false

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
        .sheet(item: $newTemplate) { tpl in
            NavigationStack {
                TemplateEditorView(template: tpl)
            }
        }
        .sheet(isPresented: $showAIImport) {
            AIImportSheet()
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

// MARK: - AI Import Sheet

private struct AIImportSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var userDescription = ""
    @State private var jsonResponse = ""
    @State private var resultMessage: String?
    @State private var isError = false
    @State private var copied = false

    private var promptText: String {
        let description = userDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholder = description.isEmpty ? "[décris ton programme ici]" : description
        return """
        Crée-moi un programme de musculation : \(placeholder).

        Réponds UNIQUEMENT avec du JSON valide, sans texte avant ni après, dans ce format exact :
        {
          "name": "Nom du programme",
          "subtitle": "Description courte",
          "exercises": [
            {"name": "Nom exercice", "muscle": "chest", "sets": 4, "reps": 10, "rest": 90}
          ]
        }

        Valeurs possibles pour "muscle" : chest, back, shoulders, arms, legs, core.
        "rest" est en secondes (30, 45, 60, 90, 120, 150, 180).
        """
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Étape", selection: $selectedTab) {
                    Text("1. Copier le prompt").tag(0)
                    Text("2. Coller la réponse").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    promptStep
                } else {
                    responseStep
                }
            }
            .navigationTitle("Importer via IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert(isError ? "Erreur" : "Importé", isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )) {
                Button("OK") {
                    if !isError {
                        dismiss()
                    }
                }
            } message: {
                Text(resultMessage ?? "")
            }
        }
    }

    // MARK: - Step 1: Prompt

    private var promptStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Décris le programme souhaité :")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    TextField("Ex : programme push/pull/legs 4 jours", text: $userDescription)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt à copier :")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(promptText)
                        .font(.caption)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    UIPasteboard.general.string = promptText
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copié !" : "Copier le prompt")
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

                VStack(alignment: .leading, spacing: 6) {
                    Label("Comment faire", systemImage: "questionmark.circle")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("1. Copie le prompt ci-dessus\n2. Colle-le dans ChatGPT ou Claude\n3. Copie la réponse JSON\n4. Reviens ici, onglet \"2. Coller la réponse\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    // MARK: - Step 2: Response

    private var responseStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Colle la réponse JSON de l'IA :")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextEditor(text: $jsonResponse)
                    .font(.caption.monospaced())
                    .frame(maxHeight: .infinity)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                importJSON()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Importer")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(jsonResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.gray
                    : theme.color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(jsonResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    // MARK: - JSON Parsing

    private func importJSON() {
        let trimmed = jsonResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            isError = true
            resultMessage = "JSON invalide. Vérifie que tu as bien copié toute la réponse de l'IA, sans texte avant ni après."
            return
        }

        let name = json["name"] as? String ?? "Programme importé"
        let subtitle = json["subtitle"] as? String ?? ""

        guard let exercisesJSON = json["exercises"] as? [[String: Any]], !exercisesJSON.isEmpty else {
            isError = true
            resultMessage = "Aucun exercice trouvé dans le JSON. Le champ \"exercises\" est manquant ou vide."
            return
        }

        let validMuscles = Set(MuscleGroup.allCases.map(\.rawValue))
        let nextTemplateOrder = (try? context.fetchCount(FetchDescriptor<CustomTemplate>())) ?? 0

        let template = CustomTemplate(name: name, subtitle: subtitle, order: nextTemplateOrder)
        context.insert(template)

        for (index, exJSON) in exercisesJSON.enumerated() {
            let exName = exJSON["name"] as? String ?? "Exercice \(index + 1)"
            let muscleRaw = exJSON["muscle"] as? String ?? "chest"
            let muscleGroup = validMuscles.contains(muscleRaw) ? MuscleGroup(rawValue: muscleRaw)! : .chest
            let sets = exJSON["sets"] as? Int ?? 3
            let reps = exJSON["reps"] as? Int ?? 10
            let rest = exJSON["rest"] as? Int ?? 90

            let exercise = CustomTemplateExercise(
                name: exName,
                muscleGroup: muscleGroup,
                scheme: "\(sets)x\(reps)",
                restSeconds: rest,
                defaultSets: sets,
                defaultReps: reps,
                order: index
            )
            if template.exercises == nil { template.exercises = [] }
            template.exercises?.append(exercise)
        }

        isError = false
        resultMessage = "\"\(name)\" importé avec \(exercisesJSON.count) exercices !"
    }
}
