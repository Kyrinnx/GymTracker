import SwiftUI
import SwiftData

struct FastingView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \FastingSession.startDate, order: .reverse) private var allSessions: [FastingSession]

    @AppStorage("fastingMethod") private var savedMethod: String = FastingMethod.sixteen8.rawValue

    @State private var now: Date = Date()
    @State private var showMethodPicker = false
    @State private var showEditStart = false
    @State private var showEditEnd = false
    @State private var editedStart: Date = Date()
    @State private var editedEnd: Date = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentMethod: FastingMethod {
        FastingMethod(rawValue: savedMethod) ?? .sixteen8
    }

    private var activeSession: FastingSession? {
        allSessions.first { $0.isActive }
    }

    private var pastSessions: [FastingSession] {
        allSessions.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let active = activeSession {
                        activeFastCard(active)
                        stagesTimeline(active)
                    } else {
                        idleCard
                    }
                    methodsSection
                    if !pastSessions.isEmpty {
                        historySection
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onReceive(timer) { now = $0 }
            .sheet(isPresented: $showMethodPicker) {
                MethodPickerSheet(selected: currentMethod) { method in
                    savedMethod = method.rawValue
                    showMethodPicker = false
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showEditStart) {
                editDateSheet(title: "Début du jeûne", date: $editedStart) {
                    if let active = activeSession {
                        active.startDate = editedStart
                        active.plannedEndDate = Calendar.current.date(
                            byAdding: .hour,
                            value: active.method.hours,
                            to: editedStart
                        ) ?? active.plannedEndDate
                    }
                    showEditStart = false
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showEditEnd) {
                editDateSheet(title: "Fin du jeûne", date: $editedEnd) {
                    if let active = activeSession {
                        active.plannedEndDate = editedEnd
                    }
                    showEditEnd = false
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Jeûne intermittent")
                .font(.system(size: 32, weight: .black))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text("Si tu ne changes rien, rien ne changera. ⚡️")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Idle (no active fast)

    private var idleCard: some View {
        VStack(spacing: 18) {
            Text(currentMethod.emoji)
                .font(.system(size: 60))

            VStack(spacing: 4) {
                Text("Prêt à jeûner")
                    .font(.title3.bold())
                Text(currentMethod.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button { startFast() } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Commencer un jeûne \(currentMethod.label)")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.color.gradient)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    // MARK: - Active fast

    private func activeFastCard(_ session: FastingSession) -> some View {
        let progress = session.progress
        let inEatingWindow = progress >= 1.0
        let bigTimerText = inEatingWindow
            ? formatDuration(Date().timeIntervalSince(session.plannedEndDate))
            : formatDuration(session.remaining)

        return VStack(spacing: 20) {
            // Title
            Text(inEatingWindow ? "Fenêtre alimentaire ouverte ! 🎉" : "Tu jeûnes...")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(inEatingWindow ? .green : .primary)

            // Progress ring with mascot
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 12)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.color.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6), value: progress)

                // End indicator dot
                Circle()
                    .fill(theme.color.accent)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: progress >= 1 ? "checkmark" : "moon.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(y: -100)
                    .rotationEffect(.degrees(360 * progress))
                    .shadow(color: theme.color.accent.opacity(0.6), radius: 6)

                // Mascot in center
                Text(session.method.emoji)
                    .font(.system(size: 56))
            }

            // Big timer
            Text(bigTimerText)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(inEatingWindow ? .green : .primary)

            // Stop button
            Button {
                stopFast()
            } label: {
                HStack {
                    Image(systemName: "stop.circle.fill")
                    Text("Arrêter le jeûne")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.pink.gradient)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Edit start / end
            HStack(spacing: 12) {
                editTimeBox(
                    label: "Commencé",
                    value: relativeDateString(session.startDate),
                    fullDate: session.startDate
                ) {
                    editedStart = session.startDate
                    showEditStart = true
                }
                editTimeBox(
                    label: "Se termine",
                    value: relativeDateString(session.plannedEndDate),
                    fullDate: session.plannedEndDate
                ) {
                    editedEnd = session.plannedEndDate
                    showEditEnd = true
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private func editTimeBox(label: String, value: String, fullDate: Date, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(label.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(fullDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("Éditer", systemImage: "pencil")
                    .font(.caption2)
                    .foregroundStyle(theme.color.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.color.accent.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stages timeline

    private func stagesTimeline(_ session: FastingSession) -> some View {
        let current = session.currentStage
        return VStack(alignment: .leading, spacing: 10) {
            Text("ÉTAPES")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.5)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FastingStage.allCases) { stage in
                        stageBubble(stage, current: current, elapsedHours: session.elapsedHours)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func stageBubble(_ stage: FastingStage, current: FastingStage, elapsedHours: Double) -> some View {
        let isActive = stage == current
        let isPassed = stage.rawValue < current.rawValue
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? theme.color.accent : (isPassed ? theme.color.accent.opacity(0.5) : Color.secondary.opacity(0.15)))
                    .frame(width: 50, height: 50)
                Image(systemName: stage.icon)
                    .font(.title3)
                    .foregroundStyle(isActive || isPassed ? .white : .secondary)
            }
            Text(stage.label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(isActive ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("\(stage.rawValue)h")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(isActive ? theme.color.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Methods grid

    private var methodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Méthodes")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(columns: [.init(.flexible(), spacing: 12), .init(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(FastingMethod.allCases) { method in
                    methodCard(method)
                }
            }
            .padding(.horizontal)
        }
    }

    private func methodCard(_ method: FastingMethod) -> some View {
        let isSelected = method == currentMethod
        return Button {
            savedMethod = method.rawValue
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(method.emoji)
                        .font(.title2)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.color.accent)
                    }
                }
                Text(method.label)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(method.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? AnyShapeStyle(theme.color.accent.opacity(0.12)) : AnyShapeStyle(.regularMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isSelected ? theme.color.accent : .clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(pastSessions.prefix(10)) { session in
                    historyRow(session)
                }
            }
            .padding(.horizontal)
        }
    }

    private func historyRow(_ session: FastingSession) -> some View {
        let actualEnd = session.actualEndDate ?? session.plannedEndDate
        let duration = actualEnd.timeIntervalSince(session.startDate)
        let achievedPct = min(100, Int((duration / session.totalDuration) * 100))
        return HStack(spacing: 14) {
            Text(session.method.emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(theme.color.accent.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.subheadline.bold())
                Text("\(session.method.label) · \(formatHours(duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(achievedPct)%")
                .font(.subheadline.bold())
                .foregroundStyle(achievedPct >= 100 ? .green : theme.color.accent)
            Button {
                context.delete(session)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Edit date sheet

    private func editDateSheet(title: String, date: Binding<Date>, onSave: @escaping () -> Void) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("", selection: date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                Button {
                    onSave()
                } label: {
                    Text("Enregistrer")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.color.gradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Actions

    private func startFast() {
        let session = FastingSession(method: currentMethod, startDate: Date())
        context.insert(session)
    }

    private func stopFast() {
        guard let active = activeSession else { return }
        active.actualEndDate = Date()
    }

    // MARK: - Formatting

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(abs(seconds))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d : %02d : %02d", h, m, sec)
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return "\(h)h\(String(format: "%02d", m))"
    }

    private func relativeDateString(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Aujourd'hui" }
        if cal.isDateInYesterday(date) { return "Hier" }
        if cal.isDateInTomorrow(date) { return "Demain" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - Method picker sheet

private struct MethodPickerSheet: View {
    @Environment(ThemeManager.self) private var theme
    let selected: FastingMethod
    let onSelect: (FastingMethod) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [.init(.flexible(), spacing: 12), .init(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(FastingMethod.allCases) { method in
                        methodButton(method)
                    }
                }
                .padding()
            }
            .navigationTitle("Choisir une méthode")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func methodButton(_ method: FastingMethod) -> some View {
        let isSelected = method == selected
        return Button {
            onSelect(method)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(method.emoji)
                    .font(.title)
                Text(method.label)
                    .font(.headline.bold())
                Text(method.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isSelected ? AnyShapeStyle(theme.color.accent.opacity(0.15)) : AnyShapeStyle(.regularMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isSelected ? theme.color.accent : .clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
