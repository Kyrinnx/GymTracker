import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("calGoal") private var calGoal: Int = 2200

    @State private var step: Int = 0
    @State private var weightInput: String = ""
    @State private var bfInput: String = ""
    @State private var showFilePicker = false
    @State private var restoreMessage: String?
    @State private var isRestoring = false
    @State private var showFolderPicker = false
    @State private var cloudFolderConfigured = AutoBackupService.isCloudFolderConfigured

    var body: some View {
        ZStack {
            theme.color.gradient
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<5) { i in
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
                    default: iCloudStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Bottom buttons
                if step == 1 {
                    // Restore step has its own buttons
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
                } else if step == 4 {
                    // iCloud step: show folder picker button, then Commencer when configured
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
                                next()
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
        if step < 4 {
            // Save weight when leaving step 3 (body measurements)
            if step == 3 {
                if let kg = Double(weightInput.replacingOccurrences(of: ",", with: ".")), kg > 0 {
                    let bf = Double(bfInput.replacingOccurrences(of: ",", with: "."))
                    context.insert(WeightEntry(kg: kg, bodyFat: bf))
                }
            }
            withAnimation(.spring) { step += 1 }
            return
        }
        // Final step (4): mark onboarding complete
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
                // Skip to end — data is restored, no need for name/weight steps
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
