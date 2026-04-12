import SwiftUI

/// Body map using AI-generated anatomical images with colored muscle overlays.
struct BodyMapView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    var activeGroups: [MuscleGroup]
    @State private var showBack = false
    @State private var pulse = false

    private func colorFor(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: Color(red: 1.0, green: 0.36, blue: 0.30)
        case .back: Color(red: 0.20, green: 0.78, blue: 0.70)
        case .shoulders: Color(red: 0.30, green: 0.55, blue: 1.0)
        case .arms: Color(red: 1.0, green: 0.78, blue: 0.20)
        case .legs: Color(red: 0.65, green: 0.35, blue: 0.95)
        case .core: Color(red: 1.0, green: 0.46, blue: 0.66)
        }
    }

    private func isActive(_ group: MuscleGroup) -> Bool {
        activeGroups.contains(group)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Body image
                bodyImage

                // Colored glow overlays
                overlayCanvas
            }

            // Flip indicator
            Button {
                withAnimation(.spring(duration: 0.4)) { showBack.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 7))
                    Text(showBack ? "DOS" : "FACE")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .onAppear { pulse = true }
    }

    private var bodyImage: some View {
        Image(showBack ? "BodyBack" : "BodyFront")
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .brightness(colorScheme == .light ? -0.5 : 0)
            .opacity(0.9)
    }

    private var overlayCanvas: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let spots: [(MuscleGroup, CGFloat, CGFloat, CGFloat)] = showBack ? [
                // Back view
                (.shoulders, 0.28, 0.2, w * 0.08),
                (.shoulders, 0.72, 0.2, w * 0.08),
                (.back, 0.38, 0.28, w * 0.09),
                (.back, 0.62, 0.28, w * 0.09),
                (.back, 0.5, 0.2, w * 0.07),
                (.arms, 0.2, 0.3, w * 0.06),
                (.arms, 0.8, 0.3, w * 0.06),
                (.core, 0.5, 0.4, w * 0.08),
                (.legs, 0.39, 0.55, w * 0.07),
                (.legs, 0.61, 0.55, w * 0.07),
                (.legs, 0.39, 0.72, w * 0.06),
                (.legs, 0.61, 0.72, w * 0.06),
            ] : [
                // Front view
                (.shoulders, 0.3, 0.19, w * 0.08),
                (.shoulders, 0.7, 0.19, w * 0.08),
                (.chest, 0.4, 0.24, w * 0.09),
                (.chest, 0.6, 0.24, w * 0.09),
                (.arms, 0.2, 0.3, w * 0.06),
                (.arms, 0.8, 0.3, w * 0.06),
                (.arms, 0.17, 0.42, w * 0.05),
                (.arms, 0.83, 0.42, w * 0.05),
                (.core, 0.5, 0.35, w * 0.08),
                (.legs, 0.39, 0.57, w * 0.07),
                (.legs, 0.61, 0.57, w * 0.07),
                (.legs, 0.38, 0.76, w * 0.05),
                (.legs, 0.62, 0.76, w * 0.05),
            ]

            for (group, xFrac, yFrac, radius) in spots where isActive(group) {
                let center = CGPoint(x: w * xFrac, y: h * yFrac)
                let color = colorFor(group)
                let ellipse = Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(ellipse, with: .color(color.opacity(0.5)))
            }
        }
        .allowsHitTesting(false)
        .animation(isActive(.chest) || isActive(.back) || isActive(.legs) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }
}
