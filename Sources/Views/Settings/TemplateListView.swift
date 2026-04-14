import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomTemplate.order) private var customTemplates: [CustomTemplate]

    var body: some View {
        List {
            Section {
                if customTemplates.isEmpty {
                    ContentUnavailableView {
                        Label("Aucune séance", systemImage: "dumbbell")
                    } description: {
                        Text("Crée ta première séance personnalisée")
                    }
                } else {
                    ForEach(customTemplates) { tpl in
                        NavigationLink {
                            TemplateEditorView(template: tpl)
                        } label: {
                            customTemplateRow(tpl)
                        }
                    }
                    .onDelete(perform: deleteCustomTemplates)
                }
            } header: {
                Text("Mes séances")
            }

            Section("Programmes par défaut") {
                ForEach(WorkoutTemplate.all) { tpl in
                    builtInRow(tpl)
                }
            }
        }
        .navigationTitle("Séances")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addNewTemplate()
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .foregroundStyle(theme.color.accent)
                }
                .accessibilityLabel("Ajouter une séance personnalisée")
            }
        }
    }

    // MARK: - Rows

    private func customTemplateRow(_ tpl: CustomTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tpl.name.isEmpty ? "Sans nom" : tpl.name)
                .font(.headline)
                .fontWeight(.bold)
            if !tpl.subtitle.isEmpty {
                Text(tpl.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("\(tpl.exercisesArray.count) exercices")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func builtInRow(_ tpl: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tpl.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(tpl.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(tpl.exercises.count) exercices")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func addNewTemplate() {
        let nextOrder = (customTemplates.map(\.order).max() ?? -1) + 1
        let tpl = CustomTemplate(name: "", subtitle: "", order: nextOrder)
        context.insert(tpl)
    }

    private func deleteCustomTemplates(at offsets: IndexSet) {
        for index in offsets {
            context.delete(customTemplates[index])
        }
    }
}
