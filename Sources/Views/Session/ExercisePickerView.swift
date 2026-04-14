import SwiftUI

struct ExercisePickerView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    var onSelect: (String, MuscleGroup, EquipmentType) -> Void

    @State private var selectedGroup: MuscleGroup?
    @State private var selectedExercise: ExerciseDefinition?
    @State private var searchText = ""
    @State private var customName = ""
    @State private var customEquipment: EquipmentType = .barre

    private var filteredExercises: [ExerciseDefinition] {
        guard let group = selectedGroup,
              let list = ExerciseLibrary.catalog[group] else { return [] }
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var currentTitle: String {
        if selectedExercise != nil { return "Équipement" }
        if selectedGroup != nil { return selectedGroup!.label }
        return "Groupe musculaire"
    }

    var body: some View {
        NavigationStack {
            Group {
                if let exercise = selectedExercise, let group = selectedGroup {
                    equipmentGrid(exercise: exercise, group: group)
                } else if let group = selectedGroup {
                    exerciseList(for: group)
                } else {
                    groupGrid
                }
            }
            .navigationTitle(currentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                if selectedGroup != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation {
                                if selectedExercise != nil {
                                    selectedExercise = nil
                                } else {
                                    selectedGroup = nil
                                    searchText = ""
                                    customName = ""
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Group Grid

    private var groupGrid: some View {
        ScrollView {
            LazyVGrid(columns: [.init(), .init()], spacing: 14) {
                ForEach(MuscleGroup.allCases) { group in
                    Button {
                        withAnimation { selectedGroup = group }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: group.icon)
                                .font(.title2)
                                .foregroundStyle(theme.color.accent)
                            Text(group.label)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("\(ExerciseLibrary.catalog[group]?.count ?? 0) exercices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(.quaternary, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Exercise List

    private func exerciseList(for group: MuscleGroup) -> some View {
        List {
            Section {
                ForEach(filteredExercises, id: \.name) { def in
                    Button {
                        if def.equipment.count == 1 {
                            // Un seul équipement → sélection directe
                            onSelect(def.name, group, def.equipment[0])
                            dismiss()
                        } else {
                            withAnimation { selectedExercise = def }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(def.name)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 4) {
                                    ForEach(def.equipment) { eq in
                                        Text(eq.shortLabel)
                                            .font(.system(size: 10, weight: .medium))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(theme.color.accent.opacity(0.08))
                                            .foregroundStyle(theme.color.accent.opacity(0.7))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: def.equipment.count == 1 ? "plus.circle.fill" : "chevron.right")
                                .foregroundStyle(theme.color.accent)
                        }
                    }
                }
            }
            Section("Exercice personnalisé") {
                HStack {
                    TextField("Nom de l'exercice", text: $customName)
                        .textInputAutocapitalization(.sentences)
                    Menu {
                        ForEach(EquipmentType.allCases) { eq in
                            Button {
                                customEquipment = eq
                            } label: {
                                Label(eq.label, systemImage: eq.icon)
                                if customEquipment == eq {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Text(customEquipment.shortLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.color.accent.opacity(0.12))
                            .foregroundStyle(theme.color.accent)
                            .clipShape(Capsule())
                    }
                    Button {
                        guard !customName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSelect(customName.trimmingCharacters(in: .whitespaces), group, customEquipment)
                        dismiss()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.color.accent)
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher un exercice")
    }

    // MARK: - Equipment Grid

    private func equipmentGrid(exercise: ExerciseDefinition, group: MuscleGroup) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise name header
                VStack(spacing: 6) {
                    Image(systemName: group.icon)
                        .font(.largeTitle)
                        .foregroundStyle(theme.color.accent)
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Choisis l'équipement")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 10)

                // Equipment cards
                LazyVGrid(columns: [.init(), .init()], spacing: 14) {
                    ForEach(exercise.equipment) { eq in
                        Button {
                            onSelect(exercise.name, group, eq)
                            dismiss()
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: eq.icon)
                                    .font(.title)
                                    .foregroundStyle(theme.color.accent)
                                    .frame(width: 50, height: 50)
                                    .background(theme.color.accent.opacity(0.12))
                                    .clipShape(Circle())
                                Text(eq.label)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(eq.weightHint)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
