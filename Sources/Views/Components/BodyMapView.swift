import SwiftUI

/// Body map using AI-generated anatomical images with colored muscle overlays.
struct BodyMapView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
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
        VStack(spacing: 4) {
            ZStack {
                // Base body (shown when no muscles active for this view)
                Image(showBack ? "BodyBack" : "BodyFront")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                // Muscle overlays — darken keeps colored muscles visible through all layers
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

            // Flip indicator
            Button {
                showBack.toggle()
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
    }
}
