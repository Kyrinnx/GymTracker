import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query private var allMeals: [MealEntry]
    @Query private var waterEntries: [WaterEntry]
    @Query(sort: \FastingSession.startDate, order: .reverse) private var fastingSessions: [FastingSession]

    @AppStorage("calGoal") private var calGoal: Int = 2200
    @AppStorage("proteinGoal") private var proteinGoal: Int = 110
    @AppStorage("carbsGoal") private var carbsGoal: Int = 275
    @AppStorage("fatGoal") private var fatGoal: Int = 73

    // Meal toggles
    @AppStorage("mealBreakfastOn") private var breakfastOn: Bool = true
    @AppStorage("mealLunchOn") private var lunchOn: Bool = true
    @AppStorage("mealDinnerOn") private var dinnerOn: Bool = true
    @AppStorage("mealSnackOn") private var snackOn: Bool = true

    // Calorie split
    @AppStorage("splitBreakfast") private var splitBreakfast: Int = 25
    @AppStorage("splitLunch") private var splitLunch: Int = 35
    @AppStorage("splitDinner") private var splitDinner: Int = 30
    @AppStorage("splitSnack") private var splitSnack: Int = 10

    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false
    @State private var addSheetType: MealType?
    @State private var showFasting = false
    @State private var showSettings = false
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeFast: FastingSession? {
        fastingSessions.first { $0.isActive }
    }

    private var todayMeals: [MealEntry] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allMeals.filter { $0.date >= start && $0.date < end }
    }
    private var todayCal: Int { todayMeals.reduce(0) { $0 + $1.calories } }
    private var todayProt: Double { todayMeals.reduce(0) { $0 + $1.protein } }
    private var todayCarb: Double { todayMeals.reduce(0) { $0 + $1.carbs } }
    private var todayFat: Double { todayMeals.reduce(0) { $0 + $1.fat } }
    private var remainingCal: Int { max(0, calGoal - todayCal) }

    private var todayWater: WaterEntry? {
        let start = Calendar.current.startOfDay(for: Date())
        return waterEntries.first { Calendar.current.isDate($0.date, inSameDayAs: start) }
    }

    private var activeMealTypes: [MealType] {
        var types: [MealType] = []
        if breakfastOn { types.append(.breakfast) }
        if lunchOn { types.append(.lunch) }
        if dinnerOn { types.append(.dinner) }
        if snackOn { types.append(.snack) }
        return types
    }

    private func targetFor(_ type: MealType) -> Int {
        let pct: Int
        switch type {
        case .breakfast: pct = splitBreakfast
        case .lunch: pct = splitLunch
        case .dinner: pct = splitDinner
        case .snack: pct = splitSnack
        }
        return Int(Double(calGoal) * Double(pct) / 100.0)
    }

    private func mealsFor(_ type: MealType) -> [MealEntry] {
        todayMeals.filter { $0.type == type }
    }

    private func caloriesFor(_ type: MealType) -> Int {
        mealsFor(type).reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    fastingCard
                    summarySection
                    waterRow
                    mealsSection
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onReceive(timer) { now = $0 }
            .sheet(item: $addSheetType) { type in
                FoodSearchView(mealType: type)
            }
            .sheet(isPresented: $showSettings) {
                NutritionSettingsView()
            }
            .fullScreenCover(isPresented: $showFasting) {
                NavigationStack {
                    FastingView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button { showFasting = false } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Aujourd'hui")
                    .font(.system(size: 36, weight: .black))
                Text(weekString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var weekString: String {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        return "Semaine \(week)"
    }

    // MARK: - Fasting Card

    @ViewBuilder
    private var fastingCard: some View {
        Button {
            showFasting = true
        } label: {
            if let active = activeFast {
                activeFastingMini(active)
            } else {
                idleFastingMini
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func activeFastingMini(_ session: FastingSession) -> some View {
        let progress = session.progress
        let inEatingWindow = progress >= 1.0
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(theme.color.accent.opacity(0.18), lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.color.gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text(session.method.emoji)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(inEatingWindow ? "Fenêtre alimentaire ouverte" : "Tu jeûnes")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(formatDuration(inEatingWindow ? Date().timeIntervalSince(session.plannedEndDate) : session.remaining))
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(inEatingWindow ? .green : .primary)
                Text("\(session.method.label) · \(session.currentStage.label)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var idleFastingMini: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(theme.color.accent)
                .frame(width: 56, height: 56)
                .background(theme.color.accent.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Jeûne intermittent")
                    .font(.subheadline.bold())
                Text("Lance un jeûne 16:8, 18:6, OMAD…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(abs(seconds))
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Résumé")
                .font(.title3.bold())
                .padding(.horizontal)

            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    smallStat(value: "\(todayCal)", label: "Mangées")
                    Spacer()
                    GaugeRing(value: Double(todayCal), goal: Double(calGoal), accent: theme.color.accent)
                        .frame(width: 130, height: 130)
                    Spacer()
                    smallStat(value: "0", label: "Brûlées")
                }
                .padding(.top, 4)

                HStack(spacing: 14) {
                    macroBar(label: "Glucides", value: todayCarb, goal: Double(carbsGoal), color: .blue)
                    macroBar(label: "Protéines", value: todayProt, goal: Double(proteinGoal), color: .orange)
                    macroBar(label: "Lipides", value: todayFat, goal: Double(fatGoal), color: .purple)
                }
            }
            .padding(18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal)
        }
    }

    private func smallStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 60)
    }

    private func macroBar(label: String, value: Double, goal: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(1, value / max(goal, 1))))
                }
            }
            .frame(height: 6)
            Text("\(Int(value)) / \(Int(goal)) g")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Water

    @AppStorage("waterGoalMl") private var waterGoalMl: Int = 3000

    private var todayTotalMl: Int { todayWater?.totalMl ?? 0 }
    private var waterProgress: Double {
        guard waterGoalMl > 0 else { return 0 }
        return min(1.0, Double(todayTotalMl) / Double(waterGoalMl))
    }

    @State private var showWaterInput = false
    @State private var manualMlText = ""

    private var waterRow: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                // Bottle visual
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 80)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 40, height: max(4, 80 * waterProgress))
                        .animation(.spring(duration: 0.4), value: waterProgress)
                    // Cap
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 24, height: 8)
                        .offset(y: -40)
                }
                .frame(height: 88)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedLiters(todayTotalMl))
                            .font(.title2.bold().monospacedDigit())
                        Text("/ \(formattedLiters(waterGoalMl))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(Int(waterProgress * 100)) %")
                        .font(.caption.bold())
                        .foregroundStyle(waterProgress >= 1 ? .green : .blue)

                    // Quick add buttons
                    HStack(spacing: 8) {
                        waterQuickButton(ml: 250, label: "250 ml")
                        waterQuickButton(ml: 500, label: "500 ml")
                        waterQuickButton(ml: 330, label: "33 cl")
                        Button {
                            showWaterInput = true
                            manualMlText = ""
                        } label: {
                            Text("...")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                                .frame(width: 36, height: 28)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Remove button
                VStack(spacing: 8) {
                    Button { removeWater(ml: 250) } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    Button {
                        showWaterInput = true
                        manualMlText = ""
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Manual ml input (expandable)
            if showWaterInput {
                HStack(spacing: 10) {
                    TextField("ml", text: $manualMlText)
                        .keyboardType(.numberPad)
                        .font(.callout.bold())
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(width: 100)
                    Text("ml")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        if let ml = Int(manualMlText), ml > 0 {
                            addWater(ml: ml)
                        }
                        showWaterInput = false
                    } label: {
                        Text("Ajouter")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Goal editor
            HStack {
                Text("Objectif")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Button { waterGoalMl = max(500, waterGoalMl - 250) } label: {
                        Image(systemName: "minus")
                            .font(.caption2.bold())
                            .frame(width: 24, height: 24)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Text(formattedLiters(waterGoalMl))
                        .font(.caption.bold())
                        .monospacedDigit()
                        .frame(width: 45)
                    Button { waterGoalMl = min(6000, waterGoalMl + 250) } label: {
                        Image(systemName: "plus")
                            .font(.caption2.bold())
                            .frame(width: 24, height: 24)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .animation(.spring(duration: 0.3), value: showWaterInput)
    }

    private func waterQuickButton(ml: Int, label: String) -> some View {
        Button { addWater(ml: ml) } label: {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func addWater(ml: Int) {
        if let entry = todayWater {
            entry.milliliters += ml
        } else {
            context.insert(WaterEntry(milliliters: ml))
        }
        if healthKitEnabled {
            HealthKitService.shared.saveWater(milliliters: ml, date: Date())
        }
    }

    private func removeWater(ml: Int) {
        guard let entry = todayWater else { return }
        entry.milliliters = max(0, entry.milliliters - ml)
    }

    private func formattedLiters(_ ml: Int) -> String {
        if ml >= 1000 {
            let l = Double(ml) / 1000.0
            return String(format: "%.1f L", l)
        }
        return "\(ml) ml"
    }

    // MARK: - Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alimentation")
                .font(.title3.bold())
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(activeMealTypes) { type in
                    mealCard(type)
                }
            }
            .padding(.horizontal)
        }
    }

    private func mealCard(_ type: MealType) -> some View {
        let meals = mealsFor(type)
        let consumed = caloriesFor(type)
        let target = targetFor(type)
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(theme.color.accent)
                    .frame(width: 44, height: 44)
                    .background(theme.color.accent.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.label)
                        .font(.headline.bold())
                    Text("\(consumed) / \(target) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    addSheetType = type
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(theme.color.gradient)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            if !meals.isEmpty {
                Divider().padding(.horizontal, 14)
                VStack(spacing: 0) {
                    ForEach(meals) { meal in
                        mealItemRow(meal)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func mealItemRow(_ meal: MealEntry) -> some View {
        HStack(spacing: 10) {
            Text("•")
                .foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(meal.name.isEmpty ? "Aliment" : meal.name)
                    .font(.subheadline.weight(.medium))
                if meal.protein + meal.carbs + meal.fat > 0 {
                    Text("\(Int(meal.protein))P · \(Int(meal.carbs))G · \(Int(meal.fat))L")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(meal.calories) kcal")
                .font(.caption.bold())
                .foregroundStyle(theme.color.accent)
            Button {
                if healthKitEnabled {
                    HealthKitService.shared.deleteMeal(
                        calories: meal.calories, protein: meal.protein, carbs: meal.carbs,
                        fat: meal.fat, fiber: meal.fiber, sugar: meal.sugar, date: meal.date
                    )
                }
                context.delete(meal)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Gauge Ring

private struct GaugeRing: View {
    let value: Double
    let goal: Double
    let accent: Color

    private var pct: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    private var remaining: Int { max(0, Int(goal - value)) }

    private var ringColor: Color {
        let p = goal > 0 ? value / goal : 0
        if p > 1 { return .red }
        if p > 0.85 { return .orange }
        return accent
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(90))
            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * pct)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(90))
                .animation(.spring(duration: 0.6), value: pct)
            VStack(spacing: 2) {
                Text("\(remaining)")
                    .font(.system(size: 32, weight: .black))
                    .monospacedDigit()
                Text("Restantes")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
