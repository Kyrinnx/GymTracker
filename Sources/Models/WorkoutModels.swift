import Foundation
import SwiftData

// MARK: - Muscle Group
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, arms, legs, core
    var id: String { rawValue }
    var label: String {
        switch self {
        case .chest: "Pecs"
        case .back: "Dos"
        case .shoulders: "Épaules"
        case .arms: "Bras"
        case .legs: "Jambes"
        case .core: "Abdos"
        }
    }
    var icon: String {
        switch self {
        case .chest: "figure.strengthtraining.traditional"
        case .back: "figure.rowing"
        case .shoulders: "figure.boxing"
        case .arms: "figure.curling"
        case .legs: "figure.run"
        case .core: "figure.core.training"
        }
    }
}

// MARK: - Workout Set
@Model
final class WorkoutSet {
    var kg: Double = 0
    var reps: Int = 0
    var done: Bool = false
    var order: Int = 0

    init(kg: Double = 0, reps: Int = 0, done: Bool = false, order: Int = 0) {
        self.kg = kg
        self.reps = reps
        self.done = done
        self.order = order
    }
    var volume: Double { kg * Double(reps) }

    /// Estimated 1-rep max using the Epley formula: 1RM = kg * (1 + reps/30)
    var estimatedOneRM: Double {
        guard kg > 0, reps > 0 else { return 0 }
        if reps == 1 { return kg }
        return kg * (1 + Double(reps) / 30.0)
    }
}

// MARK: - Exercise Entry
@Model
final class ExerciseEntry {
    var name: String = ""
    var muscleGroup: String = "chest"
    var scheme: String = ""
    var restSeconds: Int = 90
    var order: Int = 0
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]? = []

    init(name: String, muscleGroup: MuscleGroup, scheme: String = "", restSeconds: Int = 90, order: Int = 0) {
        self.name = name
        self.muscleGroup = muscleGroup.rawValue
        self.scheme = scheme
        self.restSeconds = restSeconds
        self.order = order
        self.sets = []
    }
    var group: MuscleGroup { MuscleGroup(rawValue: muscleGroup) ?? .chest }
    var setsArray: [WorkoutSet] { sets ?? [] }
    var doneSets: [WorkoutSet] { setsArray.filter { $0.done } }
    var totalVolume: Double { doneSets.reduce(0) { $0 + $1.volume } }
}

// MARK: - Workout Session
@Model
final class WorkoutSession {
    var started: Date = Date()
    var finished: Date?
    var templateId: String?
    var templateName: String = "Séance libre"
    var caloriesBurned: Int = 0
    var xpAwarded: Int = 0
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseEntry]? = []

    init(templateId: String? = nil, templateName: String = "Séance libre") {
        self.started = Date()
        self.templateId = templateId
        self.templateName = templateName
        self.caloriesBurned = 0
        self.xpAwarded = 0
        self.exercises = []
    }
    var exercisesArray: [ExerciseEntry] { exercises ?? [] }
    var totalSets: Int { exercisesArray.reduce(0) { $0 + $1.doneSets.count } }
    var totalVolume: Double { exercisesArray.reduce(0) { $0 + $1.totalVolume } }
    var duration: TimeInterval? {
        guard let f = finished else { return nil }
        return f.timeIntervalSince(started)
    }
    var durationMinutes: Int { Int((duration ?? 0) / 60) }
    var activeGroups: [MuscleGroup] {
        Array(Set(exercisesArray.compactMap { MuscleGroup(rawValue: $0.muscleGroup) }))
    }
}

// MARK: - Weight Entry
@Model
final class WeightEntry {
    var date: Date = Date()
    var kg: Double = 0
    var bodyFat: Double?
    var muscleMass: Double?

    init(date: Date = Date(), kg: Double, bodyFat: Double? = nil, muscleMass: Double? = nil) {
        self.date = date
        self.kg = kg
        self.bodyFat = bodyFat
        self.muscleMass = muscleMass
    }

    /// Lean mass: from manual muscle mass, or calculated from BF%
    var leanMass: Double? {
        if let mm = muscleMass { return mm }
        guard let bf = bodyFat else { return nil }
        return kg * (1 - bf / 100)
    }

    /// BMR (Katch-McArdle if lean mass available)
    var bmr: Double? {
        guard let lm = leanMass else { return nil }
        return 370 + 21.6 * lm
    }
}
