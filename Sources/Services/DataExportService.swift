import Foundation
import SwiftData

/// Pure-data DTOs for portable JSON export/import.
/// Versioning lets us evolve the schema later without breaking existing files.
struct ExportPayload: Codable {
    var version: Int = 1
    var exportedAt: Date = Date()
    var sessions: [SessionDTO] = []
    var weights: [WeightDTO] = []
    var customTemplates: [CustomTemplateDTO] = []
    var exerciseInfos: [ExerciseInfoDTO] = []
}

struct SessionDTO: Codable {
    var started: Date
    var finished: Date?
    var templateId: String?
    var templateName: String
    var caloriesBurned: Int
    var xpAwarded: Int?
    var exercises: [ExerciseDTO]
}

struct ExerciseDTO: Codable {
    var name: String
    var muscleGroup: String
    var scheme: String
    var restSeconds: Int
    var order: Int
    var sets: [SetDTO]
}

struct SetDTO: Codable {
    var kg: Double
    var reps: Int
    var done: Bool
    var order: Int
}

struct WeightDTO: Codable {
    var date: Date
    var kg: Double
    var bodyFat: Double?
    var muscleMass: Double?
}

struct CustomTemplateDTO: Codable {
    var name: String
    var subtitle: String
    var order: Int
    var exercises: [CustomTemplateExerciseDTO]
}

struct CustomTemplateExerciseDTO: Codable {
    var name: String
    var muscleGroup: String
    var scheme: String
    var restSeconds: Int
    var defaultSets: Int
    var defaultReps: Int
    var order: Int
}

struct ExerciseInfoDTO: Codable {
    var name: String
    var muscleGroup: String
    var isFavorite: Bool
    var personalRecord: Double
    var notes: String
}

// MARK: - Service

enum DataExportService {

    /// Builds a JSON file in the temp directory containing every record from the SwiftData store.
    /// Returns the URL to share via UIActivityViewController / ShareLink.
    static func exportAll(context: ModelContext) throws -> URL {
        var payload = ExportPayload()

        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        payload.sessions = sessions.map { s in
            SessionDTO(
                started: s.started,
                finished: s.finished,
                templateId: s.templateId,
                templateName: s.templateName,
                caloriesBurned: s.caloriesBurned,
                xpAwarded: s.xpAwarded,
                exercises: s.exercisesArray.sorted { $0.order < $1.order }.map { ex in
                    ExerciseDTO(
                        name: ex.name,
                        muscleGroup: ex.muscleGroup,
                        scheme: ex.scheme,
                        restSeconds: ex.restSeconds,
                        order: ex.order,
                        sets: ex.setsArray.sorted { $0.order < $1.order }.map { st in
                            SetDTO(kg: st.kg, reps: st.reps, done: st.done, order: st.order)
                        }
                    )
                }
            )
        }

        let weights = (try? context.fetch(FetchDescriptor<WeightEntry>())) ?? []
        payload.weights = weights.map { WeightDTO(date: $0.date, kg: $0.kg, bodyFat: $0.bodyFat, muscleMass: $0.muscleMass) }

        let templates = (try? context.fetch(FetchDescriptor<CustomTemplate>())) ?? []
        payload.customTemplates = templates.map { tpl in
            CustomTemplateDTO(
                name: tpl.name, subtitle: tpl.subtitle, order: tpl.order,
                exercises: tpl.exercisesArray.map { ex in
                    CustomTemplateExerciseDTO(
                        name: ex.name, muscleGroup: ex.muscleGroup, scheme: ex.scheme,
                        restSeconds: ex.restSeconds, defaultSets: ex.defaultSets,
                        defaultReps: ex.defaultReps, order: ex.order
                    )
                }
            )
        }

        let infos = (try? context.fetch(FetchDescriptor<ExerciseInfo>())) ?? []
        payload.exerciseInfos = infos.map {
            ExerciseInfoDTO(
                name: $0.name, muscleGroup: $0.muscleGroup,
                isFavorite: $0.isFavorite, personalRecord: $0.personalRecord, notes: $0.notes
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filename = "GymTracker-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    /// Imports a previously exported JSON. By default it MERGES (appends to existing data).
    /// Pass `replaceAll = true` to wipe local data first.
    static func importAll(from url: URL, into context: ModelContext, replaceAll: Bool = false) throws {
        // Handle security-scoped URLs from the Files picker
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        if replaceAll {
            try wipeAll(context: context)
        }

        for s in payload.sessions {
            let session = WorkoutSession(templateId: s.templateId, templateName: s.templateName)
            session.started = s.started
            session.finished = s.finished
            session.caloriesBurned = s.caloriesBurned
            session.xpAwarded = s.xpAwarded ?? 0
            context.insert(session)
            for ex in s.exercises {
                let group = MuscleGroup(rawValue: ex.muscleGroup) ?? .chest
                let entry = ExerciseEntry(name: ex.name, muscleGroup: group, scheme: ex.scheme, restSeconds: ex.restSeconds, order: ex.order)
                if entry.sets == nil { entry.sets = [] }
                for st in ex.sets {
                    entry.sets?.append(WorkoutSet(kg: st.kg, reps: st.reps, done: st.done, order: st.order))
                }
                if session.exercises == nil { session.exercises = [] }
                session.exercises?.append(entry)
            }
        }

        for w in payload.weights {
            context.insert(WeightEntry(date: w.date, kg: w.kg, bodyFat: w.bodyFat, muscleMass: w.muscleMass))
        }

        for tpl in payload.customTemplates {
            let template = CustomTemplate(name: tpl.name, subtitle: tpl.subtitle, order: tpl.order)
            context.insert(template)
            if template.exercises == nil { template.exercises = [] }
            for ex in tpl.exercises {
                let group = MuscleGroup(rawValue: ex.muscleGroup) ?? .chest
                template.exercises?.append(CustomTemplateExercise(
                    name: ex.name, muscleGroup: group, scheme: ex.scheme,
                    restSeconds: ex.restSeconds, defaultSets: ex.defaultSets,
                    defaultReps: ex.defaultReps, order: ex.order
                ))
            }
        }

        for info in payload.exerciseInfos {
            let group = MuscleGroup(rawValue: info.muscleGroup) ?? .chest
            context.insert(ExerciseInfo(
                name: info.name, muscleGroup: group,
                isFavorite: info.isFavorite, personalRecord: info.personalRecord, notes: info.notes
            ))
        }

        try context.save()
    }

    /// Deletes every persisted entity from the local store.
    static func wipeAll(context: ModelContext) throws {
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: ExerciseEntry.self)
        try context.delete(model: WorkoutSet.self)
        try context.delete(model: WeightEntry.self)
        try context.delete(model: CustomTemplate.self)
        try context.delete(model: CustomTemplateExercise.self)
        try context.delete(model: ExerciseInfo.self)
        try context.save()
    }
}
