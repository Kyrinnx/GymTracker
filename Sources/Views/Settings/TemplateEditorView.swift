import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var template: CustomTemplate
    var isNew: Bool = false

    @State private var showExercisePicker = false
    @State private var pendingExercise: (name: String, group: MuscleGroup, equipment: EquipmentType)?
    @State private var showExerciseConfig = false

    // Config sheet state
    @State private var configRestSeconds: Int = 90
    @State private var configSets: Int = 3
    @State private var configReps: Int = 10

    private var sortedExercises: [CustomTemplateExercise] {
        template.exercisesArray.sorted { $0.order < $1.order }
    }

    var body: some View {
        Form {
            Section("Informations") {
                TextField("Nom de la séance", text: $template.name)
                    .font(.headline)
                TextField("Sous-titre (ex\u{00A0}: Poussée lourde)", text: $template.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                if sortedExercises.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun exercice", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Ajoute des exercices pour créer ta séance")
                    }
                } else {
                    ForEach(sortedExercises) { exercise in
                        exerciseRow(exercise)
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                }
            } header: {
                HStack {
                    Text("Exercices (\(template.exercisesArray.count))")
                    Spacer()
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Ajouter", systemImage: "plus")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle(template.name.isEmpty ? "Nouvelle séance" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        context.delete(template)
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(theme.color.accent)
            }
            if !isNew {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { name, group, equipment in
                pendingExercise = (name, group, equipment)
                configRestSeconds = 90
                configSets = 3
                configReps = 10
                showExerciseConfig = true
            }
        }
        .sheet(isPresented: $showExerciseConfig) {
            exerciseConfigSheet
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: CustomTemplateExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Summary line: [icon] Name — 3x10 — Repos 90s
            HStack(spacing: 8) {
                Image(systemName: exercise.group.icon)
                    .font(.caption)
                    .foregroundStyle(theme.color.accent)
                    .frame(width: 24, height: 24)
                    .background(theme.color.accent.opacity(0.12))
                    .clipShape(Circle())
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let eq = exercise.equipment {
                    Text(eq.shortLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(theme.color.accent.opacity(0.10))
                        .foregroundStyle(theme.color.accent)
                        .clipShape(Capsule())
                }
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("\(exercise.defaultSets)x\(exercise.defaultReps)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Repos \(exercise.restSeconds)s")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.color.accent)
            }

            // Inline editing: rest time
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Repos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { exercise.restSeconds },
                    set: { exercise.restSeconds = $0 }
                )) {
                    ForEach([30, 45, 60, 75, 90, 120, 150, 180, 240, 300], id: \.self) { s in
                        Text("\(s)s").tag(s)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            HStack(spacing: 16) {
                Stepper("Séries\u{00A0}: \(exercise.defaultSets)", value: Binding(
                    get: { exercise.defaultSets },
                    set: { exercise.defaultSets = $0 }
                ), in: 1...10)
                .font(.caption)
            }
            HStack(spacing: 16) {
                Stepper("Reps\u{00A0}: \(exercise.defaultReps)", value: Binding(
                    get: { exercise.defaultReps },
                    set: { exercise.defaultReps = $0 }
                ), in: 1...30)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Exercise Config Sheet

    private var exerciseConfigSheet: some View {
        NavigationStack {
            Form {
                if let pending = pendingExercise {
                    Section {
                        HStack {
                            Image(systemName: pending.group.icon)
                                .foregroundStyle(theme.color.accent)
                            Text(pending.name)
                                .font(.headline)
                            Text(pending.equipment.shortLabel)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.color.accent.opacity(0.12))
                                .foregroundStyle(theme.color.accent)
                                .clipShape(Capsule())
                        }
                    }
                }

                Section("Temps de repos") {
                    Picker("Repos", selection: $configRestSeconds) {
                        ForEach([30, 45, 60, 90, 120, 150, 180], id: \.self) { s in
                            Text("\(s)s").tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Séries et répétitions") {
                    Stepper("Séries\u{00A0}: \(configSets)", value: $configSets, in: 1...10)
                    Stepper("Répétitions\u{00A0}: \(configReps)", value: $configReps, in: 1...30)
                }
            }
            .navigationTitle("Configurer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        pendingExercise = nil
                        showExerciseConfig = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        if let pending = pendingExercise {
                            let nextOrder = (template.exercisesArray.map(\.order).max() ?? -1) + 1
                            let ex = CustomTemplateExercise(
                                name: pending.name,
                                muscleGroup: pending.group,
                                equipment: pending.equipment,
                                scheme: "\(configSets)x\(configReps)",
                                restSeconds: configRestSeconds,
                                defaultSets: configSets,
                                defaultReps: configReps,
                                order: nextOrder
                            )
                            if template.exercises == nil { template.exercises = [] }
                            template.exercises?.append(ex)
                        }
                        pendingExercise = nil
                        showExerciseConfig = false
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = sortedExercises
        for index in offsets {
            let exercise = sorted[index]
            context.delete(exercise)
        }
        reorderExercises()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var ordered = sortedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, ex) in ordered.enumerated() {
            ex.order = i
        }
    }

    private func reorderExercises() {
        let sorted = template.exercisesArray.sorted { $0.order < $1.order }
        for (i, ex) in sorted.enumerated() {
            ex.order = i
        }
    }
}
