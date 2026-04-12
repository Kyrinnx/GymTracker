import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mealType: MealType

    @Query(sort: \MealEntry.date, order: .reverse) private var allMeals: [MealEntry]
    @Query(sort: \FavoriteFood.addedAt, order: .reverse) private var favorites: [FavoriteFood]

    @State private var searchText: String = ""
    @State private var selectedTab: Tab = .frequent
    @State private var selectedCategory: FoodCategory?
    @State private var addedCount: Int = 0
    @State private var pendingPortion: FoodItem?
    @State private var showScanner = false

    enum Tab: String, CaseIterable, Identifiable {
        case frequent, recent, favorite
        var id: String { rawValue }
        var label: String {
            switch self {
            case .frequent: "Fréquents"
            case .recent: "Récents"
            case .favorite: "Favoris"
            }
        }
    }

    private var promptText: String {
        switch mealType {
        case .breakfast: "Qu'avez-vous mangé ce matin ?"
        case .lunch: "Qu'avez-vous mangé ce midi ?"
        case .dinner: "Qu'avez-vous mangé ce soir ?"
        case .snack: "Qu'avez-vous grignoté ?"
        }
    }

    private var catalogMatches: [FoodItem] {
        FoodCatalog.search(searchText, in: selectedCategory)
    }

    private var frequentItems: [FoodItem] {
        let counts = Dictionary(grouping: allMeals, by: { $0.name })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { $0.key }
        return counts.compactMap { name -> FoodItem? in
            if let item = FoodCatalog.all.first(where: { $0.name == name }) { return item }
            if let last = allMeals.first(where: { $0.name == name }) {
                return FoodItem(
                    name: last.name, emoji: "🍽", portion: "1 portion", grams: 0,
                    kcal: last.calories, protein: last.protein, carbs: last.carbs,
                    fat: last.fat, fiber: last.fiber, sugar: last.sugar, category: .snacks
                )
            }
            return nil
        }
    }

    private var recentItems: [FoodItem] {
        var seen = Set<String>()
        var result: [FoodItem] = []
        for meal in allMeals where !seen.contains(meal.name) {
            seen.insert(meal.name)
            if let item = FoodCatalog.all.first(where: { $0.name == meal.name }) {
                result.append(item)
            } else {
                result.append(FoodItem(
                    name: meal.name, emoji: "🍽", portion: "1 portion", grams: 0,
                    kcal: meal.calories, protein: meal.protein, carbs: meal.carbs,
                    fat: meal.fat, fiber: meal.fiber, sugar: meal.sugar, category: .snacks
                ))
            }
            if result.count >= 20 { break }
        }
        return result
    }

    private var favoriteItems: [FoodItem] {
        favorites.map { fav in
            FoodItem(
                name: fav.name, emoji: fav.emoji.isEmpty ? "⭐️" : fav.emoji, portion: fav.portion,
                grams: 0, kcal: fav.kcal, protein: fav.protein, carbs: fav.carbs,
                fat: fav.fat, fiber: fav.fiber, sugar: fav.sugar, category: .snacks
            )
        }
    }

    private var displayedItems: [FoodItem] {
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategory != nil {
            return catalogMatches
        }
        switch selectedTab {
        case .frequent: return frequentItems.isEmpty ? Array(FoodCatalog.all.prefix(15)) : frequentItems
        case .recent: return recentItems
        case .favorite: return favoriteItems
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                categoryRow
                tabs
                if displayedItems.isEmpty {
                    emptyState
                } else {
                    foodList
                }
                Spacer(minLength: 0)
                bottomBar
            }
            .navigationTitle(mealType.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(item: $pendingPortion) { item in
                PortionSheet(item: item, mealType: mealType)
            }
            .fullScreenCover(isPresented: $showScanner) {
                BarcodeScannerView(mealType: mealType)
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(promptText, text: $searchText)
                .textInputAutocapitalization(.sentences)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            Button {
                showScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .font(.title3)
                    .foregroundStyle(theme.color.accent)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .padding(12)
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(theme.color.accent.opacity(0.5), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryChip(nil, label: "Tous", icon: "square.grid.2x2.fill")
                ForEach(FoodCategory.allCases) { cat in
                    categoryChip(cat, label: cat.label, icon: cat.icon)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private func categoryChip(_ cat: FoodCategory?, label: String, icon: String) -> some View {
        let isOn = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = (selectedCategory == cat) ? nil : cat
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? theme.color.accent : Color.secondary.opacity(0.12))
            .foregroundStyle(isOn ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                } label: {
                    Text(tab.label)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedTab == tab ? Color.primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == tab ? Color.secondary.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var foodList: some View {
        List {
            ForEach(displayedItems) { item in
                foodRow(item)
                    .listRowSeparator(.visible)
            }
        }
        .listStyle(.plain)
    }

    private func foodRow(_ item: FoodItem) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(item.portion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(item.kcal) kcal")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(theme.color.accent)
            Button {
                pendingPortion = item
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.color.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                toggleFavorite(item)
            } label: {
                Label("Favori", systemImage: isFavorite(item) ? "star.slash" : "star.fill")
            }
            .tint(.yellow)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("Aucun aliment")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button {
                showScanner = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title3)
                    Text("Scanner")
                        .font(.caption2)
                }
                .foregroundStyle(theme.color.accent)
            }
            .buttonStyle(.plain)

            Button { dismiss() } label: {
                Text("Terminé\(addedCount > 0 ? " (\(addedCount))" : "")")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.color.gradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: - Logic

    private func isFavorite(_ item: FoodItem) -> Bool {
        favorites.contains { $0.name == item.name }
    }

    private func toggleFavorite(_ item: FoodItem) {
        if let existing = favorites.first(where: { $0.name == item.name }) {
            context.delete(existing)
        } else {
            context.insert(FavoriteFood(item: item))
        }
    }
}

// MARK: - Portion Sheet (fixé + macros éditables + favori)

struct PortionSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let item: FoodItem
    let mealType: MealType

    @State private var multiplier: Double = 1.0
    @State private var editKcal: String = ""
    @State private var editProt: String = ""
    @State private var editCarbs: String = ""
    @State private var editFat: String = ""
    @State private var saveAsFavorite = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(item.emoji)
                            .font(.system(size: 50))
                        Text(item.name)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                        Text(item.portion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // Quantity slider
                    VStack(spacing: 12) {
                        HStack {
                            Text("Quantité")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "× %.2g", multiplier))
                                .font(.title3.bold())
                                .foregroundStyle(theme.color.accent)
                        }
                        HStack(spacing: 12) {
                            Button { multiplier = max(0.25, multiplier - 0.25) } label: {
                                Image(systemName: "minus")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(theme.color.accent.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            Slider(value: $multiplier, in: 0.25...5, step: 0.25)
                                .tint(theme.color.accent)
                                .onChange(of: multiplier) { _, _ in recalcFields() }
                            Button { multiplier = min(5, multiplier + 0.25) } label: {
                                Image(systemName: "plus")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(theme.color.accent)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Editable macros
                    VStack(spacing: 8) {
                        Text("VALEURS NUTRITIONNELLES")
                            .font(.caption2.bold())
                            .tracking(1)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Modifie les valeurs si besoin")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 8) {
                            editField("kcal", text: $editKcal, kbd: .numberPad)
                            editField("P (g)", text: $editProt, kbd: .decimalPad)
                            editField("G (g)", text: $editCarbs, kbd: .decimalPad)
                            editField("L (g)", text: $editFat, kbd: .decimalPad)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Save as favorite toggle
                    Toggle(isOn: $saveAsFavorite) {
                        Label("Sauvegarder en favori", systemImage: "star.fill")
                    }
                    .tint(.yellow)

                    // Add button
                    Button { addItem() } label: {
                        Text("Ajouter")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.color.gradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .onAppear { recalcFields() }
        }
        .presentationDetents([.large])
    }

    private func editField(_ label: String, text: Binding<String>, kbd: UIKeyboardType) -> some View {
        VStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(kbd)
                .multilineTextAlignment(.center)
                .font(.callout.bold())
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func recalcFields() {
        editKcal = "\(Int(Double(item.kcal) * multiplier))"
        editProt = "\(Int(item.protein * multiplier))"
        editCarbs = "\(Int(item.carbs * multiplier))"
        editFat = "\(Int(item.fat * multiplier))"
    }

    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false

    private func addItem() {
        let kcal = Int(editKcal) ?? 0
        let prot = Double(editProt) ?? 0
        let carbs = Double(editCarbs) ?? 0
        let fat = Double(editFat) ?? 0
        let fib = item.fiber * multiplier
        let sug = item.sugar * multiplier

        let meal = MealEntry(
            name: item.name, type: mealType, calories: kcal,
            protein: prot, carbs: carbs, fat: fat,
            fiber: fib, sugar: sug
        )
        context.insert(meal)

        if healthKitEnabled {
            HealthKitService.shared.saveMeal(
                calories: kcal, protein: prot, carbs: carbs,
                fat: fat, fiber: fib, sugar: sug, date: meal.date
            )
        }

        if saveAsFavorite {
            let favItem = FoodItem(
                name: item.name, emoji: item.emoji, portion: item.portion,
                grams: item.grams, kcal: kcal, protein: prot, carbs: carbs,
                fat: fat, fiber: fib, sugar: sug,
                category: item.category
            )
            context.insert(FavoriteFood(item: favItem))
        }

        dismiss()
    }
}
