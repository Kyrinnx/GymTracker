import SwiftUI

struct ExercisePickerView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    var onSelect: (String, MuscleGroup) -> Void

    @State private var selectedGroup: MuscleGroup?
    @State private var searchText = ""
    @State private var customName = ""

    static let exercises: [MuscleGroup: [String]] = [
        .chest: ["Développé couché barre", "Développé incliné haltères", "Développé couché haltères", "Écarté poulie", "Écarté machine", "Dips pecs"],
        .back: ["Rowing barre", "Rowing haltère un bras", "Tirage vertical prise large", "Tirage horizontal câble", "Pullover poulie", "Rowing machine"],
        .shoulders: ["Développé militaire haltères", "Développé machine épaules", "Élévations latérales", "Face pull", "Oiseau", "Shrug"],
        .arms: ["Curl haltères", "Curl barre EZ", "Curl marteau", "Curl poulie", "Dips triceps", "Triceps poulie corde", "Extensions triceps overhead", "Barre au front"],
        .legs: ["Squat barre", "Presse à cuisses", "Leg extension", "Leg curl allongé", "Leg curl assis", "Fentes bulgares", "Squat bulgare", "Mollets debout", "Mollets assis", "Soulevé de terre roumain", "Hip thrust", "Hack squat"],
        .core: ["Crunch câble", "Planche", "Relevé de jambes", "Ab wheel", "Gainage latéral"],
    ]

    private var filteredExercises: [String] {
        guard let group = selectedGroup,
              let list = Self.exercises[group] else { return [] }
        if searchText.isEmpty { return list }
        return list.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let group = selectedGroup {
                    exerciseList(for: group)
                } else {
                    groupGrid
                }
            }
            .navigationTitle(selectedGroup == nil ? "Groupe musculaire" : selectedGroup!.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                if selectedGroup != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation { selectedGroup = nil }
                            searchText = ""
                            customName = ""
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
                            Text("\(Self.exercises[group]?.count ?? 0) exercices")
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
                ForEach(filteredExercises, id: \.self) { name in
                    Button {
                        onSelect(name, group)
                        dismiss()
                    } label: {
                        HStack {
                            Text(name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(theme.color.accent)
                        }
                    }
                }
            }
            Section("Exercice personnalisé") {
                HStack {
                    TextField("Nom de l'exercice", text: $customName)
                        .textInputAutocapitalization(.sentences)
                    Button {
                        guard !customName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSelect(customName.trimmingCharacters(in: .whitespaces), group)
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
}
