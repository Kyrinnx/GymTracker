import SwiftUI
import SwiftData

struct AIImportSheet: View {
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
        {"name": "Nom", "subtitle": "Description", "exercises": [{"name": "Nom exercice", "muscle": "chest", "equipment": "barre", "sets": 4, "reps": "8-12", "rest": 90}]}

        Si c'est PLUSIEURS séances (programme complet) :
        [{"name": "Séance 1", "subtitle": "...", "exercises": [...]}, {"name": "Séance 2", "subtitle": "...", "exercises": [...]}]

        Valeurs possibles pour "muscle" : chest, back, shoulders, arms, legs, core.
        Valeurs possibles pour "equipment" : barre, halteres, machine, poulie, pdc.
        "reps" peut être un nombre (10) ou une fourchette ("8-12", "10-15"). Utilise des fourchettes quand c'est pertinent.
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
                    Text("Décris le programme souhaité\u{00A0}:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    TextField("Ex\u{00A0}: programme push/pull/legs 4 jours", text: $userDescription)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt à copier\u{00A0}:")
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
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copié\u{00A0}!" : "Copier le prompt")
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
                    Text("1. Copie le prompt ci-dessus\n2. Colle-le dans ChatGPT ou Claude\n3. Copie la réponse JSON\n4. Reviens ici, onglet « 2. Coller la réponse »")
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
                Text("Colle la réponse JSON de l'IA\u{00A0}:")
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

        // Strip code-fence wrappers if the model added them (```json ... ```)
        let cleaned = stripCodeFences(trimmed)

        guard let data = cleaned.data(using: .utf8),
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
            resultMessage = "Format JSON non reconnu. Attendu\u{00A0}: un objet ou un tableau d'objets."
            return
        }

        guard !sessions.isEmpty else {
            isError = true
            resultMessage = "Aucune séance trouvée dans le JSON."
            return
        }

        let baseOrder = (try? context.fetchCount(FetchDescriptor<CustomTemplate>())) ?? 0
        var totalExercises = 0
        var importedSessions = 0

        for (sessionIndex, json) in sessions.enumerated() {
            let rawName = (json["name"] as? String) ?? ""
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Séance \(sessionIndex + 1)"
                : rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            let subtitle = ((json["subtitle"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            guard let exercisesJSON = json["exercises"] as? [[String: Any]], !exercisesJSON.isEmpty else {
                continue
            }

            let template = CustomTemplate(name: name, subtitle: subtitle, order: baseOrder + importedSessions)
            context.insert(template)
            importedSessions += 1

            for (index, exJSON) in exercisesJSON.enumerated() {
                let rawExName = (exJSON["name"] as? String) ?? ""
                let exName = rawExName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Exercice \(index + 1)"
                    : rawExName.trimmingCharacters(in: .whitespacesAndNewlines)

                let muscleRaw = (exJSON["muscle"] as? String)?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "chest"
                let muscleGroup = MuscleGroup(rawValue: muscleRaw) ?? .chest

                let equipmentRaw = (exJSON["equipment"] as? String)?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let equipmentType: EquipmentType? = EquipmentType(rawValue: equipmentRaw)
                    ?? equipmentAlias(equipmentRaw)

                // sets can be Int or String — clamp to 1...10
                let setsRaw: Int
                if let s = exJSON["sets"] as? Int { setsRaw = s }
                else if let s = exJSON["sets"] as? String, let parsed = Int(s) { setsRaw = parsed }
                else { setsRaw = 3 }
                let sets = max(1, min(setsRaw, 10))

                // rest: clamp to 0...600 seconds
                let restRaw: Int
                if let r = exJSON["rest"] as? Int { restRaw = r }
                else if let r = exJSON["rest"] as? String, let parsed = Int(r) { restRaw = parsed }
                else { restRaw = 90 }
                let rest = max(0, min(restRaw, 600))

                // reps can be Int (10) or String ("8-12")
                let repsStr: String
                let defaultRepsValue: Int
                if let repsInt = exJSON["reps"] as? Int {
                    repsStr = "\(repsInt)"
                    defaultRepsValue = max(1, min(repsInt, 100))
                } else if let repsString = exJSON["reps"] as? String {
                    let trimmedReps = repsString.trimmingCharacters(in: .whitespacesAndNewlines)
                    repsStr = trimmedReps.isEmpty ? "10" : trimmedReps
                    let digits = trimmedReps.components(separatedBy: CharacterSet.decimalDigits.inverted).first(where: { !$0.isEmpty })
                    defaultRepsValue = max(1, min(Int(digits ?? "10") ?? 10, 100))
                } else {
                    repsStr = "10"
                    defaultRepsValue = 10
                }

                let exercise = CustomTemplateExercise(
                    name: exName,
                    muscleGroup: muscleGroup,
                    equipment: equipmentType,
                    scheme: "\(sets)x\(repsStr)",
                    restSeconds: rest,
                    defaultSets: sets,
                    defaultReps: defaultRepsValue,
                    order: index
                )
                if template.exercises == nil { template.exercises = [] }
                template.exercises?.append(exercise)
            }
            totalExercises += exercisesJSON.count
        }

        guard importedSessions > 0 else {
            isError = true
            resultMessage = "Aucune séance valide trouvée. Vérifie que chaque séance a bien une liste « exercises » non vide."
            return
        }

        if importedSessions == 1 {
            resultMessage = "\(importedSessions) séance importée avec \(totalExercises)\u{00A0}exercices\u{00A0}!"
        } else {
            resultMessage = "\(importedSessions) séances importées avec \(totalExercises)\u{00A0}exercices au total\u{00A0}!"
        }
        isError = false
    }

    /// Strip ```json ... ``` wrappers that some models add around their response.
    private func stripCodeFences(_ s: String) -> String {
        var result = s
        if result.hasPrefix("```") {
            // Drop the opening fence line
            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            }
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Map common alternative names for equipment ("dumbbell" → halteres, etc.)
    private func equipmentAlias(_ raw: String) -> EquipmentType? {
        switch raw {
        case "barbell", "barre olympique": return .barre
        case "dumbbell", "dumbbells", "haltere": return .halteres
        case "cable", "cables": return .poulie
        case "bodyweight", "poids du corps", "body weight": return .pdc
        default: return nil
        }
    }
}
