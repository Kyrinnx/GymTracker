import SwiftUI
import SwiftData

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
            .padding(.top, 16)
            .padding(.bottom, 80)
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
                    Text("\(tpl.exercises.count)\u{00A0}exos")
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
            .accessibilityLabel(addedTemplateId == tpl.id ? "Ajouté" : "Ajouter \(tpl.name) à mes programmes")
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
        withAnimation { addedTemplateId = template.id }
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation { addedTemplateId = nil }
        }
    }
}
