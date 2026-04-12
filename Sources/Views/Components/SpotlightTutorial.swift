import SwiftUI

// MARK: - Spotlight Preference Key

struct SpotlightItem: Equatable {
    let key: String
    let frame: CGRect
}

struct SpotlightPreferenceKey: PreferenceKey {
    static var defaultValue: [SpotlightItem] = []
    static func reduce(value: inout [SpotlightItem], nextValue: () -> [SpotlightItem]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    func spotlightTag(_ key: String) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SpotlightPreferenceKey.self,
                    value: [SpotlightItem(key: key, frame: geo.frame(in: .global))]
                )
            }
        )
    }
}

// MARK: - Tutorial Step

struct TutorialStep {
    let spotlightKey: String
    let title: String
    let message: String
    let icon: String
    let arrowEdge: Edge
}

// MARK: - Spotlight Tutorial Overlay

struct SpotlightTutorial: View {
    @Environment(ThemeManager.self) private var theme
    @Binding var isPresented: Bool
    let spotlightFrames: [SpotlightItem]

    @State private var currentStep = 0
    @State private var opacity: Double = 0

    static let steps: [TutorialStep] = [
        TutorialStep(
            spotlightKey: "tab_home",
            title: "Accueil",
            message: "Ton tableau de bord : lance une séance, gère tes programmes et suis ton corps.",
            icon: "house.fill",
            arrowEdge: .bottom
        ),
        TutorialStep(
            spotlightKey: "free_session",
            title: "Séance libre",
            message: "Lance une séance sans programme. Tu ajoutes tes exercices au fur et à mesure.",
            icon: "bolt.fill",
            arrowEdge: .top
        ),
        TutorialStep(
            spotlightKey: "my_sessions",
            title: "Tes programmes",
            message: "Crée tes propres programmes avec le \"+\". Appui long pour dupliquer, mettre en favori ou supprimer.",
            icon: "rectangle.stack.fill",
            arrowEdge: .top
        ),
        TutorialStep(
            spotlightKey: "ai_import",
            title: "Import IA",
            message: "Copie le prompt, envoie-le à ChatGPT ou Claude, et colle le résultat pour importer tes séances.",
            icon: "sparkles",
            arrowEdge: .top
        ),
        TutorialStep(
            spotlightKey: "tab_records",
            title: "Progrès",
            message: "Suis ton poids, tes records personnels, ton 1RM et ta progression vers ton objectif.",
            icon: "trophy.fill",
            arrowEdge: .bottom
        ),
        TutorialStep(
            spotlightKey: "tab_history",
            title: "Historique",
            message: "Retrouve toutes tes séances. Appui long pour sauvegarder une séance comme programme.",
            icon: "clock.fill",
            arrowEdge: .bottom
        ),
        TutorialStep(
            spotlightKey: "tab_settings",
            title: "Réglages",
            message: "Thème, rappels, objectif, sauvegardes iCloud — tout se configure ici.",
            icon: "gearshape.fill",
            arrowEdge: .bottom
        ),
    ]

    private var step: TutorialStep { Self.steps[currentStep] }

    private var spotlightFrame: CGRect? {
        spotlightFrames.first { $0.key == step.spotlightKey }?.frame
    }

    var body: some View {
        ZStack {
            // Dark overlay with cutout
            SpotlightCutout(highlight: spotlightFrame ?? .zero)
                .fill(style: FillStyle(eoFill: true))
                .foregroundStyle(.black.opacity(0.75))
                .ignoresSafeArea()
                .onTapGesture {
                    advanceStep()
                }

            // Spotlight ring
            if let frame = spotlightFrame {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(theme.color.accent, lineWidth: 2)
                    .frame(width: frame.width + 12, height: frame.height + 12)
                    .position(x: frame.midX, y: frame.midY)
            }

            // Tooltip card
            tooltipCard
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1 }
        }
    }

    private var tooltipCard: some View {
        GeometryReader { geo in
            let frame = spotlightFrame ?? CGRect(x: geo.size.width / 2, y: geo.size.height / 2, width: 0, height: 0)
            let cardWidth: CGFloat = min(geo.size.width - 48, 320)
            let above = step.arrowEdge == .bottom || frame.minY > geo.size.height * 0.5
            let cardY = above
                ? frame.minY - 16
                : frame.maxY + 16

            VStack(spacing: 12) {
                if !above {
                    // Arrow pointing up
                    triangle
                        .frame(width: 16, height: 8)
                        .foregroundStyle(Color(.systemBackground))
                }

                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: step.icon)
                            .font(.title3)
                            .foregroundStyle(theme.color.accent)
                        Text(step.title)
                            .font(.headline)
                    }

                    Text(step.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // Progress + buttons
                    HStack(spacing: 6) {
                        ForEach(0..<Self.steps.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentStep ? theme.color.accent : Color.secondary.opacity(0.3))
                                .frame(width: 5, height: 5)
                        }
                    }

                    HStack(spacing: 16) {
                        Button("Passer") { dismiss() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            advanceStep()
                        } label: {
                            Text(currentStep == Self.steps.count - 1 ? "C'est parti !" : "Suivant")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(theme.color.gradient)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 20)

                if above {
                    triangle
                        .rotationEffect(.degrees(180))
                        .frame(width: 16, height: 8)
                        .foregroundStyle(Color(.systemBackground))
                }
            }
            .frame(width: cardWidth)
            .position(
                x: min(max(frame.midX, cardWidth / 2 + 24), geo.size.width - cardWidth / 2 - 24),
                y: above ? cardY - 80 : cardY + 80
            )
        }
    }

    private var triangle: some View {
        Triangle()
    }

    private func advanceStep() {
        if currentStep < Self.steps.count - 1 {
            withAnimation(.spring(duration: 0.35)) { currentStep += 1 }
        } else {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isPresented = false }
    }
}

// MARK: - Shapes

private struct SpotlightCutout: Shape {
    var highlight: CGRect
    var animatableData: CGRect.AnimatableData {
        get { highlight.animatableData }
        set { highlight.animatableData = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        let inset = highlight.insetBy(dx: -6, dy: -6)
        path.addRoundedRect(in: inset, cornerSize: CGSize(width: 14, height: 14))
        return path
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
