import SwiftUI

/// Stylised front-view body map. Muscle groups light up when listed in `activeGroups`.
struct BodyMapView: View {
    @Environment(ThemeManager.self) private var theme
    var activeGroups: [MuscleGroup]
    @State private var pulse = false

    private func colorFor(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: Color(red: 1.0, green: 0.36, blue: 0.30)       // red
        case .back: Color(red: 0.20, green: 0.78, blue: 0.70)       // teal
        case .shoulders: Color(red: 0.30, green: 0.55, blue: 1.0)   // blue
        case .arms: Color(red: 1.0, green: 0.78, blue: 0.20)        // gold
        case .legs: Color(red: 0.65, green: 0.35, blue: 0.95)       // purple
        case .core: Color(red: 1.0, green: 0.46, blue: 0.66)        // pink
        }
    }

    private func isActive(_ group: MuscleGroup) -> Bool {
        activeGroups.contains(group)
    }

    /// Idle muscles use a soft tinted version of the theme accent so the figure
    /// always looks alive (no flat dead-gray).
    private func fillColor(_ group: MuscleGroup) -> Color {
        isActive(group) ? colorFor(group) : theme.color.accent.opacity(0.18)
    }

    private func glowFor(_ group: MuscleGroup) -> Color {
        isActive(group) ? colorFor(group).opacity(0.65) : .clear
    }

    var body: some View {
        ZStack {
            // Body silhouette behind everything (very faint)
            silhouette

            headShape
            neckShape
            shoulderShape
            chestShape
            backIndicatorShape
            coreShape
            leftArmShape
            rightArmShape
            leftLegShape
            rightLegShape
        }
        .frame(width: 140, height: 220)
        .onAppear { pulse = true }
    }

    // MARK: - Background silhouette

    private var silhouette: some View {
        ZStack {
            // Torso
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.color.accent.opacity(0.06))
                .frame(width: 70, height: 80)
                .offset(y: -22)
            // Hips
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color.accent.opacity(0.06))
                .frame(width: 60, height: 22)
                .offset(y: 18)
        }
    }

    // MARK: - Head
    private var headShape: some View {
        Ellipse()
            .fill(theme.color.accent.opacity(0.18))
            .frame(width: 30, height: 36)
            .offset(y: -90)
    }

    // MARK: - Neck
    private var neckShape: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(theme.color.accent.opacity(0.15))
            .frame(width: 14, height: 12)
            .offset(y: -68)
    }

    // MARK: - Shoulders (deltoids)
    private var shoulderShape: some View {
        HStack(spacing: 42) {
            deltoid
            deltoid
        }
        .offset(y: -54)
        .animation(isActive(.shoulders) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var deltoid: some View {
        Circle()
            .fill(fillColor(.shoulders))
            .frame(width: 22, height: 22)
            .shadow(color: glowFor(.shoulders), radius: 8)
            .opacity(isActive(.shoulders) ? (pulse ? 0.85 : 1.0) : 1.0)
    }

    // MARK: - Chest (pecs as 2 rounded squares)
    private var chestShape: some View {
        HStack(spacing: 4) {
            pec
            pec
        }
        .offset(y: -42)
        .animation(isActive(.chest) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var pec: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(fillColor(.chest))
            .frame(width: 24, height: 22)
            .shadow(color: glowFor(.chest), radius: 8)
            .opacity(isActive(.chest) ? (pulse ? 0.85 : 1.0) : 1.0)
    }

    // MARK: - Back (lat indicator)
    private var backIndicatorShape: some View {
        // Two thin rounded shapes flanking the torso to suggest lats
        HStack(spacing: 50) {
            lat
            lat
        }
        .offset(y: -30)
        .animation(isActive(.back) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var lat: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(fillColor(.back))
            .frame(width: 6, height: 30)
            .shadow(color: glowFor(.back), radius: 6)
            .opacity(isActive(.back) ? (pulse ? 0.85 : 1.0) : 1.0)
    }

    // MARK: - Core (4 abs blocks)
    private var coreShape: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                abBlock
                abBlock
            }
            HStack(spacing: 3) {
                abBlock
                abBlock
            }
        }
        .offset(y: -10)
        .animation(isActive(.core) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var abBlock: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(fillColor(.core))
            .frame(width: 16, height: 10)
            .shadow(color: glowFor(.core), radius: 5)
            .opacity(isActive(.core) ? (pulse ? 0.85 : 1.0) : 1.0)
    }

    // MARK: - Arms
    private var leftArmShape: some View {
        armColumn
            .offset(x: -42, y: -28)
            .animation(isActive(.arms) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var rightArmShape: some View {
        armColumn
            .offset(x: 42, y: -28)
            .animation(isActive(.arms) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var armColumn: some View {
        VStack(spacing: 3) {
            // Bicep
            RoundedRectangle(cornerRadius: 6)
                .fill(fillColor(.arms))
                .frame(width: 16, height: 28)
            // Forearm
            RoundedRectangle(cornerRadius: 5)
                .fill(fillColor(.arms).opacity(0.7))
                .frame(width: 13, height: 24)
        }
        .shadow(color: glowFor(.arms), radius: 6)
        .opacity(isActive(.arms) ? (pulse ? 0.85 : 1.0) : 1.0)
    }

    // MARK: - Legs
    private var leftLegShape: some View {
        legColumn
            .offset(x: -16, y: 50)
            .animation(isActive(.legs) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var rightLegShape: some View {
        legColumn
            .offset(x: 16, y: 50)
            .animation(isActive(.legs) ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: pulse)
    }

    private var legColumn: some View {
        VStack(spacing: 3) {
            // Thigh
            RoundedRectangle(cornerRadius: 7)
                .fill(fillColor(.legs))
                .frame(width: 22, height: 40)
            // Calf
            RoundedRectangle(cornerRadius: 6)
                .fill(fillColor(.legs).opacity(0.75))
                .frame(width: 17, height: 32)
        }
        .shadow(color: glowFor(.legs), radius: 8)
        .opacity(isActive(.legs) ? (pulse ? 0.85 : 1.0) : 1.0)
    }
}
