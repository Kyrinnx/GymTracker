import SwiftUI

// MARK: - Anchor Preference Key

struct SpotlightBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func tutorialTag(_ key: String) -> some View {
        self.anchorPreference(key: SpotlightBoundsKey.self, value: .bounds) { [key: $0] }
    }
}

// MARK: - Tutorial Step

private struct TutorialStep {
    let key: String       // matches tutorialTag or "tab_X"
    let title: String
    let message: String
    let icon: String
}

// MARK: - Tutorial Overlay

struct TutorialOverlay: View {
    @Environment(ThemeManager.self) private var theme
    @Binding var isPresented: Bool
    let anchors: [String: Anchor<CGRect>]

    @State private var currentStep = 0

    private let steps: [TutorialStep] = [
        TutorialStep(key: "_welcome", title: "Bienvenue !", message: "Petit tour rapide de l'app. Tape \"Suivant\" pour continuer.", icon: "hand.wave.fill"),
        TutorialStep(key: "tab_home", title: "Accueil", message: "Ton tableau de bord : stats, programmes et lancement de séance.", icon: "house.fill"),
        TutorialStep(key: "free_session", title: "Séance libre", message: "Lance une séance sans programme. Tu ajoutes tes exercices au fur et à mesure.", icon: "bolt.fill"),
        TutorialStep(key: "my_sessions", title: "Tes programmes", message: "Crée tes programmes avec le \"+\". Appui long pour dupliquer, favori ou supprimer.", icon: "rectangle.stack.fill"),
        TutorialStep(key: "ai_import", title: "Import IA", message: "Copie le prompt, envoie-le à ChatGPT ou Claude, colle le JSON pour importer.", icon: "sparkles"),
        TutorialStep(key: "tab_records", title: "Progrès", message: "Suis ton poids, records, 1RM et progression vers ton objectif.", icon: "trophy.fill"),
        TutorialStep(key: "tab_history", title: "Historique", message: "Toutes tes séances. Appui long pour sauvegarder comme programme.", icon: "clock.fill"),
        TutorialStep(key: "tab_settings", title: "Réglages", message: "Thème, rappels, objectif et sauvegardes iCloud.", icon: "gearshape.fill"),
        TutorialStep(key: "_end", title: "C'est parti !", message: "Lance ta première séance et commence à progresser !", icon: "flame.fill"),
    ]

    private var step: TutorialStep { steps[currentStep] }

    var body: some View {
        GeometryReader { proxy in
            let highlight = resolvedRect(in: proxy)

            ZStack {
                // Dark overlay with cutout hole
                cutoutOverlay(highlight: highlight)
                    .ignoresSafeArea()
                    .onTapGesture { advance() }

                // Highlight border
                if let r = highlight {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(theme.color.accent, lineWidth: 2.5)
                        .frame(width: r.width + 16, height: r.height + 16)
                        .position(x: r.midX, y: r.midY)
                        .shadow(color: theme.color.accent.opacity(0.4), radius: 10)
                }

                // Tooltip
                tooltip(screenSize: proxy.size, safeArea: proxy.safeAreaInsets, highlight: highlight)
            }
        }
        .transition(.opacity)
        .animation(.spring(duration: 0.35), value: currentStep)
    }

    // MARK: - Resolve highlight rect

    private func resolvedRect(in proxy: GeometryProxy) -> CGRect? {
        let key = step.key
        // Tab bar items — compute position from screen geometry
        if key.hasPrefix("tab_") {
            let tabIndex: Int? = switch key {
            case "tab_home": 0
            case "tab_records": 1
            case "tab_history": 2
            case "tab_settings": 3
            default: nil
            }
            guard let idx = tabIndex else { return nil }
            let tabWidth = proxy.size.width / 4
            let tabBarHeight: CGFloat = 49
            let y = proxy.size.height - proxy.safeAreaInsets.bottom - tabBarHeight / 2
            return CGRect(
                x: tabWidth * CGFloat(idx) + tabWidth * 0.15,
                y: y - tabBarHeight * 0.3,
                width: tabWidth * 0.7,
                height: tabBarHeight * 0.8
            )
        }
        // Regular anchored elements
        if let anchor = anchors[key] {
            return proxy[anchor]
        }
        return nil
    }

    // MARK: - Cutout overlay

    private func cutoutOverlay(highlight: CGRect?) -> some View {
        Canvas { context, size in
            // Full dark rect
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.78)))

            // Cut hole if we have a highlight
            if let r = highlight {
                let hole = r.insetBy(dx: -8, dy: -8)
                let holePath = Path(roundedRect: hole, cornerRadius: 12)
                context.blendMode = .clear
                context.fill(holePath, with: .color(.white))
            }
        }
        .compositingGroup()
    }

    // MARK: - Tooltip card

    private func tooltip(screenSize: CGSize, safeArea: EdgeInsets, highlight: CGRect?) -> some View {
        let cardWidth = min(screenSize.width - 48, 320)

        // Determine if card should go above or below the highlight
        let showAbove: Bool
        let cardY: CGFloat

        if let r = highlight {
            let spaceAbove = r.minY - safeArea.top
            let spaceBelow = screenSize.height - r.maxY - safeArea.bottom
            showAbove = spaceAbove > spaceBelow
            cardY = showAbove ? r.minY - 20 : r.maxY + 20
        } else {
            // No highlight — center vertically
            showAbove = false
            cardY = screenSize.height * 0.45
        }

        return VStack(spacing: 14) {
            // Arrow pointing to highlight
            if highlight != nil && !showAbove {
                triangle(pointing: .up)
                    .frame(width: 18, height: 9)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
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

                // Dots
                HStack(spacing: 5) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentStep ? theme.color.accent : Color.secondary.opacity(0.25))
                            .frame(width: i == currentStep ? 18 : 5, height: 5)
                    }
                }

                // Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Passer") { dismiss() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        advance()
                    } label: {
                        Text(currentStep == steps.count - 1 ? "C'est parti !" : "Suivant")
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
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 16)

            if highlight != nil && showAbove {
                triangle(pointing: .down)
                    .frame(width: 18, height: 9)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
        .frame(width: cardWidth)
        .position(
            x: screenSize.width / 2,
            y: highlight != nil ? (showAbove ? cardY - 100 : cardY + 100) : cardY
        )
    }

    // MARK: - Helpers

    enum ArrowDirection { case up, down }

    private func triangle(pointing: ArrowDirection) -> some View {
        Triangle(pointing: pointing)
    }

    private func advance() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(duration: 0.35)) { currentStep += 1 }
        } else {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    let pointing: TutorialOverlay.ArrowDirection

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch pointing {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .down:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}
