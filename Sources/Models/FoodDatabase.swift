import Foundation
import SwiftData

// MARK: - Food Category
enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case proteins, carbs, vegetables, fruits, dairy, fats, drinks, snacks
    var id: String { rawValue }
    var label: String {
        switch self {
        case .proteins: "Protéines"
        case .carbs: "Féculents"
        case .vegetables: "Légumes"
        case .fruits: "Fruits"
        case .dairy: "Produits laitiers"
        case .fats: "Lipides"
        case .drinks: "Boissons"
        case .snacks: "Snacks"
        }
    }
    var icon: String {
        switch self {
        case .proteins: "fork.knife"
        case .carbs: "takeoutbag.and.cup.and.straw.fill"
        case .vegetables: "leaf.fill"
        case .fruits: "apple.logo"
        case .dairy: "drop.fill"
        case .fats: "circle.circle.fill"
        case .drinks: "cup.and.saucer.fill"
        case .snacks: "birthday.cake.fill"
        }
    }
}

// MARK: - Food Item (static catalog entry)
struct FoodItem: Identifiable, Hashable {
    var id: String { name + portion }
    let name: String
    let emoji: String
    let portion: String
    let grams: Double
    let kcal: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let category: FoodCategory
}

// MARK: - Static Catalog
enum FoodCatalog {
    static let all: [FoodItem] = [
        // Proteins
        .init(name: "Poulet rôti", emoji: "🍗", portion: "150 g", grams: 150, kcal: 250, protein: 46, carbs: 0, fat: 5, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Œuf dur", emoji: "🥚", portion: "1 œuf", grams: 60, kcal: 80, protein: 7, carbs: 1, fat: 6, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Saumon grillé", emoji: "🐟", portion: "150 g", grams: 150, kcal: 310, protein: 34, carbs: 0, fat: 18, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Thon en boîte", emoji: "🐟", portion: "100 g", grams: 100, kcal: 116, protein: 26, carbs: 0, fat: 1, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Steak haché 5%", emoji: "🥩", portion: "100 g", grams: 100, kcal: 130, protein: 21, carbs: 0, fat: 5, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Steak haché 15%", emoji: "🥩", portion: "100 g", grams: 100, kcal: 220, protein: 19, carbs: 0, fat: 15, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Dinde", emoji: "🦃", portion: "100 g", grams: 100, kcal: 135, protein: 30, carbs: 0, fat: 1, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Jambon blanc", emoji: "🥓", portion: "1 tranche", grams: 40, kcal: 45, protein: 8, carbs: 0, fat: 1, fiber: 0, sugar: 0, category: .proteins),
        .init(name: "Tofu", emoji: "🥡", portion: "100 g", grams: 100, kcal: 145, protein: 15, carbs: 4, fat: 9, fiber: 2, sugar: 0, category: .proteins),
        .init(name: "Lentilles cuites", emoji: "🫘", portion: "150 g", grams: 150, kcal: 175, protein: 13, carbs: 30, fat: 0, fiber: 12, sugar: 1, category: .proteins),
        .init(name: "Pois chiches cuits", emoji: "🫘", portion: "150 g", grams: 150, kcal: 245, protein: 13, carbs: 41, fat: 4, fiber: 12, sugar: 7, category: .proteins),
        .init(name: "Whey 30 g", emoji: "🥤", portion: "30 g", grams: 30, kcal: 120, protein: 24, carbs: 3, fat: 1, fiber: 0, sugar: 2, category: .proteins),

        // Carbs / Féculents
        .init(name: "Riz blanc cuit", emoji: "🍚", portion: "150 g", grams: 150, kcal: 195, protein: 4, carbs: 43, fat: 0, fiber: 1, sugar: 0, category: .carbs),
        .init(name: "Riz complet cuit", emoji: "🍚", portion: "150 g", grams: 150, kcal: 165, protein: 4, carbs: 34, fat: 1, fiber: 3, sugar: 0, category: .carbs),
        .init(name: "Pâtes cuites", emoji: "🍝", portion: "150 g", grams: 150, kcal: 220, protein: 8, carbs: 43, fat: 1, fiber: 2, sugar: 1, category: .carbs),
        .init(name: "Pommes de terre vapeur", emoji: "🥔", portion: "200 g", grams: 200, kcal: 170, protein: 4, carbs: 38, fat: 0, fiber: 4, sugar: 2, category: .carbs),
        .init(name: "Patate douce", emoji: "🍠", portion: "150 g", grams: 150, kcal: 130, protein: 2, carbs: 30, fat: 0, fiber: 4, sugar: 9, category: .carbs),
        .init(name: "Pain blanc", emoji: "🍞", portion: "1 tranche", grams: 30, kcal: 80, protein: 3, carbs: 15, fat: 1, fiber: 1, sugar: 1, category: .carbs),
        .init(name: "Pain complet", emoji: "🍞", portion: "1 tranche", grams: 30, kcal: 75, protein: 4, carbs: 13, fat: 1, fiber: 2, sugar: 1, category: .carbs),
        .init(name: "Quinoa cuit", emoji: "🥣", portion: "150 g", grams: 150, kcal: 180, protein: 6, carbs: 32, fat: 3, fiber: 4, sugar: 1, category: .carbs),
        .init(name: "Flocons d'avoine", emoji: "🥣", portion: "40 g", grams: 40, kcal: 150, protein: 5, carbs: 27, fat: 3, fiber: 4, sugar: 1, category: .carbs),
        .init(name: "Couscous cuit", emoji: "🍚", portion: "150 g", grams: 150, kcal: 170, protein: 6, carbs: 36, fat: 0, fiber: 2, sugar: 0, category: .carbs),

        // Vegetables
        .init(name: "Brocoli vapeur", emoji: "🥦", portion: "150 g", grams: 150, kcal: 50, protein: 4, carbs: 10, fat: 1, fiber: 4, sugar: 2, category: .vegetables),
        .init(name: "Salade verte", emoji: "🥬", portion: "1 bol", grams: 80, kcal: 12, protein: 1, carbs: 2, fat: 0, fiber: 1, sugar: 1, category: .vegetables),
        .init(name: "Tomate", emoji: "🍅", portion: "1 moyenne", grams: 120, kcal: 22, protein: 1, carbs: 5, fat: 0, fiber: 1, sugar: 3, category: .vegetables),
        .init(name: "Concombre", emoji: "🥒", portion: "150 g", grams: 150, kcal: 23, protein: 1, carbs: 5, fat: 0, fiber: 1, sugar: 3, category: .vegetables),
        .init(name: "Carotte", emoji: "🥕", portion: "1 moyenne", grams: 80, kcal: 33, protein: 1, carbs: 8, fat: 0, fiber: 2, sugar: 4, category: .vegetables),
        .init(name: "Courgette", emoji: "🥒", portion: "150 g", grams: 150, kcal: 25, protein: 2, carbs: 5, fat: 0, fiber: 2, sugar: 3, category: .vegetables),
        .init(name: "Poivron", emoji: "🫑", portion: "1 moyen", grams: 120, kcal: 30, protein: 1, carbs: 7, fat: 0, fiber: 2, sugar: 5, category: .vegetables),
        .init(name: "Épinards", emoji: "🥬", portion: "100 g", grams: 100, kcal: 23, protein: 3, carbs: 4, fat: 0, fiber: 2, sugar: 0, category: .vegetables),
        .init(name: "Haricots verts", emoji: "🫛", portion: "150 g", grams: 150, kcal: 45, protein: 3, carbs: 10, fat: 0, fiber: 4, sugar: 4, category: .vegetables),
        .init(name: "Champignons", emoji: "🍄", portion: "100 g", grams: 100, kcal: 22, protein: 3, carbs: 3, fat: 0, fiber: 1, sugar: 2, category: .vegetables),

        // Fruits
        .init(name: "Banane", emoji: "🍌", portion: "1 moyenne", grams: 120, kcal: 105, protein: 1, carbs: 27, fat: 0, fiber: 3, sugar: 14, category: .fruits),
        .init(name: "Pomme", emoji: "🍎", portion: "1 moyenne", grams: 180, kcal: 95, protein: 0, carbs: 25, fat: 0, fiber: 4, sugar: 19, category: .fruits),
        .init(name: "Orange", emoji: "🍊", portion: "1 moyenne", grams: 150, kcal: 65, protein: 1, carbs: 16, fat: 0, fiber: 3, sugar: 12, category: .fruits),
        .init(name: "Fraises", emoji: "🍓", portion: "150 g", grams: 150, kcal: 50, protein: 1, carbs: 12, fat: 0, fiber: 3, sugar: 7, category: .fruits),
        .init(name: "Raisin", emoji: "🍇", portion: "100 g", grams: 100, kcal: 70, protein: 1, carbs: 18, fat: 0, fiber: 1, sugar: 16, category: .fruits),
        .init(name: "Kiwi", emoji: "🥝", portion: "1 moyen", grams: 80, kcal: 42, protein: 1, carbs: 10, fat: 0, fiber: 2, sugar: 6, category: .fruits),
        .init(name: "Mangue", emoji: "🥭", portion: "100 g", grams: 100, kcal: 60, protein: 1, carbs: 15, fat: 0, fiber: 2, sugar: 14, category: .fruits),
        .init(name: "Ananas", emoji: "🍍", portion: "100 g", grams: 100, kcal: 50, protein: 1, carbs: 13, fat: 0, fiber: 1, sugar: 10, category: .fruits),
        .init(name: "Myrtilles", emoji: "🫐", portion: "100 g", grams: 100, kcal: 57, protein: 1, carbs: 14, fat: 0, fiber: 2, sugar: 10, category: .fruits),
        .init(name: "Avocat", emoji: "🥑", portion: "1/2", grams: 100, kcal: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, sugar: 1, category: .fruits),

        // Dairy
        .init(name: "Yaourt grec nature", emoji: "🥛", portion: "150 g", grams: 150, kcal: 100, protein: 17, carbs: 6, fat: 1, fiber: 0, sugar: 5, category: .dairy),
        .init(name: "Skyr nature", emoji: "🥛", portion: "150 g", grams: 150, kcal: 95, protein: 17, carbs: 6, fat: 0, fiber: 0, sugar: 5, category: .dairy),
        .init(name: "Fromage blanc 0%", emoji: "🥛", portion: "100 g", grams: 100, kcal: 50, protein: 8, carbs: 4, fat: 0, fiber: 0, sugar: 4, category: .dairy),
        .init(name: "Lait demi-écrémé", emoji: "🥛", portion: "200 ml", grams: 200, kcal: 92, protein: 7, carbs: 10, fat: 3, fiber: 0, sugar: 10, category: .dairy),
        .init(name: "Mozzarella", emoji: "🧀", portion: "30 g", grams: 30, kcal: 85, protein: 6, carbs: 1, fat: 6, fiber: 0, sugar: 0, category: .dairy),
        .init(name: "Comté", emoji: "🧀", portion: "30 g", grams: 30, kcal: 120, protein: 8, carbs: 0, fat: 10, fiber: 0, sugar: 0, category: .dairy),
        .init(name: "Feta", emoji: "🧀", portion: "30 g", grams: 30, kcal: 80, protein: 4, carbs: 1, fat: 6, fiber: 0, sugar: 1, category: .dairy),
        .init(name: "Parmesan", emoji: "🧀", portion: "20 g", grams: 20, kcal: 80, protein: 7, carbs: 1, fat: 5, fiber: 0, sugar: 0, category: .dairy),

        // Fats
        .init(name: "Huile d'olive", emoji: "🫒", portion: "1 c. à soupe", grams: 14, kcal: 120, protein: 0, carbs: 0, fat: 14, fiber: 0, sugar: 0, category: .fats),
        .init(name: "Beurre", emoji: "🧈", portion: "10 g", grams: 10, kcal: 75, protein: 0, carbs: 0, fat: 8, fiber: 0, sugar: 0, category: .fats),
        .init(name: "Amandes", emoji: "🌰", portion: "30 g", grams: 30, kcal: 175, protein: 6, carbs: 6, fat: 15, fiber: 4, sugar: 1, category: .fats),
        .init(name: "Noix", emoji: "🌰", portion: "30 g", grams: 30, kcal: 195, protein: 5, carbs: 4, fat: 19, fiber: 2, sugar: 1, category: .fats),
        .init(name: "Noix de cajou", emoji: "🌰", portion: "30 g", grams: 30, kcal: 165, protein: 5, carbs: 9, fat: 13, fiber: 1, sugar: 2, category: .fats),
        .init(name: "Beurre de cacahuète", emoji: "🥜", portion: "1 c. à soupe", grams: 16, kcal: 95, protein: 4, carbs: 3, fat: 8, fiber: 1, sugar: 1, category: .fats),

        // Drinks
        .init(name: "Café noir", emoji: "☕️", portion: "1 tasse", grams: 200, kcal: 2, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, category: .drinks),
        .init(name: "Thé vert", emoji: "🍵", portion: "1 tasse", grams: 200, kcal: 2, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, category: .drinks),
        .init(name: "Jus d'orange", emoji: "🧃", portion: "200 ml", grams: 200, kcal: 90, protein: 1, carbs: 21, fat: 0, fiber: 0, sugar: 18, category: .drinks),
        .init(name: "Coca-Cola", emoji: "🥤", portion: "33 cl", grams: 330, kcal: 140, protein: 0, carbs: 35, fat: 0, fiber: 0, sugar: 35, category: .drinks),
        .init(name: "Coca Zero", emoji: "🥤", portion: "33 cl", grams: 330, kcal: 1, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, category: .drinks),
        .init(name: "Bière blonde", emoji: "🍺", portion: "25 cl", grams: 250, kcal: 110, protein: 1, carbs: 9, fat: 0, fiber: 0, sugar: 0, category: .drinks),
        .init(name: "Vin rouge", emoji: "🍷", portion: "12 cl", grams: 120, kcal: 100, protein: 0, carbs: 3, fat: 0, fiber: 0, sugar: 1, category: .drinks),

        // Snacks
        .init(name: "Carré chocolat noir", emoji: "🍫", portion: "10 g", grams: 10, kcal: 55, protein: 1, carbs: 4, fat: 4, fiber: 1, sugar: 3, category: .snacks),
        .init(name: "Carré chocolat lait", emoji: "🍫", portion: "10 g", grams: 10, kcal: 55, protein: 1, carbs: 6, fat: 3, fiber: 0, sugar: 5, category: .snacks),
        .init(name: "Cookie", emoji: "🍪", portion: "1 unité", grams: 25, kcal: 120, protein: 1, carbs: 16, fat: 6, fiber: 1, sugar: 9, category: .snacks),
        .init(name: "Croissant", emoji: "🥐", portion: "1 unité", grams: 60, kcal: 235, protein: 5, carbs: 26, fat: 12, fiber: 2, sugar: 6, category: .snacks),
        .init(name: "Pain au chocolat", emoji: "🥐", portion: "1 unité", grams: 75, kcal: 290, protein: 6, carbs: 33, fat: 15, fiber: 2, sugar: 10, category: .snacks),
        .init(name: "Barre céréales", emoji: "🍫", portion: "1 unité", grams: 25, kcal: 100, protein: 2, carbs: 16, fat: 3, fiber: 1, sugar: 8, category: .snacks),
        .init(name: "Chips", emoji: "🍟", portion: "30 g", grams: 30, kcal: 160, protein: 2, carbs: 15, fat: 10, fiber: 1, sugar: 0, category: .snacks),
        .init(name: "Glace vanille", emoji: "🍨", portion: "1 boule", grams: 60, kcal: 130, protein: 2, carbs: 16, fat: 7, fiber: 0, sugar: 14, category: .snacks),
    ]

    static func search(_ query: String, in category: FoodCategory? = nil) -> [FoodItem] {
        var items = all
        if let category {
            items = items.filter { $0.category == category }
        }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
        return items.sorted { $0.name < $1.name }
    }
}

// MARK: - Food Favorite (SwiftData) — tracks user-marked favorites
@Model
final class FavoriteFood {
    var name: String = ""
    var emoji: String = ""
    var portion: String = ""
    var kcal: Int = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var addedAt: Date = Date()

    init(item: FoodItem) {
        self.name = item.name
        self.emoji = item.emoji
        self.portion = item.portion
        self.kcal = item.kcal
        self.protein = item.protein
        self.carbs = item.carbs
        self.fat = item.fat
        self.fiber = item.fiber
        self.sugar = item.sugar
        self.addedAt = Date()
    }
}
