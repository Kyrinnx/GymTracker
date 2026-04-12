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
    let category: String
    let exercises: [ExerciseTemplate]

    static let all: [WorkoutTemplate] = [

        // MARK: - Upper / Lower

        WorkoutTemplate(id: "upper-a", name: "Upper A", subtitle: "Poussée lourde", category: "Upper / Lower", exercises: [
            .init(name: "Développé couché barre", group: .chest, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Rowing barre", group: .back, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Développé militaire haltères", group: .shoulders, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Tirage vertical prise large", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Élévations latérales", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Curl haltères", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Dips triceps", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "lower-a", name: "Lower A", subtitle: "Quadris", category: "Upper / Lower", exercises: [
            .init(name: "Squat barre", group: .legs, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Presse à cuisses", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Leg curl allongé", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Fentes bulgares", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Mollets debout", group: .legs, scheme: "4×12-15", defaultSets: [(0,15),(0,15),(0,12),(0,12)]),
            .init(name: "Crunch câble", group: .core, scheme: "3×15-20", defaultSets: [(0,20),(0,15),(0,15)]),
        ]),
        WorkoutTemplate(id: "upper-b", name: "Upper B", subtitle: "Tirage lourd", category: "Upper / Lower", exercises: [
            .init(name: "Rowing haltère un bras", group: .back, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Développé couché haltères", group: .chest, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Tirage horizontal câble", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Développé machine épaules", group: .shoulders, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Face pull", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Curl marteau", group: .arms, scheme: "2×10-12", defaultSets: [(0,12),(0,10)]),
            .init(name: "Extensions triceps overhead", group: .arms, scheme: "2×10-12", defaultSets: [(0,12),(0,10)]),
        ]),
        WorkoutTemplate(id: "lower-b", name: "Lower B", subtitle: "Chaîne postérieure", category: "Upper / Lower", exercises: [
            .init(name: "Soulevé de terre roumain", group: .legs, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Squat bulgare", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Leg extension", group: .legs, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Leg curl assis", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Mollets assis", group: .legs, scheme: "4×12-15", defaultSets: [(0,15),(0,15),(0,12),(0,12)]),
            .init(name: "Planche", group: .core, scheme: "3×30-45s", defaultSets: [(0,45),(0,30),(0,30)]),
        ]),

        // MARK: - Push Pull Legs

        WorkoutTemplate(id: "ppl-push", name: "Push", subtitle: "Pecs, épaules, triceps", category: "Push Pull Legs", exercises: [
            .init(name: "Développé couché barre", group: .chest, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Développé incliné haltères", group: .chest, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Développé militaire barre", group: .shoulders, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Élévations latérales", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Triceps pushdown poulie", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Extensions triceps overhead", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "ppl-pull", name: "Pull", subtitle: "Dos, biceps", category: "Push Pull Legs", exercises: [
            .init(name: "Soulevé de terre", group: .back, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Rowing barre", group: .back, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Tirage vertical poulie", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Face pull", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Curl barre", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Curl marteau", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "ppl-legs", name: "Legs", subtitle: "Quadris, ischios, mollets", category: "Push Pull Legs", exercises: [
            .init(name: "Squat barre", group: .legs, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Presse à cuisses", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Soulevé de terre roumain", group: .legs, scheme: "4×8-10", defaultSets: [(0,10),(0,10),(0,8),(0,8)]),
            .init(name: "Leg extension", group: .legs, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Leg curl allongé", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Mollets debout", group: .legs, scheme: "4×12-15", defaultSets: [(0,15),(0,15),(0,12),(0,12)]),
        ]),

        // MARK: - Full Body

        WorkoutTemplate(id: "fb-a", name: "Full Body A", subtitle: "Composés + biceps", category: "Full Body", exercises: [
            .init(name: "Squat barre", group: .legs, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Développé couché barre", group: .chest, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Rowing barre", group: .back, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Développé militaire barre", group: .shoulders, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Curl barre", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Planche", group: .core, scheme: "3×30-45s", defaultSets: [(0,45),(0,30),(0,30)]),
        ]),
        WorkoutTemplate(id: "fb-b", name: "Full Body B", subtitle: "Composés + triceps", category: "Full Body", exercises: [
            .init(name: "Soulevé de terre", group: .back, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Développé incliné haltères", group: .chest, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Tirage vertical poulie", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Élévations latérales", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Dips triceps", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Crunch", group: .core, scheme: "3×15-20", defaultSets: [(0,20),(0,15),(0,15)]),
        ]),

        // MARK: - Bro Split

        WorkoutTemplate(id: "bro-chest", name: "Pecs", subtitle: "Poitrine", category: "Bro Split", exercises: [
            .init(name: "Développé couché barre", group: .chest, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Développé incliné haltères", group: .chest, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Câble fly (écarté poulie)", group: .chest, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Dips pecs", group: .chest, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "bro-back", name: "Dos", subtitle: "Largeur + épaisseur", category: "Bro Split", exercises: [
            .init(name: "Soulevé de terre", group: .back, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Rowing barre", group: .back, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Tirage vertical poulie", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Tirage horizontal câble", group: .back, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "bro-shoulders", name: "Epaules", subtitle: "Deltos avant, lat, post", category: "Bro Split", exercises: [
            .init(name: "Développé militaire barre", group: .shoulders, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Élévations latérales", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Face pull", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
            .init(name: "Oiseau (rear delt fly)", group: .shoulders, scheme: "3×12-15", defaultSets: [(0,15),(0,12),(0,12)]),
        ]),
        WorkoutTemplate(id: "bro-arms", name: "Bras", subtitle: "Biceps + triceps", category: "Bro Split", exercises: [
            .init(name: "Curl barre", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Curl marteau", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Triceps pushdown poulie", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Extensions triceps overhead", group: .arms, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
        ]),
        WorkoutTemplate(id: "bro-legs", name: "Jambes", subtitle: "Quadris, ischios, mollets", category: "Bro Split", exercises: [
            .init(name: "Squat barre", group: .legs, scheme: "4×6-8", defaultSets: [(0,8),(0,8),(0,6),(0,6)]),
            .init(name: "Presse à cuisses", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Leg curl allongé", group: .legs, scheme: "3×10-12", defaultSets: [(0,12),(0,10),(0,10)]),
            .init(name: "Mollets debout", group: .legs, scheme: "4×12-15", defaultSets: [(0,15),(0,15),(0,12),(0,12)]),
        ]),
    ]

    /// Ordered list of unique categories, preserving declaration order.
    static var categories: [String] {
        var seen = Set<String>()
        return all.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }

    /// Templates grouped by category, preserving declaration order.
    static var grouped: [(category: String, templates: [WorkoutTemplate])] {
        categories.map { cat in (cat, all.filter { $0.category == cat }) }
    }
}
