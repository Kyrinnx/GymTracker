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
                            Text(userName.isEmpty ? "Salut !" : userName)
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
                    rankBar
                        .padding(.horizontal)

                    // Streak + week days
                    streakCard
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
                        lastSessionCard(last)
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
        .alert("Supprimer ce programme ?", isPresented: Binding(
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

    // MARK: - Rank Bar

    private var currentRank: Rank { Rank.from(xp: totalXP) }

    private var rankBar: some View {
        let rank = currentRank
        let nextRank = rank.next
        let xpInRank = totalXP - rank.xpRequired
        let xpForNext = (nextRank?.xpRequired ?? rank.xpRequired) - rank.xpRequired
        let progress: Double = xpForNext > 0 ? min(Double(xpInRank) / Double(xpForNext), 1.0) : 1.0

        return HStack(spacing: 12) {
            // Rank icon
            Image(systemName: rank.icon)
                .font(.title3)
                .foregroundStyle(rank.color)
                .frame(width: 36, height: 36)
                .background(rank.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(rank.label)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(rank.color)
                    Spacer()
                    Text("\(totalXP) XP")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 6)
                        Capsule()
                            .fill(rank.color.gradient)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                if let next = nextRank {
                    Text("\(next.xpRequired - totalXP) XP avant \(next.label)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        let streak = StreakCalculator.currentStreak(sessions: Array(sessions), weeklyGoal: weeklyGoal)
        let days = StreakCalculator.weekDays(sessions: Array(sessions))
        let dayLabels = ["L", "M", "M", "J", "V", "S", "D"]
        let calendar = Calendar.current
        let todayIndex = (calendar.component(.weekday, from: Date()) + 5) % 7

        return HStack(spacing: 0) {
            // Flame + streak count
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            streak > 0
                            ? LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                        )
                        .symbolEffect(.pulse, options: .repeating, isActive: streak > 0)
                }
                Text("\(streak)")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundStyle(streak > 0 ? .orange : .secondary)
                Text("JOURS")
                    .font(.system(size: 7))
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70)

            // Week days
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(dayLabels[i])
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(i == todayIndex ? .primary : .secondary)

                        ZStack {
                            Circle()
                                .fill(days[i] ? theme.color.accent : Color(.systemGray5))
                                .frame(width: 28, height: 28)
                            if days[i] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    statBox(value: lastWeight.map { String(format: "%.1f", $0.kg) } ?? "—", label: "KG", tooltip: "Poids actuel")
                    statBox(value: lastWeight?.bodyFat.map { String(format: "%.1f", $0) } ?? "—", label: "% BF", tooltip: "Taux de masse grasse")
                }
                HStack(spacing: 10) {
                    statBox(value: lastWeight?.leanMass.map { String(format: "%.1f", $0) } ?? "—",
                            label: "MM", tooltip: "Masse maigre (poids - gras)")
                    statBox(value: lastWeight?.bmr.map { "\(Int($0))" } ?? "—",
                            label: "MB", tooltip: "Métabolisme basal (kcal/jour)")
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
        StatBoxView(value: value, label: label, tooltip: tooltip)
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
// MARK: - Stat Box with Tooltip

private struct StatBoxView: View {
    let value: String
    let label: String
    let tooltip: String?
    @State private var showTooltip = false

    var body: some View {
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
        .onTapGesture {
            if tooltip != nil {
                showTooltip = true
            }
        }
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            Text(tooltip ?? "")
                .font(.subheadline)
                .padding(12)
                .presentationCompactAdaptation(.popover)
        }
    }
}

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

// MARK: - AI Import Sheet

// MARK: - Program Library

struct ProgramLibraryView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomTemplate.order) private var customTemplates: [CustomTemplate]

    @State private var addedTemplateId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(WorkoutTemplate.grouped, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.category.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ForEach(group.templates) { tpl in
                            libraryRow(tpl)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Bibliothèque")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func libraryRow(_ tpl: WorkoutTemplate) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tpl.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(tpl.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    let groups = Array(Set(tpl.exercises.map(\.group)))
                    ForEach(groups) { g in
                        Image(systemName: g.icon)
                            .font(.caption2)
                            .foregroundStyle(theme.color.accent)
                    }
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(tpl.exercises.count) exos")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button {
                addToMyPrograms(tpl)
            } label: {
                Image(systemName: addedTemplateId == tpl.id ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(addedTemplateId == tpl.id ? .green : theme.color.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .disabled(addedTemplateId == tpl.id)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func addToMyPrograms(_ template: WorkoutTemplate) {
        let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
        let custom = CustomTemplate(name: template.name, subtitle: template.subtitle, order: nextOrder)
        context.insert(custom)
        for (i, ex) in template.exercises.enumerated() {
            let cex = CustomTemplateExercise(
                name: ex.name,
                muscleGroup: ex.group,
                scheme: ex.scheme,
                restSeconds: 90,
                defaultSets: ex.defaultSets.count,
                defaultReps: ex.defaultSets.first?.reps ?? 10,
                order: i
            )
            if custom.exercises == nil { custom.exercises = [] }
            custom.exercises?.append(cex)
        }
        withAnimation { addedTemplateId = template.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { addedTemplateId = nil }
        }
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

        Réponds UNIQUEMENT avec du JSON valide, sans texte avant ni après.

        Si c'est UNE seule séance :
        {"name": "Nom", "subtitle": "Description", "exercises": [{"name": "Nom exercice", "muscle": "chest", "sets": 4, "reps": 10, "rest": 90}]}

        Si c'est PLUSIEURS séances (programme complet) :
        [{"name": "Séance 1", "subtitle": "...", "exercises": [...]}, {"name": "Séance 2", "subtitle": "...", "exercises": [...]}]

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
              let parsed = try? JSONSerialization.jsonObject(with: data) else {
            isError = true
            resultMessage = "JSON invalide. Vérifie que tu as bien copié toute la réponse de l'IA, sans texte avant ni après."
            return
        }

        // Support both single object and array of objects
        let sessions: [[String: Any]]
        if let array = parsed as? [[String: Any]] {
            sessions = array
        } else if let single = parsed as? [String: Any] {
            sessions = [single]
        } else {
            isError = true
            resultMessage = "Format JSON non reconnu. Attendu : un objet ou un tableau d'objets."
            return
        }

        guard !sessions.isEmpty else {
            isError = true
            resultMessage = "Aucune séance trouvée dans le JSON."
            return
        }

        let validMuscles = Set(MuscleGroup.allCases.map(\.rawValue))
        let baseOrder = (try? context.fetchCount(FetchDescriptor<CustomTemplate>())) ?? 0
        var totalExercises = 0

        for (sessionIndex, json) in sessions.enumerated() {
            let name = json["name"] as? String ?? "Séance \(sessionIndex + 1)"
            let subtitle = json["subtitle"] as? String ?? ""

            guard let exercisesJSON = json["exercises"] as? [[String: Any]], !exercisesJSON.isEmpty else {
                continue
            }

            let template = CustomTemplate(name: name, subtitle: subtitle, order: baseOrder + sessionIndex)
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
            totalExercises += exercisesJSON.count
        }

        if sessions.count == 1 {
            let name = sessions[0]["name"] as? String ?? "Programme importé"
            resultMessage = "\"\(name)\" importé avec \(totalExercises) exercices !"
        } else {
            resultMessage = "\(sessions.count) séances importées avec \(totalExercises) exercices au total !"
        }
        isError = false
    }
}
