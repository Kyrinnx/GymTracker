import SwiftUI

// MARK: - Tutorial

struct TutorialOverlay: View {
    @Environment(ThemeManager.self) private var theme
    @Binding var isPresented: Bool
    @State private var currentStep = 0

    private struct Step {
        let title: String
        let message: String
        let icon: String
        /// Where the tooltip should appear vertically (0 = top, 1 = bottom)
        let position: Position

        enum Position {
            case top      // tooltip at top, pointing down
            case center   // tooltip centered
            case bottom   // tooltip at bottom, pointing up
        }
    }

    private let steps: [Step] = [
        Step(
            title: "Bienvenue dans GymTracker !",
            message: "On va te faire un rapide tour de l'app. Tape n'importe où ou sur \"Suivant\" pour continuer.",
            icon: "hand.wave.fill",
            position: .center
        ),
        Step(
            title: "Accueil",
            message: "C'est ton tableau de bord. Tu y trouves tes stats, tes programmes et tu peux lancer une séance.",
            icon: "house.fill",
            position: .bottom
        ),
        Step(
            title: "Séance libre",
            message: "Lance une séance sans programme défini. Tu ajoutes tes exercices au fur et à mesure.",
            icon: "bolt.fill",
            position: .center
        ),
        Step(
            title: "Tes programmes",
            message: "Crée tes propres programmes avec le \"+\". Appui long sur un programme pour le dupliquer, mettre en favori ou supprimer.",
            icon: "rectangle.stack.fill",
            position: .center
        ),
        Step(
            title: "Import IA",
            message: "Copie le prompt, envoie-le à ChatGPT ou Claude, puis colle le JSON pour importer tes séances automatiquement.",
            icon: "sparkles",
            position: .center
        ),
        Step(
            title: "Progrès & Records",
            message: "Suis ton poids, tes records personnels, ton 1RM estimé et ta progression vers ton objectif.",
            icon: "trophy.fill",
            position: .bottom
        ),
        Step(
            title: "Historique",
            message: "Retrouve toutes tes séances passées. Appui long sur une séance pour la sauvegarder comme programme.",
            icon: "clock.fill",
            position: .bottom
        ),
        Step(
            title: "Réglages",
            message: "Change ton thème, configure tes rappels, modifie ton objectif et gère tes sauvegardes iCloud.",
            icon: "gearshape.fill",
            position: .bottom
        ),
        Step(
            title: "C'est parti !",
            message: "Tu es prêt. Lance ta première séance et commence à progresser !",
            icon: "flame.fill",
            position: .center
        ),
    ]

    var body: some View {
        ZStack {
            // Full dark overlay
            Color.black.opacity(0.82)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            GeometryReader { geo in
                let step = steps[currentStep]

                VStack(spacing: 0) {
                    if step.position == .bottom || step.position == .center {
                        Spacer()
                    }

                    if step.position == .top {
                        Spacer().frame(height: geo.safeAreaInsets.top + 20)
                    }

                    // Card
                    VStack(spacing: 16) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(theme.color.accent.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: step.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(theme.color.gradient)
                        }

                        Text(step.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(step.message)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        // Progress dots
                        HStack(spacing: 6) {
                            ForEach(0..<steps.count, id: \.self) { i in
                                Capsule()
                                    .fill(i == currentStep ? theme.color.accent : Color.white.opacity(0.2))
                                    .frame(width: i == currentStep ? 20 : 6, height: 6)
                            }
                        }
                        .padding(.top, 4)

                        // Buttons
                        HStack(spacing: 20) {
                            if currentStep > 0 {
                                Button("Passer") { dismiss() }
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            Button {
                                advance()
                            } label: {
                                Text(currentStep == steps.count - 1 ? "C'est parti !" : "Suivant")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 11)
                                    .background(theme.color.gradient)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.4))
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.black.opacity(0.5))
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 28)

                    if step.position == .top || step.position == .center {
                        Spacer()
                    }

                    if step.position == .bottom {
                        // Tab bar hint
                        tabBarHint(geo: geo)
                    }
                }
            }

            // Step counter
            VStack {
                HStack {
                    Spacer()
                    Text("\(currentStep + 1)/\(steps.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .clipShape(Capsule())
                    .padding(.trailing, 20)
                }
                .padding(.top, 8)
                Spacer()
            }
        }
        .transition(.opacity)
    }

    // MARK: - Tab bar visual hint

    @ViewBuilder
    private func tabBarHint(geo: GeometryProxy) -> some View {
        let tabLabels = ["Accueil", "Records", "Historique", "Réglages"]
        let tabIcons = ["house.fill", "trophy.fill", "clock.fill", "gearshape.fill"]
        let step = steps[currentStep]
        let highlightIndex: Int? = {
            switch step.icon {
            case "trophy.fill": return 1
            case "clock.fill": return 2
            case "gearshape.fill": return 3
            case "house.fill": return 0
            default: return nil
            }
        }()

        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                VStack(spacing: 4) {
                    Image(systemName: tabIcons[i])
                        .font(.system(size: 20))
                    Text(tabLabels[i])
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(highlightIndex == i ? theme.color.accent : .white.opacity(0.3))
                .scaleEffect(highlightIndex == i ? 1.15 : 1.0)
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial.opacity(0.3))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Actions

    private func advance() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(duration: 0.35)) { currentStep += 1 }
        } else {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
    }
}
