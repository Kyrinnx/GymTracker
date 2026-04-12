import Foundation
import SwiftData

// MARK: - Meal Type
enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var label: String {
        switch self {
        case .breakfast: "Petit-déj"
        case .lunch: "Déjeuner"
        case .dinner: "Dîner"
        case .snack: "Snack"
        }
    }
    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.fill"
        case .snack: "cup.and.saucer.fill"
        }
    }
}

// MARK: - Meal Entry
@Model
final class MealEntry {
    var name: String = ""
    var mealType: String = "lunch"
    var calories: Int = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var date: Date = Date()

    init(name: String = "", type: MealType = .lunch, calories: Int = 0,
         protein: Double = 0, carbs: Double = 0, fat: Double = 0,
         fiber: Double = 0, sugar: Double = 0, date: Date = Date()) {
        self.name = name
        self.mealType = type.rawValue
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.date = date
    }
    var type: MealType { MealType(rawValue: mealType) ?? .lunch }
}

// MARK: - Water Entry
@Model
final class WaterEntry {
    var date: Date = Date()
    var glasses: Int = 0
    var milliliters: Int = 0

    init(date: Date = Date(), glasses: Int = 0, milliliters: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.glasses = glasses
        self.milliliters = milliliters
    }

    /// Total ml: manual entry + glasses (250ml each)
    var totalMl: Int { milliliters + (glasses * 250) }
}

