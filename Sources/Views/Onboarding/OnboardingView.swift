import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userGoal") private var userGoalRaw: String = ""
    @AppStorage("targetWeight") private var targetWeight: Double = 0
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4
    @AppStorage("userHeight") private var userHeight: Int = 0
    @AppStorage("userAge") private var userAge: Int = 0
    @AppStorage("activityLevel") private var activityLevelRaw: String = "moderate"

    @State private var step: Int = 0
    @State private var weightInput: String = ""
    @State private var bfInput: String = ""
    @State private var heightInput: String = ""
    @State private var ageInput: String = ""
    @State private var targetWeightInput: String = ""
    @State private var selectedGoal: FitnessGoal? = nil
    @State private var showFilePicker = false
    @State private var restoreMessage: String?
    @State private var isRestoring = false
    @State private var showFolderPicker = false
    @State private var cloudFolderConfigured = AutoBackupService.isCloudFolderConfigured

    private let totalSteps = 7

    var body: some View {
        ZStack {
            theme.color.gradient
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
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
                    case 1: restoreStep
                    case 2: nameStep
                    case 3: bodyStep
                    case 4: goalStep
                    case 5: frequencyStep
                    default: iCloudStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Bottom buttons
                bottomButtons

                if step > 0 && step != 1 {
                    Button("Retour") {
                        withAnimation(.spring) { step -= 1 }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleRestore(result)
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView { url in
                AutoBackupService.setCloudFolder(url)
                withAnimation(.spring) {
                    cloudFolderConfigured = true
                }
            }
        }
        .alert("Restauration", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    // MARK: - Bottom Buttons

    @ViewBuilder
    private var bottomButtons: some View {
        if step == 1 {
            // Restore step
            VStack(spacing: 12) {
                Button {
                    showFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restaurer une sauvegarde")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring) { step += 1 }
                } label: {
                    Text("Commencer à zéro")
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.color.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        } else if step == totalSteps - 1 {
            // iCloud step (last)
            VStack(spacing: 12) {
                if !cloudFolderConfigured {
                    Button {
                        showFolderPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                            Text("Configurer iCloud Drive")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }

                if cloudFolderConfigured {
                    Button {
                        finishOnboarding()
                    } label: {
                        HStack {
                            Text("Commencer")
                                .fontWeight(.bold)
                            Image(systemName: "checkmark")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        } else if step == 4 || step == 5 {
            // Goal & frequency: allow skip
            VStack(spacing: 12) {
                Button {
                    next()
                } label: {
                    HStack {
                        Text("Suivant")
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring) { step += 1 }
                } label: {
                    Text("Passer")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        } else {
            Button {
                next()
            } label: {
                HStack {
                    Text("Suivant")
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .disabled(step == 2 && userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(step == 2 && userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
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

                Text("Suis tes séances de muscu\net ta progression")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 32)
    }

    private var restoreStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.down.fill")
                .font(.system(size: 70))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 12) {
                Text("Tu as déjà des données\u{00A0}?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Si tu avais GymTracker avant, tu peux restaurer une sauvegarde depuis iCloud Drive ou tes fichiers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            if isRestoring {
                ProgressView()
                    .padding(.top, 8)
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
                Text("Comment t'appelles-tu\u{00A0}?")
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
        VStack(spacing: 20) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 8) {
                Text("Tes mesures")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Pour calculer ton métabolisme de base")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TAILLE (CM)")
                            .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                        TextField("175", text: $heightInput)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ÂGE")
                            .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                        TextField("25", text: $ageInput)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
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
            }
            .padding(.horizontal, 32)

            // Activity level
            VStack(alignment: .leading, spacing: 8) {
                Text("NIVEAU D'ACTIVITÉ")
                    .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ActivityLevel.allCases) { level in
                            let selected = activityLevelRaw == level.rawValue
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    activityLevelRaw = level.rawValue
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: level.icon)
                                        .font(.caption)
                                    Text(level.label)
                                        .font(.system(size: 10, weight: .bold))
                                    Text(level.subtitle)
                                        .font(.system(size: 8))
                                        .foregroundStyle(selected ? .white.opacity(0.8) : .secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(minWidth: 90)
                                .background(selected ? theme.color.accent : Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(selected ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
    }

    private var goalStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 8) {
                Text("Quel est ton objectif\u{00A0}?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("On adaptera le suivi à ton objectif")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(FitnessGoal.allCases) { goal in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedGoal = goal
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: goal.icon)
                                .font(.title3)
                                .frame(width: 32)
                                .foregroundStyle(selectedGoal == goal ? .white : theme.color.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.label)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(selectedGoal == goal ? .white : .primary)
                                Text(goal.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(selectedGoal == goal ? .white.opacity(0.8) : .secondary)
                            }
                            Spacer()
                            if selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(12)
                        .background(selectedGoal == goal ? theme.color.accent : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            // Target weight input for cut/bulk
            if let goal = selectedGoal, goal.hasWeightTarget {
                VStack(spacing: 8) {
                    Text("POIDS CIBLE (KG)")
                        .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                    TextField(goal == .cut ? "68" : "82", text: $targetWeightInput)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .frame(width: 140)

                    // Estimation
                    if let estimation = goalEstimation {
                        Text(estimation)
                            .font(.caption)
                            .foregroundStyle(theme.color.accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Danger warning
                    if let warning = targetWeightWarning {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
    }

    /// Warning if target weight is dangerous based on height/current weight
    private var targetWeightWarning: String? {
        guard let goal = selectedGoal, goal.hasWeightTarget else { return nil }
        guard let currentKg = Double(weightInput.replacingOccurrences(of: ",", with: ".")),
              currentKg > 0,
              let tgtKg = Double(targetWeightInput.replacingOccurrences(of: ",", with: ".")),
              tgtKg > 0 else { return nil }

        let heightCm = Double(heightInput) ?? Double(userHeight)
        let heightM = heightCm > 0 ? heightCm / 100.0 : 0

        if goal == .cut {
            // Check BMI at target if height known
            if heightM > 0 {
                let targetBMI = tgtKg / (heightM * heightM)
                if targetBMI < 17 {
                    return "⚠️ Danger\u{00A0}: ton poids cible correspond à un IMC de \(String(format: "%.1f", targetBMI)), ce qui est très insuffisant et dangereux pour ta santé."
                } else if targetBMI < 18.5 {
                    return "Attention\u{00A0}: ton poids cible correspond à un IMC sous la normale (\(String(format: "%.1f", targetBMI))). Consulte un professionnel de santé."
                }
            }
            // Check % loss too extreme
            let lossPercent = (currentKg - tgtKg) / currentKg * 100
            if lossPercent > 30 {
                return "Perdre \(Int(lossPercent))% de ton poids est dangereux. Un objectif réaliste est 10-15% max par phase de sèche."
            } else if lossPercent > 20 {
                return "Attention\u{00A0}: perdre \(Int(lossPercent))% de ton poids en une seule phase peut entraîner une perte de muscle importante. Envisage plusieurs phases."
            }
        } else if goal == .bulk {
            if heightM > 0 {
                let targetBMI = tgtKg / (heightM * heightM)
                if targetBMI > 35 {
                    return "Attention\u{00A0}: ton poids cible correspond à un IMC de \(String(format: "%.1f", targetBMI)), ce qui comporte des risques pour ta santé."
                }
            }
            let gainPercent = (tgtKg - currentKg) / currentKg * 100
            if gainPercent > 25 {
                return "Prendre \(Int(gainPercent))% de ton poids risque d'entraîner un excès de gras. Un gain de 10-15% par phase est recommandé."
            }
        }
        return nil
    }

    private var goalEstimation: String? {
        guard let goal = selectedGoal,
              let currentKg = Double(weightInput.replacingOccurrences(of: ",", with: ".")),
              currentKg > 0,
              let tgtKg = Double(targetWeightInput.replacingOccurrences(of: ",", with: ".")),
              tgtKg > 0 else { return nil }
        guard let weeks = goal.estimatedWeeks(from: currentKg, to: tgtKg) else { return nil }
        let months = weeks / 4
        let remainingWeeks = weeks % 4
        let rate = String(format: "%.1f", abs(goal.weeklyRate))
        let direction = goal == .cut ? "perdant" : "prenant"
        if months > 0 {
            return "~\(months) mois\(remainingWeeks > 0 ? " et \(remainingWeeks) sem." : "") en \(direction) \(rate) kg/sem."
        } else {
            return "~\(weeks) semaines en \(direction) \(rate) kg/sem."
        }
    }

    private var frequencyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 8) {
                Text("Fréquence d'entraînement")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Combien de séances par semaine\u{00A0}?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                Text("\(weeklyGoal)")
                    .font(.system(size: 60, weight: .black))
                    .foregroundStyle(theme.color.accent)

                Text(weeklyGoal == 1 ? "séance / semaine" : "séances / semaine")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ForEach(1...7, id: \.self) { n in
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                weeklyGoal = n
                            }
                        } label: {
                            Text("\(n)")
                                .font(.callout.bold())
                                .foregroundStyle(weeklyGoal == n ? .white : .primary)
                                .frame(width: 38, height: 38)
                                .background(weeklyGoal == n ? theme.color.accent : Color(.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
    }

    private var iCloudStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.fill")
                .font(.system(size: 70))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 12) {
                Text("Configure ta sauvegarde")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Choisis un dossier iCloud Drive pour sauvegarder tes données automatiquement. Tu ne perdras rien, même si tu supprimes l'app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            if cloudFolderConfigured {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("iCloud Drive configuré")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Logic

    private func next() {
        if step == 3 {
            // Save height & age
            if let h = Int(heightInput), h > 0 { userHeight = h }
            if let a = Int(ageInput), a > 0 { userAge = a }
            // Save weight when leaving body step
            if let kg = Double(weightInput.replacingOccurrences(of: ",", with: ".")), kg > 0 {
                let bf = Double(bfInput.replacingOccurrences(of: ",", with: "."))
                context.insert(WeightEntry(kg: kg, bodyFat: bf))
            }
        }
        if step == 4 {
            // Save goal
            if let goal = selectedGoal {
                userGoalRaw = goal.rawValue
                if let tgt = Double(targetWeightInput.replacingOccurrences(of: ",", with: ".")), tgt > 0 {
                    targetWeight = tgt
                }
            }
        }
        if step < totalSteps - 1 {
            withAnimation(.spring) { step += 1 }
            return
        }
        finishOnboarding()
    }

    private func finishOnboarding() {
        withAnimation(.spring) { onboardingCompleted = true }
    }

    private func handleRestore(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isRestoring = true
            do {
                try DataExportService.importAll(from: url, into: context, replaceAll: true)
                restoreMessage = "Restauration réussie\u{00A0}! Toutes tes données sont de retour."
                withAnimation(.spring) { onboardingCompleted = true }
            } catch {
                restoreMessage = "Échec de la restauration\u{00A0}: \(error.localizedDescription)"
            }
            isRestoring = false
        case .failure(let error):
            restoreMessage = "Impossible de lire le fichier\u{00A0}: \(error.localizedDescription)"
        }
    }
}
