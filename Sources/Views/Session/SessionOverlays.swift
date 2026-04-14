import SwiftUI

// MARK: - Rest Overlay

struct SessionRestOverlay: View {
    @Environment(ThemeManager.self) private var theme
    let remaining: Int
    let total: Int
    let onDismiss: () -> Void

    private var formattedRest: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%d:%02d", m, s)
    }

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(remaining) / CGFloat(total)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text("REPOS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 8)
                        .frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(theme.color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: remaining)
                    VStack(spacing: 4) {
                        Text(formattedRest)
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .monospacedDigit()
                        Text("/ \(total)s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Passer")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(theme.color.gradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
    }
}

// MARK: - XP Overlay

struct SessionXPOverlay: View {
    @Environment(ThemeManager.self) private var theme
    let breakdown: XPBreakdown
    let totalXP: Int
    let onContinue: () -> Void

    var body: some View {
        let rank = Rank.from(xp: totalXP)
        return ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Mascot: GIF for high ranks, icon for others
                let isHighTier = [Rank.elite, .legende, .titan, .mythique].contains(rank)
                if isHighTier {
                    GIFView(name: rank.mascot)
                        .frame(width: 60, height: 60)
                        .clipped()
                } else {
                    Image(systemName: rank.icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [theme.color.accent, rank.color == .gray ? theme.color.accent.opacity(0.7) : rank.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: theme.color.accent.opacity(0.4), radius: 8, y: 4)
                }

                Text(rank.label)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(.white)

                // XP breakdown
                VStack(spacing: 6) {
                    ForEach(breakdown.details, id: \.label) { detail in
                        HStack(spacing: 8) {
                            Image(systemName: detail.icon)
                                .font(.caption)
                                .foregroundStyle(theme.color.accent)
                                .frame(width: 20)
                            Text(detail.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("+\(detail.value)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                    }
                    Divider().padding(.vertical, 2)
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("+\(breakdown.total) XP")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundStyle(theme.color.accent)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("\(totalXP) XP au total")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    onContinue()
                } label: {
                    Text("Continuer")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Drag & Drop Delegate

struct ExerciseDropDelegate: DropDelegate {
    let target: ExerciseEntry
    @Binding var dragged: ExerciseEntry?
    let session: WorkoutSession

    func dropEntered(info: DropInfo) {
        guard let dragged = dragged, dragged !== target else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            let fromOrder = dragged.order
            let toOrder = target.order
            // Shift all exercises between the two positions
            let sorted = session.exercisesArray.sorted { $0.order < $1.order }
            for ex in sorted {
                if fromOrder < toOrder {
                    if ex.order > fromOrder && ex.order <= toOrder { ex.order -= 1 }
                } else {
                    if ex.order >= toOrder && ex.order < fromOrder { ex.order += 1 }
                }
            }
            dragged.order = toOrder
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        dragged = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        // Safety: reset if drag leaves all targets
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
    }
}
