import Foundation
import SwiftData

@Model
final class CustomTemplate {
    var name: String = ""
    var subtitle: String = ""
    var order: Int = 0
    var isFavorite: Bool = false
    @Relationship(deleteRule: .cascade) var exercises: [CustomTemplateExercise]? = []

    init(name: String, subtitle: String = "", order: Int = 0) {
        self.name = name
        self.subtitle = subtitle
        self.order = order
        self.exercises = []
    }
    var exercisesArray: [CustomTemplateExercise] { exercises ?? [] }
}

@Model
final class CustomTemplateExercise {
    var name: String = ""
    var muscleGroup: String = "chest"
    var scheme: String = ""
    var restSeconds: Int = 90
    var defaultSets: Int = 3
    var defaultReps: Int = 10
    var order: Int = 0

    init(name: String, muscleGroup: MuscleGroup, scheme: String = "", restSeconds: Int = 90, defaultSets: Int = 3, defaultReps: Int = 10, order: Int = 0) {
        self.name = name
        self.muscleGroup = muscleGroup.rawValue
        self.scheme = scheme
        self.restSeconds = restSeconds
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.order = order
    }

    var group: MuscleGroup { MuscleGroup(rawValue: muscleGroup) ?? .chest }
}
