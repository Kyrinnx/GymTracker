import Foundation
import SwiftData

// MARK: - Exercise Info (SwiftData for favorites/notes)
@Model
final class ExerciseInfo {
    var name: String = ""
    var muscleGroup: String = "chest"
    var isFavorite: Bool = false
    var personalRecord: Double = 0  // best kg ever
    var notes: String = ""

    init(name: String, muscleGroup: MuscleGroup, isFavorite: Bool = false, personalRecord: Double = 0, notes: String = "") {
        self.name = name
        self.muscleGroup = muscleGroup.rawValue
        self.isFavorite = isFavorite
        self.personalRecord = personalRecord
        self.notes = notes
    }
    var group: MuscleGroup { MuscleGroup(rawValue: muscleGroup) ?? .chest }
}

// MARK: - Exercise Definition (base name + compatible equipment)
struct ExerciseDefinition {
    let name: String
    let equipment: [EquipmentType]
}

// MARK: - Static Exercise Library
struct ExerciseLibrary {

    static let catalog: [MuscleGroup: [ExerciseDefinition]] = [
        .chest: [
            ExerciseDefinition(name: "Développé couché", equipment: [.barre, .halteres, .machine]),
            ExerciseDefinition(name: "Développé incliné", equipment: [.barre, .halteres, .machine]),
            ExerciseDefinition(name: "Développé décliné", equipment: [.barre, .halteres]),
            ExerciseDefinition(name: "Écarté", equipment: [.halteres, .poulie, .machine]),
            ExerciseDefinition(name: "Pullover", equipment: [.halteres, .poulie]),
            ExerciseDefinition(name: "Butterfly", equipment: [.machine]),
            ExerciseDefinition(name: "Dips pecs", equipment: [.pdc]),
            ExerciseDefinition(name: "Pompes", equipment: [.pdc]),
        ],
        .back: [
            ExerciseDefinition(name: "Rowing", equipment: [.barre, .halteres, .machine]),
            ExerciseDefinition(name: "Rowing T-barre", equipment: [.barre]),
            ExerciseDefinition(name: "Tirage vertical", equipment: [.poulie, .machine]),
            ExerciseDefinition(name: "Tirage horizontal", equipment: [.poulie, .machine]),
            ExerciseDefinition(name: "Pullover dos", equipment: [.poulie]),
            ExerciseDefinition(name: "Soulevé de terre", equipment: [.barre]),
            ExerciseDefinition(name: "Tractions", equipment: [.pdc]),
            ExerciseDefinition(name: "Chin-ups", equipment: [.pdc]),
        ],
        .shoulders: [
            ExerciseDefinition(name: "Développé militaire", equipment: [.barre, .halteres, .machine]),
            ExerciseDefinition(name: "Élévation latérale", equipment: [.halteres, .poulie, .machine]),
            ExerciseDefinition(name: "Élévation frontale", equipment: [.halteres, .poulie]),
            ExerciseDefinition(name: "Face pull", equipment: [.poulie]),
            ExerciseDefinition(name: "Oiseau", equipment: [.halteres, .poulie, .machine]),
            ExerciseDefinition(name: "Shrug", equipment: [.barre, .halteres, .machine]),
            ExerciseDefinition(name: "Arnold press", equipment: [.halteres]),
        ],
        .arms: [
            ExerciseDefinition(name: "Curl biceps", equipment: [.barre, .halteres, .poulie, .machine]),
            ExerciseDefinition(name: "Curl marteau", equipment: [.halteres]),
            ExerciseDefinition(name: "Curl concentré", equipment: [.halteres]),
            ExerciseDefinition(name: "Curl incliné", equipment: [.halteres]),
            ExerciseDefinition(name: "Extension triceps", equipment: [.poulie, .halteres]),
            ExerciseDefinition(name: "Triceps overhead", equipment: [.halteres, .poulie]),
            ExerciseDefinition(name: "Barre au front", equipment: [.barre]),
            ExerciseDefinition(name: "Kick-back", equipment: [.halteres]),
            ExerciseDefinition(name: "Dips triceps", equipment: [.pdc]),
        ],
        .legs: [
            ExerciseDefinition(name: "Squat", equipment: [.barre, .machine, .halteres]),
            ExerciseDefinition(name: "Presse à cuisses", equipment: [.machine]),
            ExerciseDefinition(name: "Leg extension", equipment: [.machine]),
            ExerciseDefinition(name: "Leg curl", equipment: [.machine]),
            ExerciseDefinition(name: "Fentes", equipment: [.barre, .halteres, .pdc]),
            ExerciseDefinition(name: "Fentes bulgares", equipment: [.halteres, .barre, .pdc]),
            ExerciseDefinition(name: "Soulevé de terre roumain", equipment: [.barre, .halteres]),
            ExerciseDefinition(name: "Hip thrust", equipment: [.barre, .machine]),
            ExerciseDefinition(name: "Hack squat", equipment: [.machine]),
            ExerciseDefinition(name: "Mollets debout", equipment: [.machine, .barre]),
            ExerciseDefinition(name: "Mollets assis", equipment: [.machine]),
            ExerciseDefinition(name: "Adducteurs", equipment: [.machine]),
            ExerciseDefinition(name: "Abducteurs", equipment: [.machine]),
        ],
        .core: [
            ExerciseDefinition(name: "Crunch", equipment: [.machine, .poulie, .pdc]),
            ExerciseDefinition(name: "Planche", equipment: [.pdc]),
            ExerciseDefinition(name: "Relevé de jambes", equipment: [.pdc]),
            ExerciseDefinition(name: "Ab wheel", equipment: [.pdc]),
            ExerciseDefinition(name: "Gainage latéral", equipment: [.pdc]),
            ExerciseDefinition(name: "Russian twist", equipment: [.halteres, .pdc]),
            ExerciseDefinition(name: "Pallof press", equipment: [.poulie]),
        ],
    ]

    /// Flat list of all exercise definitions
    static var allDefinitions: [(def: ExerciseDefinition, group: MuscleGroup)] {
        catalog.flatMap { group, defs in
            defs.map { (def: $0, group: group) }
        }
    }

    /// Find compatible equipment for an exercise name
    static func equipmentFor(name: String, group: MuscleGroup) -> [EquipmentType] {
        catalog[group]?.first { $0.name == name }?.equipment ?? EquipmentType.allCases
    }

    // MARK: - Legacy compatibility
    /// Old-style flat dict for seeding ExerciseInfo and backward compat
    static let exercises: [MuscleGroup: [String]] = {
        var result: [MuscleGroup: [String]] = [:]
        for (group, defs) in catalog {
            result[group] = defs.map(\.name)
        }
        return result
    }()

    static var allExercises: [(name: String, group: MuscleGroup)] {
        exercises.flatMap { group, names in
            names.map { (name: $0, group: group) }
        }
    }
}
