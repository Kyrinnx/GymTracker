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

// MARK: - Static Exercise Library
struct ExerciseLibrary {
    static let exercises: [MuscleGroup: [String]] = [
        .chest: ["Développé couché barre", "Développé incliné haltères", "Développé couché haltères", "Développé incliné barre", "Développé machine guidée", "Écarté poulie", "Écarté machine", "Écarté haltères incliné", "Dips pecs", "Pompes", "Pullover haltère"],
        .back: ["Rowing barre", "Rowing haltère un bras", "Tirage vertical prise large", "Tirage vertical prise serrée", "Tirage horizontal câble", "Pullover poulie", "Rowing machine", "Rowing T-barre", "Soulevé de terre", "Pull-ups", "Chin-ups"],
        .shoulders: ["Développé militaire haltères", "Développé militaire barre", "Développé machine épaules", "Élévations latérales", "Élévations latérales câble", "Face pull", "Oiseau", "Oiseau machine", "Shrug barre", "Shrug haltères", "Arnold press"],
        .arms: ["Curl haltères", "Curl barre EZ", "Curl barre droite", "Curl marteau", "Curl poulie", "Curl concentré", "Curl incliné", "Dips triceps", "Triceps poulie corde", "Triceps poulie barre", "Extensions triceps overhead", "Barre au front", "Kick-back triceps"],
        .legs: ["Squat barre", "Squat goblet", "Presse à cuisses", "Leg extension", "Leg curl allongé", "Leg curl assis", "Fentes bulgares", "Fentes marchées", "Squat bulgare", "Mollets debout", "Mollets assis", "Soulevé de terre roumain", "Hip thrust", "Hack squat", "Adducteurs machine", "Abducteurs machine"],
        .core: ["Crunch câble", "Crunch machine", "Planche", "Planche latérale", "Relevé de jambes", "Relevé de jambes suspendu", "Ab wheel", "Gainage latéral", "Russian twist", "Pallof press"],
    ]

    static var allExercises: [(name: String, group: MuscleGroup)] {
        exercises.flatMap { group, names in
            names.map { (name: $0, group: group) }
        }
    }
}
