import SwiftUI

/// Body map using AI-generated anatomical images with colored muscle overlays.
struct BodyMapView: View {
    @Environment(ThemeManager.self) private var theme
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
        ZStack {
            // Base body image
            Image(showBack ? "BodyBack" : "BodyFront")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.85)

            // Colored overlays for active muscles
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                if showBack {
                    backOverlays(w: w, h: h)
                } else {
                    frontOverlays(w: w, h: h)
                }
            }

            // Tap to flip indicator
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 8))
                    Text(showBack ? "DOS" : "FACE")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.4)) {
                showBack.toggle()
            }
        }
        .onAppear { pulse = true }
    }

    // MARK: - Front Overlays

    @ViewBuilder
    private func frontOverlays(w: CGFloat, h: CGFloat) -> some View {
        // Shoulders (deltoids) — two circles at top of shoulders
        muscleSpot(.shoulders, x: w * 0.28, y: h * 0.2, size: w * 0.12)
        muscleSpot(.shoulders, x: w * 0.72, y: h * 0.2, size: w * 0.12)

        // Chest (pecs) — two ovals on upper torso
        muscleOval(.chest, x: w * 0.39, y: h * 0.24, width: w * 0.15, height: h * 0.06)
        muscleOval(.chest, x: w * 0.61, y: h * 0.24, width: w * 0.15, height: h * 0.06)

        // Arms (biceps) — two elongated shapes
        muscleRect(.arms, x: w * 0.2, y: h * 0.3, width: w * 0.08, height: h * 0.1)
        muscleRect(.arms, x: w * 0.8, y: h * 0.3, width: w * 0.08, height: h * 0.1)
        // Forearms
        muscleRect(.arms, x: w * 0.17, y: h * 0.42, width: w * 0.06, height: h * 0.09)
        muscleRect(.arms, x: w * 0.83, y: h * 0.42, width: w * 0.06, height: h * 0.09)

        // Core (abs) — center grid
        muscleRect(.core, x: w * 0.5, y: h * 0.35, width: w * 0.16, height: h * 0.12)

        // Legs (quads) — two shapes per leg
        muscleRect(.legs, x: w * 0.39, y: h * 0.58, width: w * 0.12, height: h * 0.14)
        muscleRect(.legs, x: w * 0.61, y: h * 0.58, width: w * 0.12, height: h * 0.14)
        // Calves
        muscleRect(.legs, x: w * 0.38, y: h * 0.78, width: w * 0.08, height: h * 0.1)
        muscleRect(.legs, x: w * 0.62, y: h * 0.78, width: w * 0.08, height: h * 0.1)
    }

    // MARK: - Back Overlays

    @ViewBuilder
    private func backOverlays(w: CGFloat, h: CGFloat) -> some View {
        // Shoulders (rear delts)
        muscleSpot(.shoulders, x: w * 0.28, y: h * 0.2, size: w * 0.12)
        muscleSpot(.shoulders, x: w * 0.72, y: h * 0.2, size: w * 0.12)

        // Back (traps + lats)
        muscleRect(.back, x: w * 0.5, y: h * 0.2, width: w * 0.2, height: h * 0.06)
        muscleRect(.back, x: w * 0.38, y: h * 0.3, width: w * 0.14, height: h * 0.12)
        muscleRect(.back, x: w * 0.62, y: h * 0.3, width: w * 0.14, height: h * 0.12)

        // Arms (triceps)
        muscleRect(.arms, x: w * 0.2, y: h * 0.3, width: w * 0.08, height: h * 0.1)
        muscleRect(.arms, x: w * 0.8, y: h * 0.3, width: w * 0.08, height: h * 0.1)

        // Core (lower back)
        muscleRect(.core, x: w * 0.5, y: h * 0.4, width: w * 0.16, height: h * 0.06)

        // Legs (hamstrings + glutes + calves)
        muscleRect(.legs, x: w * 0.39, y: h * 0.5, width: w * 0.12, height: h * 0.06)
        muscleRect(.legs, x: w * 0.61, y: h * 0.5, width: w * 0.12, height: h * 0.06)
        muscleRect(.legs, x: w * 0.39, y: h * 0.6, width: w * 0.11, height: h * 0.12)
        muscleRect(.legs, x: w * 0.61, y: h * 0.6, width: w * 0.11, height: h * 0.12)
        muscleRect(.legs, x: w * 0.38, y: h * 0.78, width: w * 0.08, height: h * 0.1)
        muscleRect(.legs, x: w * 0.62, y: h * 0.78, width: w * 0.08, height: h * 0.1)
    }

    // MARK: - Shape Helpers

    private func muscleSpot(_ group: MuscleGroup, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Circle()
            .fill(isActive(group) ? colorFor(group).opacity(0.45) : .clear)
            .frame(width: size, height: size)
            .blur(radius: size * 0.3)
            .shadow(color: isActive(group) ? colorFor(group).opacity(0.6) : .clear, radius: 8)
            .position(x: x, y: y)
            .animation(isActive(group) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
            .opacity(isActive(group) ? (pulse ? 0.8 : 1.0) : 0)
    }

    private func muscleOval(_ group: MuscleGroup, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        Ellipse()
            .fill(isActive(group) ? colorFor(group).opacity(0.45) : .clear)
            .frame(width: width, height: height)
            .blur(radius: min(width, height) * 0.3)
            .shadow(color: isActive(group) ? colorFor(group).opacity(0.6) : .clear, radius: 8)
            .position(x: x, y: y)
            .animation(isActive(group) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
            .opacity(isActive(group) ? (pulse ? 0.8 : 1.0) : 0)
    }

    private func muscleRect(_ group: MuscleGroup, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: min(width, height) * 0.3)
            .fill(isActive(group) ? colorFor(group).opacity(0.4) : .clear)
            .frame(width: width, height: height)
            .blur(radius: min(width, height) * 0.25)
            .shadow(color: isActive(group) ? colorFor(group).opacity(0.5) : .clear, radius: 6)
            .position(x: x, y: y)
            .animation(isActive(group) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
            .opacity(isActive(group) ? (pulse ? 0.8 : 1.0) : 0)
    }
}
