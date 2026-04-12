import Foundation
import SwiftData

/// Pure-data DTOs for portable JSON export/import.
/// Versioning lets us evolve the schema later without breaking existing files.
struct ExportPayload: Codable {
    var version: Int = 1
    var exportedAt: Date = Date()
    var sessions: [SessionDTO] = []
    var weights: [WeightDTO] = []
    var meals: [MealDTO] = []
    var waters: [WaterDTO] = []
    var customTemplates: [CustomTemplateDTO] = []
    var exerciseInfos: [ExerciseInfoDTO] = []
    var favoriteFoods: [FavoriteFoodDTO] = []
    var fastingSessions: [FastingDTO] = []
}

struct SessionDTO: Codable {
    var started: Date
    var finished: Date?
    var templateId: String?
    var templateName: String
    var caloriesBurned: Int
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
}

struct MealDTO: Codable {
    var name: String
    var mealType: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var date: Date
}

struct WaterDTO: Codable {
    var date: Date
    var glasses: Int
    var milliliters: Int?
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

struct FavoriteFoodDTO: Codable {
    var name: String
    var emoji: String
    var portion: String
    var kcal: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var addedAt: Date
}

struct FastingDTO: Codable {
    var startDate: Date
    var plannedEndDate: Date
    var actualEndDate: Date?
    var methodRaw: String
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
        payload.weights = weights.map { WeightDTO(date: $0.date, kg: $0.kg, bodyFat: $0.bodyFat) }

        let meals = (try? context.fetch(FetchDescriptor<MealEntry>())) ?? []
        payload.meals = meals.map {
            MealDTO(
                name: $0.name, mealType: $0.mealType, calories: $0.calories,
                protein: $0.protein, carbs: $0.carbs, fat: $0.fat,
                fiber: $0.fiber, sugar: $0.sugar, date: $0.date
            )
        }

        let waters = (try? context.fetch(FetchDescriptor<WaterEntry>())) ?? []
        payload.waters = waters.map { WaterDTO(date: $0.date, glasses: $0.glasses, milliliters: $0.milliliters) }

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

        let favs = (try? context.fetch(FetchDescriptor<FavoriteFood>())) ?? []
        payload.favoriteFoods = favs.map {
            FavoriteFoodDTO(
                name: $0.name, emoji: $0.emoji, portion: $0.portion,
                kcal: $0.kcal, protein: $0.protein, carbs: $0.carbs, fat: $0.fat,
                fiber: $0.fiber, sugar: $0.sugar, addedAt: $0.addedAt
            )
        }

        let fasts = (try? context.fetch(FetchDescriptor<FastingSession>())) ?? []
        payload.fastingSessions = fasts.map {
            FastingDTO(
                startDate: $0.startDate, plannedEndDate: $0.plannedEndDate,
                actualEndDate: $0.actualEndDate, methodRaw: $0.methodRaw
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
            context.insert(WeightEntry(date: w.date, kg: w.kg, bodyFat: w.bodyFat))
        }

        for m in payload.meals {
            let type = MealType(rawValue: m.mealType) ?? .lunch
            context.insert(MealEntry(
                name: m.name, type: type, calories: m.calories,
                protein: m.protein, carbs: m.carbs, fat: m.fat,
                fiber: m.fiber, sugar: m.sugar, date: m.date
            ))
        }

        for w in payload.waters {
            let entry = WaterEntry(date: w.date, glasses: w.glasses, milliliters: w.milliliters ?? 0)
            context.insert(entry)
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

        for fav in payload.favoriteFoods {
            // Build a synthetic FoodItem to reuse the FavoriteFood initializer
            let synthetic = FoodItem(
                name: fav.name, emoji: fav.emoji, portion: fav.portion,
                grams: 0, kcal: fav.kcal, protein: fav.protein, carbs: fav.carbs,
                fat: fav.fat, fiber: fav.fiber, sugar: fav.sugar, category: .snacks
            )
            let entry = FavoriteFood(item: synthetic)
            entry.addedAt = fav.addedAt
            context.insert(entry)
        }

        for f in payload.fastingSessions {
            let method = FastingMethod(rawValue: f.methodRaw) ?? .sixteen8
            let entry = FastingSession(method: method, startDate: f.startDate)
            entry.plannedEndDate = f.plannedEndDate
            entry.actualEndDate = f.actualEndDate
            context.insert(entry)
        }

        try context.save()
    }

    /// Deletes every persisted entity from the local store.
    static func wipeAll(context: ModelContext) throws {
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: ExerciseEntry.self)
        try context.delete(model: WorkoutSet.self)
        try context.delete(model: WeightEntry.self)
        try context.delete(model: MealEntry.self)
        try context.delete(model: WaterEntry.self)
        try context.delete(model: CustomTemplate.self)
        try context.delete(model: CustomTemplateExercise.self)
        try context.delete(model: ExerciseInfo.self)
        try context.delete(model: FavoriteFood.self)
        try context.delete(model: FastingSession.self)
        try context.save()
    }
}
