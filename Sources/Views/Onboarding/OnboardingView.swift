import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("calGoal") private var calGoal: Int = 2200

    @State private var step: Int = 0
    @State private var weightInput: String = ""
    @State private var bfInput: String = ""

    var body: some View {
        ZStack {
            theme.color.gradient
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == step ? theme.color.accent : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 32)

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: nameStep
                    default: bodyStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Bottom button
                Button {
                    next()
                } label: {
                    HStack {
                        Text(step == 2 ? "Commencer" : "Suivant")
                            .fontWeight(.bold)
                        Image(systemName: step == 2 ? "checkmark" : "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .disabled(step == 1 && userName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(step == 1 && userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                if step > 0 {
                    Button("Retour") {
                        withAnimation(.spring) { step -= 1 }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundStyle(theme.color.gradient)

            VStack(spacing: 12) {
                Text("GymTracker")
                    .font(.system(size: 40, weight: .black))

                Text("Suis tes séances, ta nutrition\net ta progression")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 32)
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 8) {
                Text("Comment t'appelles-tu ?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("On t'accueillera avec ton prénom")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("Prénom", text: $userName)
                .textInputAutocapitalization(.words)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
        }
    }

    private var bodyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 70))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 8) {
                Text("Tes mesures de départ")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Optionnel — tu pourras les ajouter plus tard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("POIDS (KG)")
                            .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                        TextField("75", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BF %")
                            .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                        TextField("opt.", text: $bfInput)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                HStack {
                    Text("OBJECTIF CALORIQUE")
                        .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                    Spacer()
                    TextField("kcal", value: $calGoal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.title3.bold())
                        .frame(width: 100)
                        .padding(10)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Logic

    private func next() {
        if step < 2 {
            withAnimation(.spring) { step += 1 }
            return
        }
        // Final step: save weight if provided, mark complete
        if let kg = Double(weightInput.replacingOccurrences(of: ",", with: ".")), kg > 0 {
            let bf = Double(bfInput.replacingOccurrences(of: ",", with: "."))
            context.insert(WeightEntry(kg: kg, bodyFat: bf))
        }
        withAnimation(.spring) { onboardingCompleted = true }
    }
}
