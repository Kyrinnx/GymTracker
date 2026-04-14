import SwiftUI

/// Body map using AI-generated anatomical images with colored muscle overlays.
/// The PNGs have an integrated dark background — we frame them in a rounded
/// panel so the whole thing reads as an intentional dark card instead of a
/// hard rectangle dropped onto the parent surface.
struct BodyMapView: View {
    @Environment(ThemeManager.self) private var theme
    var activeGroups: [MuscleGroup]
    @State private var showBack = false

    private func overlayName(for group: MuscleGroup) -> String? {
        switch group {
        case .chest: showBack ? nil : "FrontChest"
        case .back:  showBack ? "BackBack" : nil
        case .shoulders: showBack ? "BackShoulders" : "FrontShoulders"
        case .arms:  showBack ? "BackArms" : "FrontArms"
        case .legs:  showBack ? "BackLegs" : "FrontLegs"
        case .core:  showBack ? "BackCore" : "FrontCore"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Unified dark panel that matches the PNG's integrated background.
            // Any aspect-ratio gap around the figure is filled seamlessly.
            Color(white: 0.10)

            // Body image + active muscle overlays
            ZStack {
                Image(showBack ? "BodyBack" : "BodyFront")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                ForEach(activeGroups, id: \.self) { group in
                    if let name = overlayName(for: group) {
                        Image(name)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .blendMode(.darken)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: activeGroups)
            .animation(.spring(duration: 0.4), value: showBack)

            // Flip indicator — floats over the feet of the figure
            Button {
                withAnimation(.spring(duration: 0.4)) { showBack.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(showBack ? "DOS" : "FACE")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.5)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        // Force the dark variant of the PNG assets (body_front_dark, etc.)
        // so the body map keeps its stylised dark-panel look regardless of
        // whether the rest of the app is in light or dark mode.
        .environment(\.colorScheme, .dark)
    }
}
