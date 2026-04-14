import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: WorkoutSession
    @Query private var exerciseInfos: [ExerciseInfo]
    @Query(sort: \WorkoutSession.started, order: .reverse) private var allSessions: [WorkoutSession]

    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    // Pause
    @State private var isPaused = false
    @State private var pauseStart: Date?
    @State private var totalPausedSeconds: TimeInterval = 0

    // Rest timer (date-based for background support)
    @State private var restDuration: Int = 90
    @State private var activeRestDuration: Int = 90
    @State private var restRemaining: Int = 0
    @State private var restTimer: Timer?
    @State private var showRestOverlay = false
    @State private var restEndDate: Date?

    // XP
    @State private var xpBreakdown: XPBreakdown?
    @State private var showXPOverlay = false

    // Pickers / Sheets
    @State private var showExercisePicker = false
    @State private var showRestConfig = false
    @State private var showCancelConfirm = false
    @State private var showFinishConfirm = false
    @State private var showSaveAsTemplate = false

    // Edit exercise
    @State private var editingExercise: ExerciseEntry?
    @State private var editedName: String = ""
    @State private var oldExerciseName: String = ""
    @State private var showRenameAlert = false
    @State private var showUpdateTemplateConfirm = false

    // Drag-and-drop reorder
    @State private var draggedExercise: ExerciseEntry?

    @Query(sort: \CustomTemplate.order) private var customTemplates: [CustomTemplate]

    private var elapsedMinutes: Int { elapsedSeconds / 60 }
    private var estimatedCalories: Int { elapsedMinutes * 7 }

    private var sortedExercises: [ExerciseEntry] {
        let sorted = session.exercisesArray.sorted { $0.order < $1.order }
        // Move completed exercises to bottom
        let incomplete = sorted.filter { !isExerciseComplete($0) }
        let complete = sorted.filter { isExerciseComplete($0) }
        return incomplete + complete
    }

    private func isExerciseComplete(_ exercise: ExerciseEntry) -> Bool {
        let sets = exercise.setsArray
        return !sets.isEmpty && sets.allSatisfy(\.done)
    }

    var body: some View {
        ZStack {
            mainContent
            if showRestOverlay {
                SessionRestOverlay(
                    remaining: restRemaining,
                    total: activeRestDuration,
                    onDismiss: dismissRest
                )
            }
            if showXPOverlay, let breakdown = xpBreakdown {
                SessionXPOverlay(
                    breakdown: breakdown,
                    totalXP: totalXP,
                    onContinue: dismissXPAndFinish
                )
            }
        }
        .onAppear(perform: startElapsedTimer)
        .onDisappear(perform: stopAllTimers)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Restore rest timer from background
            if let endDate = restEndDate {
                let remaining = Int(endDate.timeIntervalSinceNow)
                if remaining > 0 {
                    restRemaining = remaining
                } else {
                    dismissRest()
                }
            }
        }
        .alert("Renommer l'exercice", isPresented: $showRenameAlert) {
            TextField("Nom", text: $editedName)
            Button("Annuler", role: .cancel) {}
            Button("OK") {
                if let ex = editingExercise, !editedName.isEmpty {
                    oldExerciseName = ex.name
                    ex.name = editedName
                    // Check if a saved template contains the old exercise name
                    let hasTemplate = customTemplates.contains { tpl in
                        tpl.name == session.templateName &&
                        tpl.exercisesArray.contains { $0.name == oldExerciseName }
                    }
                    if hasTemplate {
                        showUpdateTemplateConfirm = true
                    }
                }
            }
        }
        .confirmationDialog("Mettre à jour le programme\u{00A0}?", isPresented: $showUpdateTemplateConfirm, titleVisibility: .visible) {
            Button("Oui, remplacer dans le programme") {
                if let tpl = customTemplates.first(where: { $0.name == session.templateName }),
                   let tplEx = tpl.exercisesArray.first(where: { $0.name == oldExerciseName }) {
                    tplEx.name = editedName
                }
            }
            Button("Non, juste cette séance", role: .cancel) {}
        } message: {
            Text("L'exercice «\u{00A0}\(oldExerciseName)\u{00A0}» existe dans ton programme «\u{00A0}\(session.templateName)\u{00A0}». Veux-tu le remplacer par «\u{00A0}\(editedName)\u{00A0}»\u{00A0}?")
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { name, group, equipment in
                addExercise(name: name, group: group, equipment: equipment)
            }
        }
        .confirmationDialog("Annuler la séance\u{00A0}?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Annuler la séance", role: .destructive) {
                cancelSession()
            }
            Button("Continuer", role: .cancel) {}
        } message: {
            Text("Toute la progression sera perdue.")
        }
        .confirmationDialog("Terminer la séance\u{00A0}?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Terminer") {
                finishSession()
            }
            Button("Continuer", role: .cancel) {}
        } message: {
            Text("Les séries non complétées seront ignorées.")
        }
        .confirmationDialog("Séance terminée\u{00A0}!", isPresented: $showSaveAsTemplate, titleVisibility: .visible) {
            Button("Sauvegarder comme programme") {
                saveSessionAsTemplate()
                dismiss()
            }
            Button("Non merci", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Veux-tu sauvegarder cette séance comme programme\u{00A0}?")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    exercisesList
                    addExerciseButton
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(session.templateName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showCancelConfirm = true
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminer") {
                        showFinishConfirm = true
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Text(formattedElapsed)
                            .font(.title2)
                            .fontWeight(.black)
                            .monospacedDigit()
                        Button {
                            togglePause()
                        } label: {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.caption)
                                .foregroundStyle(isPaused ? .green : .secondary)
                                .frame(width: 28, height: 28)
                                .background(isPaused ? Color.green.opacity(0.15) : Color(.systemGray5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPaused ? "Reprendre la séance" : "Mettre en pause")
                    }
                    Text(isPaused ? "EN PAUSE" : "DURÉE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(isPaused ? .orange : .secondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(estimatedCalories)")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundStyle(theme.color.accent)
                    Text("KCAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(session.totalSets)")
                        .font(.title2)
                        .fontWeight(.black)
                    Text("SÉRIES")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    // MARK: - Exercises List

    private var exercisesList: some View {
        ForEach(sortedExercises) { exercise in
            exerciseCard(exercise)
                .padding(.horizontal)
                .onDrag {
                    draggedExercise = exercise
                    return NSItemProvider(object: "\(exercise.order)" as NSString)
                } preview: {
                    // Preview arrondi avec ombre pour le drag
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .onDrop(of: [.text], delegate: ExerciseDropDelegate(
                    target: exercise,
                    dragged: $draggedExercise,
                    session: session
                ))
        }
    }

    private func infoFor(_ exercise: ExerciseEntry) -> ExerciseInfo? {
        exerciseInfos.first { $0.name == exercise.name }
    }

    private func toggleFavorite(_ exercise: ExerciseEntry) {
        if let info = infoFor(exercise) {
            info.isFavorite.toggle()
        } else {
            let info = ExerciseInfo(name: exercise.name, muscleGroup: exercise.group, isFavorite: true)
            context.insert(info)
        }
    }

    private func exerciseCard(_ exercise: ExerciseEntry) -> some View {
        let isFav = infoFor(exercise)?.isFavorite ?? false
        return VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                Button { toggleFavorite(exercise) } label: {
                    Image(systemName: isFav ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(isFav ? Color.yellow : Color.gray.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFav ? "Retirer \(exercise.name) des favoris" : "Ajouter \(exercise.name) aux favoris")
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    HStack(spacing: 6) {
                        Text(exercise.group.label)
                            .font(.caption)
                            .foregroundStyle(theme.color.accent)
                        if let eq = exercise.equipment {
                            Text(eq.shortLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.color.accent.opacity(0.10))
                                .foregroundStyle(theme.color.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
                Menu {
                    Button {
                        editingExercise = exercise
                        editedName = exercise.name
                        showRenameAlert = true
                    } label: {
                        Label("Renommer", systemImage: "pencil")
                    }
                    // Equipment submenu
                    Menu {
                        ForEach(EquipmentType.allCases) { eq in
                            Button {
                                exercise.equipmentType = eq.rawValue
                            } label: {
                                HStack {
                                    Label(eq.label, systemImage: eq.icon)
                                    if exercise.equipment == eq {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Équipement", systemImage: "wrench.and.screwdriver")
                    }
                    if exercise.order > 0 {
                        Button {
                            moveExercise(exercise, direction: -1)
                        } label: {
                            Label("Monter", systemImage: "arrow.up")
                        }
                    }
                    let maxOrder = session.exercisesArray.map(\.order).max() ?? 0
                    if exercise.order < maxOrder {
                        Button {
                            moveExercise(exercise, direction: 1)
                        } label: {
                            Label("Descendre", systemImage: "arrow.down")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        deleteExercise(exercise)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Options pour \(exercise.name)")
                Menu {
                    ForEach([0, 30, 60, 90, 120, 180], id: \.self) { duration in
                        Button {
                            exercise.restSeconds = duration
                        } label: {
                            if duration == 0 {
                                Label("Désactivé", systemImage: exercise.restSeconds == 0 ? "checkmark" : "")
                            } else {
                                Label("\(duration)s", systemImage: exercise.restSeconds == duration ? "checkmark" : "")
                            }
                        }
                    }
                } label: {
                    Label(exercise.restSeconds > 0 ? "\(exercise.restSeconds)s" : "Off", systemImage: "timer")
                        .font(.caption2)
                        .foregroundStyle(exercise.restSeconds > 0 ? theme.color.accent : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(exercise.restSeconds > 0 ? theme.color.accent.opacity(0.12) : Color(.systemGray6))
                        .clipShape(Capsule())
                }
                if !exercise.scheme.isEmpty {
                    Text(exercise.scheme)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            // Sets header
            HStack(spacing: 0) {
                Text("SÉRIE")
                    .frame(width: 44, alignment: .leading)
                Group {
                    if exercise.equipment == .pdc {
                        Text("KG (+)")
                    } else if exercise.equipment == .halteres {
                        Text("KG /MAIN")
                    } else {
                        Text("KG")
                    }
                }
                .frame(maxWidth: .infinity)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: 44)
            }
            .font(.caption2)
            .fontWeight(.bold)
            .tracking(1)
            .foregroundStyle(.tertiary)

            // Sets rows
            let sortedSets = exercise.setsArray.sorted { $0.order < $1.order }
            ForEach(sortedSets) { set in
                setRow(set: set, exercise: exercise)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSet(set, from: exercise)
                        } label: {
                            Label("Supprimer la série", systemImage: "trash")
                        }
                    }
            }

            // Add set button
            Button {
                addSet(to: exercise)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Ajouter une série")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(theme.color.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Undo completed: tap to unmark all sets
            if isExerciseComplete(exercise) {
                Button {
                    for s in exercise.setsArray { s.done = false }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Remettre l'exercice")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .opacity(isExerciseComplete(exercise) ? 0.5 : 1.0)
    }

    private func setRow(set: WorkoutSet, exercise: ExerciseEntry) -> some View {
        HStack(spacing: 0) {
            Text("\(set.order + 1)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            kgField(set: set, exercise: exercise)
                .frame(maxWidth: .infinity)

            repsField(set: set, exercise: exercise)
                .frame(maxWidth: .infinity)

            Button {
                toggleDone(set, exercise: exercise)
            } label: {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.done ? theme.color.accent : Color.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .frame(width: 44)
            .accessibilityLabel(set.done ? "Série \(set.order + 1) terminée" : "Marquer la série \(set.order + 1) comme terminée")
        }
        .padding(.vertical, 2)
    }

    @State private var kgTexts: [PersistentIdentifier: [Int: String]] = [:]
    @State private var repsTexts: [PersistentIdentifier: [Int: String]] = [:]

    private func kgField(set: WorkoutSet, exercise: ExerciseEntry) -> some View {
        let binding = Binding<String>(
            get: {
                kgTexts[exercise.persistentModelID]?[set.order] ?? (set.kg > 0 ? formatKg(set.kg) : "")
            },
            set: { newVal in
                kgTexts[exercise.persistentModelID, default: [:]][set.order] = newVal
                if let val = Double(newVal.replacingOccurrences(of: ",", with: ".")) {
                    set.kg = val
                } else if newVal.isEmpty {
                    set.kg = 0
                }
            }
        )
        let placeholder = exercise.equipment == .pdc ? "PDC" : "0"
        return TextField(placeholder, text: binding)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(width: 60)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func repsField(set: WorkoutSet, exercise: ExerciseEntry) -> some View {
        let binding = Binding<String>(
            get: {
                repsTexts[exercise.persistentModelID]?[set.order] ?? (set.reps > 0 ? "\(set.reps)" : "")
            },
            set: { newVal in
                repsTexts[exercise.persistentModelID, default: [:]][set.order] = newVal
                if let val = Int(newVal) {
                    set.reps = val
                } else if newVal.isEmpty {
                    set.reps = 0
                }
            }
        )
        return TextField("0", text: binding)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(width: 60)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatKg(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(kg))" : String(format: "%.1f", kg)
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Ajouter un exercice")
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // MARK: - Computed

    private var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Actions

    private func startElapsedTimer() {
        updateElapsed()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateElapsed()
            // Also update rest timer from date if running
            if let endDate = restEndDate {
                let remaining = Int(endDate.timeIntervalSinceNow)
                if remaining > 0 {
                    restRemaining = remaining
                } else if showRestOverlay {
                    dismissRest()
                }
            }
        }
    }

    private func updateElapsed() {
        guard !isPaused else { return }
        let total = Date().timeIntervalSince(session.started) - totalPausedSeconds
        elapsedSeconds = max(0, Int(total))
    }

    private func togglePause() {
        if isPaused {
            // Resume
            if let start = pauseStart {
                totalPausedSeconds += Date().timeIntervalSince(start)
            }
            pauseStart = nil
            isPaused = false
        } else {
            // Pause
            pauseStart = Date()
            isPaused = true
        }
    }

    private func stopAllTimers() {
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil
    }

    private func toggleDone(_ set: WorkoutSet, exercise: ExerciseEntry) {
        set.done.toggle()
        if set.done && exercise.restSeconds > 0 {
            startRestTimer(duration: exercise.restSeconds, exerciseName: exercise.name)
        }
    }

    private func startRestTimer(duration: Int? = nil, exerciseName: String = "") {
        restTimer?.invalidate()
        activeRestDuration = duration ?? restDuration
        restRemaining = activeRestDuration
        restEndDate = Date().addingTimeInterval(Double(activeRestDuration))
        showRestOverlay = true
        // Timer is now driven by restEndDate in the main timer loop
    }

    private func dismissRest() {
        restTimer?.invalidate()
        restTimer = nil
        restEndDate = nil
        showRestOverlay = false
    }

    private func addSet(to exercise: ExerciseEntry) {
        let nextOrder = (exercise.setsArray.map(\.order).max() ?? -1) + 1
        let newSet = WorkoutSet(kg: 0, reps: 0, done: false, order: nextOrder)
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(newSet)
    }

    private func deleteSet(_ set: WorkoutSet, from exercise: ExerciseEntry) {
        exercise.sets?.removeAll { $0 === set }
        // Re-pack orders
        for (i, s) in exercise.setsArray.sorted(by: { $0.order < $1.order }).enumerated() {
            s.order = i
        }
    }

    private func deleteExercise(_ exercise: ExerciseEntry) {
        session.exercises?.removeAll { $0 === exercise }
        for (i, ex) in session.exercisesArray.sorted(by: { $0.order < $1.order }).enumerated() {
            ex.order = i
        }
    }

    private func moveExercise(_ exercise: ExerciseEntry, direction: Int) {
        let sorted = session.exercisesArray.sorted { $0.order < $1.order }
        guard let idx = sorted.firstIndex(where: { $0 === exercise }) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0, newIdx < sorted.count else { return }
        // Swap orders
        let temp = sorted[idx].order
        sorted[idx].order = sorted[newIdx].order
        sorted[newIdx].order = temp
    }

    private func addExercise(name: String, group: MuscleGroup, equipment: EquipmentType? = nil) {
        let nextOrder = (session.exercisesArray.map(\.order).max() ?? -1) + 1
        let entry = ExerciseEntry(name: name, muscleGroup: group, equipment: equipment, scheme: "", order: nextOrder)
        for i in 0..<3 {
            if entry.sets == nil { entry.sets = [] }
            entry.sets?.append(WorkoutSet(kg: 0, reps: 0, done: false, order: i))
        }
        if session.exercises == nil { session.exercises = [] }
        session.exercises?.append(entry)
    }

    private func finishSession() {
        session.finished = Date()
        session.caloriesBurned = estimatedCalories

        // Find previous session of same template for XP comparison
        let previousSession = allSessions.first {
            $0.templateName == session.templateName && $0.finished != nil
        }

        // Streak & weekly count for XP bonuses
        let streak = StreakCalculator.currentStreak(sessions: Array(allSessions), weeklyGoal: weeklyGoal)
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let weekCount = allSessions.filter { $0.finished != nil && $0.started > weekStart }.count

        // Calculate XP BEFORE inserting (exerciseInfos has current PRs)
        let breakdown = XPCalculator.calculate(
            session: session,
            previousSession: previousSession,
            exerciseInfos: Array(exerciseInfos),
            currentStreak: streak,
            weekSessionCount: weekCount,
            weeklyGoal: weeklyGoal
        )

        // Insert session into database only when finished
        context.insert(session)

        // Auto-add new exercises to database + update PRs
        for exercise in session.exercisesArray {
            let bestKg = exercise.setsArray.filter { $0.done && $0.kg > 0 }.map(\.kg).max() ?? 0
            if let info = infoFor(exercise) {
                if bestKg > info.personalRecord { info.personalRecord = bestKg }
            } else {
                let info = ExerciseInfo(name: exercise.name, muscleGroup: exercise.group, personalRecord: bestKg)
                context.insert(info)
            }
        }

        // Award XP
        session.xpAwarded = breakdown.total
        totalXP = max(0, totalXP + breakdown.total)
        xpBreakdown = breakdown

        stopAllTimers()

        // Auto-backup right after a session is completed — captures the new data
        // before the app can be killed or the device rebooted.
        AutoBackupService.backupAfterSessionCompletion(context: context)

        // Show XP overlay
        withAnimation(.spring(duration: 0.5)) {
            showXPOverlay = true
        }
    }

    private func dismissXPAndFinish() {
        showXPOverlay = false
        let alreadySaved = customTemplates.contains { $0.name == session.templateName }
        if alreadySaved || session.templateName == "Séance libre" {
            dismiss()
        } else {
            showSaveAsTemplate = true
        }
    }

    private func saveSessionAsTemplate() {
        let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
        let custom = CustomTemplate(name: session.templateName, subtitle: "", order: nextOrder)
        context.insert(custom)
        for ex in session.exercisesArray.sorted(by: { $0.order < $1.order }) {
            let doneSetsCount = ex.setsArray.filter(\.done).count
            let firstReps = ex.setsArray.sorted(by: { $0.order < $1.order }).first?.reps ?? 10
            let cex = CustomTemplateExercise(
                name: ex.name,
                muscleGroup: ex.group,
                equipment: ex.equipment,
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

    private func cancelSession() {
        stopAllTimers()
        dismiss()
    }
}
