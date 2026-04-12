import SwiftUI

struct TutorialStep {
    let title: String
    let message: String
    let icon: String
    let tab: ContentView.Tab?
}

struct SpotlightTutorial: View {
    @Environment(ThemeManager.self) private var theme
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var opacity: Double = 0

    let steps: [TutorialStep] = [
        TutorialStep(
            title: "Bienvenue !",
            message: "Voici un rapide tour de l'application pour te montrer les fonctionnalités principales.",
            icon: "hand.wave.fill",
            tab: .home
        ),
        TutorialStep(
            title: "Séance libre",
            message: "Lance une séance sans programme. Tu ajoutes tes exercices au fur et à mesure.",
            icon: "bolt.fill",
            tab: .home
        ),
        TutorialStep(
            title: "Tes programmes",
            message: "Crée tes propres programmes avec le \"+\" ou importe-les via l'IA. Appui long pour dupliquer, mettre en favori ou supprimer.",
            icon: "rectangle.stack.fill",
            tab: .home
        ),
        TutorialStep(
            title: "Bibliothèque",
            message: "Des programmes prêts à l'emploi : Upper/Lower, PPL, Full Body, Bro Split. Tu peux les ajouter à tes séances.",
            icon: "books.vertical.fill",
            tab: .home
        ),
        TutorialStep(
            title: "Import IA",
            message: "Copie le prompt, envoie-le à ChatGPT ou Claude, puis colle le résultat. Tu peux importer plusieurs séances d'un coup.",
            icon: "sparkles",
            tab: .home
        ),
        TutorialStep(
            title: "Progrès & Records",
            message: "Suis ton poids, tes records personnels, ton 1RM estimé et ta progression vers ton objectif.",
            icon: "trophy.fill",
            tab: .records
        ),
        TutorialStep(
            title: "Historique",
            message: "Retrouve toutes tes séances passées. Appui long pour sauvegarder une séance comme programme.",
            icon: "clock.fill",
            tab: .history
        ),
        TutorialStep(
            title: "Réglages",
            message: "Change ton thème, configure tes rappels, gère tes sauvegardes et modifie ton objectif.",
            icon: "gearshape.fill",
            tab: .settings
        ),
        TutorialStep(
            title: "C'est parti !",
            message: "Tu es prêt. Lance ta première séance et commence à progresser !",
            icon: "flame.fill",
            tab: nil
        ),
    ]

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    advanceStep()
                }

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 50))
                        .foregroundStyle(theme.color.gradient)
                        .frame(height: 60)

                    // Title
                    Text(steps[currentStep].title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    // Message
                    Text(steps[currentStep].message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // Tab indicator
                    if let tab = steps[currentStep].tab {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text("Onglet \(tab.label)")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(theme.color.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.color.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    // Progress + button
                    VStack(spacing: 16) {
                        // Dots
                        HStack(spacing: 6) {
                            ForEach(0..<steps.count, id: \.self) { i in
                                Circle()
                                    .fill(i == currentStep ? theme.color.accent : Color.secondary.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }

                        HStack(spacing: 16) {
                            if currentStep > 0 {
                                Button("Passer") {
                                    dismiss()
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Button {
                                advanceStep()
                            } label: {
                                Text(currentStep == steps.count - 1 ? "C'est parti !" : "Suivant")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(theme.color.gradient)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(28)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }

    private func advanceStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}
