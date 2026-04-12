import SwiftUI

struct NutritionSettingsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("calGoal") private var calGoal: Int = 2200
    @AppStorage("proteinGoal") private var proteinGoal: Int = 110
    @AppStorage("carbsGoal") private var carbsGoal: Int = 275
    @AppStorage("fatGoal") private var fatGoal: Int = 73

    // Meal toggles
    @AppStorage("mealBreakfastOn") private var breakfastOn: Bool = true
    @AppStorage("mealLunchOn") private var lunchOn: Bool = true
    @AppStorage("mealDinnerOn") private var dinnerOn: Bool = true
    @AppStorage("mealSnackOn") private var snackOn: Bool = true

    // Calorie split (percentages)
    @AppStorage("splitBreakfast") private var splitBreakfast: Int = 25
    @AppStorage("splitLunch") private var splitLunch: Int = 35
    @AppStorage("splitDinner") private var splitDinner: Int = 30
    @AppStorage("splitSnack") private var splitSnack: Int = 10

    private var splitTotal: Int {
        splitBreakfast + splitLunch + splitDinner + splitSnack
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Objectif calorique
                Section {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("Objectif journalier")
                        Spacer()
                        TextField("kcal", value: $calGoal, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .fontWeight(.bold)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Calories")
                }

                // MARK: - Macros
                Section {
                    macroRow(label: "Protéines", value: $proteinGoal, color: .orange, unit: "g")
                    macroRow(label: "Glucides", value: $carbsGoal, color: .blue, unit: "g")
                    macroRow(label: "Lipides", value: $fatGoal, color: .purple, unit: "g")
                } header: {
                    Text("Objectifs macros")
                } footer: {
                    let totalKcal = proteinGoal * 4 + carbsGoal * 4 + fatGoal * 9
                    Text("Total macros : \(totalKcal) kcal (objectif : \(calGoal) kcal)")
                        .font(.caption)
                }

                // MARK: - Repas actifs
                Section {
                    mealToggle("Petit-déj", icon: "sunrise.fill", isOn: $breakfastOn)
                    mealToggle("Déjeuner", icon: "sun.max.fill", isOn: $lunchOn)
                    mealToggle("Dîner", icon: "moon.fill", isOn: $dinnerOn)
                    mealToggle("Snack", icon: "cup.and.saucer.fill", isOn: $snackOn)
                } header: {
                    Text("Repas actifs")
                } footer: {
                    Text("Désactive les repas que tu ne prends pas. Les calories seront redistribuées sur les repas actifs.")
                        .font(.caption)
                }

                // MARK: - Répartition
                Section {
                    if breakfastOn {
                        splitRow(label: "Petit-déj", pct: $splitBreakfast)
                    }
                    if lunchOn {
                        splitRow(label: "Déjeuner", pct: $splitLunch)
                    }
                    if dinnerOn {
                        splitRow(label: "Dîner", pct: $splitDinner)
                    }
                    if snackOn {
                        splitRow(label: "Snack", pct: $splitSnack)
                    }
                } header: {
                    Text("Répartition des calories")
                } footer: {
                    HStack {
                        Text("Total : \(splitTotal)%")
                            .fontWeight(.bold)
                            .foregroundStyle(splitTotal == 100 ? .green : .red)
                        if splitTotal != 100 {
                            Text("— doit faire 100 %")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Réglages nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(theme.color.accent)
                }
            }
        }
    }

    private func macroRow(label: String, value: Binding<Int>, color: Color, unit: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .fontWeight(.bold)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    private func mealToggle(_ label: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(label, systemImage: icon)
        }
        .tint(theme.color.accent)
    }

    private func splitRow(label: String, pct: Binding<Int>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Stepper(
                "\(pct.wrappedValue) %",
                value: pct,
                in: 0...100,
                step: 5
            )
            .frame(width: 160)
        }
    }
}
