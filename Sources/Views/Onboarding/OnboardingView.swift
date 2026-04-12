import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userGoal") private var userGoalRaw: String = ""
    @AppStorage("targetWeight") private var targetWeight: Double = 0
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4

    @State private var step: Int = 0
    @State private var weightInput: String = ""
    @State private var bfInput: String = ""
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
                Text("Tu as déjà des données ?")
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
            }
            .padding(.horizontal, 32)
        }
    }

    private var goalStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(theme.color.accent)

            VStack(spacing: 8) {
                Text("Quel est ton objectif ?")
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
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
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

                Text("Combien de séances par semaine ?")
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
                restoreMessage = "Restauration réussie ! Toutes tes données sont de retour."
                withAnimation(.spring) { onboardingCompleted = true }
            } catch {
                restoreMessage = "Échec de la restauration : \(error.localizedDescription)"
            }
            isRestoring = false
        case .failure(let error):
            restoreMessage = "Impossible de lire le fichier : \(error.localizedDescription)"
        }
    }
}
