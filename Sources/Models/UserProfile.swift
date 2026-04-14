import Foundation

// MARK: - Activity Level

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "sedentary"
    case light = "light"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "veryActive"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sedentary: "Sédentaire"
        case .light: "Légèrement actif"
        case .moderate: "Modérément actif"
        case .active: "Actif"
        case .veryActive: "Très actif"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: "Peu ou pas d'exercice"
        case .light: "1-2 séances / semaine"
        case .moderate: "3-4 séances / semaine"
        case .active: "5-6 séances / semaine"
        case .veryActive: "Sport intensif quotidien"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: "figure.stand"
        case .light: "figure.walk"
        case .moderate: "figure.run"
        case .active: "figure.strengthtraining.traditional"
        case .veryActive: "flame.fill"
        }
    }

    /// TDEE multiplier (Harris-Benedict)
    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .active: 1.725
        case .veryActive: 1.9
        }
    }
}

// MARK: - Fitness Goal

enum FitnessGoal: String, CaseIterable, Identifiable {
    case cut = "cut"
    case bulk = "bulk"
    case maintain = "maintain"
    case strength = "strength"
    case recomp = "recomp"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cut: "Sèche"
        case .bulk: "Prise de masse"
        case .maintain: "Maintien"
        case .strength: "Force"
        case .recomp: "Recomposition"
        }
    }

    var icon: String {
        switch self {
        case .cut: "flame.fill"
        case .bulk: "arrow.up.right"
        case .maintain: "equal"
        case .strength: "bolt.fill"
        case .recomp: "arrow.triangle.2.circlepath"
        }
    }

    var subtitle: String {
        switch self {
        case .cut: "Perdre du gras en gardant le muscle"
        case .bulk: "Prendre du poids et du muscle"
        case .maintain: "Garder ton physique actuel"
        case .strength: "Progresser en force pure"
        case .recomp: "Perdre du gras et gagner du muscle"
        }
    }

    /// Weekly weight change rate in kg
    var weeklyRate: Double {
        switch self {
        case .cut: -0.5
        case .bulk: 0.25
        case .maintain: 0
        case .strength: 0.1
        case .recomp: -0.15
        }
    }

    var hasWeightTarget: Bool {
        switch self {
        case .cut, .bulk: true
        default: false
        }
    }

    /// Estimated weeks to reach target weight from current
    func estimatedWeeks(from current: Double, to target: Double) -> Int? {
        guard weeklyRate != 0 else { return nil }
        let diff = target - current
        // Must align with direction
        if weeklyRate > 0 && diff <= 0 { return nil }
        if weeklyRate < 0 && diff >= 0 { return nil }
        return max(1, Int(ceil(abs(diff / weeklyRate))))
    }
}
