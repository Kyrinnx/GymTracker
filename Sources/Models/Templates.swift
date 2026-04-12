import Foundation

struct ExerciseTemplate {
    let name: String
    let group: MuscleGroup
    let scheme: String
    let defaultSets: [(kg: Double, reps: Int)]
}

struct WorkoutTemplate: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let exercises: [ExerciseTemplate]

    static let all: [WorkoutTemplate] = [
        WorkoutTemplate(id: "upper-a", name: "Upper A", subtitle: "Poussée lourde", exercises: [
            .init(name: "Développé couché barre", group: .chest, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Rowing barre", group: .back, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Développé militaire haltères", group: .shoulders, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Tirage vertical prise large", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Élévations latérales", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Curl haltères", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Dips triceps", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "lower-a", name: "Lower A", subtitle: "Quadris", exercises: [
            .init(name: "Squat barre", group: .legs, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Presse à cuisses", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Leg curl allongé", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Fentes bulgares", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Mollets debout", group: .legs, scheme: "4×12-15", defaultSets: [(0,15),(0,15),(0,12),(0,12)]),
            .init(name: "Crunch câble", group: .core, scheme: "3×15-20", defaultSets: [(0,20),(0,15),(0,15)]),
        ]),
        WorkoutTemplate(id: "upper-b", name: "Upper B", subtitle: "Tirage lourd", exercises: [
            .init(name: "Rowing haltère un bras", group: .back, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Développé couché haltères", group: .chest, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Tirage horizontal câble", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Développé machine épaules", group: .shoulders, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Face pull", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Curl marteau", group: .arms, scheme: "2×10-12", defaultSets: [(0,12),(0,10)]),
            .init(name: "Extensions triceps overhead", group: .arms, scheme: "2×10-12", defaultSets: [(0,12),(0,10)]),
        ]),
        WorkoutTemplate(id: "lower-b", name: "Lower B", subtitle: "Chaîne postérieure", exercises: [
            .init(name: "Soulevé de terre roumain", group: .legs, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Squat bulgare", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Leg extension", group: .legs, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Leg curl assis", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Mollets assis", group: .legs, scheme: "4×12-15", defaultSets: [(0,15),(0,15),(0,12),(0,12)]),
            .init(name: "Planche", group: .core, scheme: "3×30-45s", defaultSets: [(0,45),(0,30),(0,30)]),
        ]),
    ]
}
