import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.started, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var exerciseInfos: [ExerciseInfo]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]

    @AppStorage("userGoal") private var userGoalRaw: String = ""
    @AppStorage("targetWeight") private var targetWeight: Double = 0
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4
    @State private var selectedExerciseName: String?
    @State private var weightInput: String = ""
    @State private var bfInput: String = ""

    private var lastWeight: WeightEntry? { weights.first }
    private var userGoal: FitnessGoal? { FitnessGoal(rawValue: userGoalRaw) }

    fileprivate struct PRRow: Identifiable {
        var id: String { name }
        let name: String
        let group: MuscleGroup
        let bestKg: Double
        let oneRM: Double
        let lastDate: Date?
    }

    /// Computes best PR + 1RM per exercise across all finished sessions.
    fileprivate var prRows: [PRRow] {
        var bestKg: [String: Double] = [:]
        var bestOneRM: [String: Double] = [:]
        var lastDate: [String: Date] = [:]
        var groupByName: [String: MuscleGroup] = [:]

        for session in sessions {
            guard session.finished != nil else { continue }
            for exercise in session.exercisesArray {
                groupByName[exercise.name] = exercise.group
                for s in exercise.setsArray where s.done && s.kg > 0 {
                    bestKg[exercise.name] = max(bestKg[exercise.name] ?? 0, s.kg)
                    bestOneRM[exercise.name] = max(bestOneRM[exercise.name] ?? 0, s.estimatedOneRM)
                    let current = lastDate[exercise.name] ?? .distantPast
                    if session.started > current {
                        lastDate[exercise.name] = session.started
                    }
                }
            }
        }

        return bestKg.keys.compactMap { name -> PRRow? in
            guard let kg = bestKg[name], let group = groupByName[name] else { return nil }
            return PRRow(
                name: name,
                group: group,
                bestKg: kg,
                oneRM: bestOneRM[name] ?? 0,
                lastDate: lastDate[name]
            )
        }
        .sorted { $0.oneRM > $1.oneRM }
    }

    private var bestEverOneRM: Double { prRows.first?.oneRM ?? 0 }
    private var totalVolumeAllTime: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards
                    if userGoal != nil {
                        goalTrackingSection
                    }
                    weeklyProgressSection
                    weightSection
                    if weights.count >= 2 {
                        weightChart
                    }
                    if weights.contains(where: { $0.bodyFat != nil }),
                       weights.filter({ $0.bodyFat != nil }).count >= 2 {
                        bfChart
                    }
                    Text("RECORDS PERSONNELS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    if !prRows.isEmpty {
                        prList
                    } else {
                        emptyState
                    }
                }
                .padding(.bottom, 80)
            }
            .navigationTitle("Stats")
            .sheet(item: Binding(
                get: { selectedExerciseName.map { ExerciseNameWrapper(name: $0) } },
                set: { selectedExerciseName = $0?.name }
            )) { wrapper in
                if let row = prRows.first(where: { $0.name == wrapper.name }) {
                    PRDetailSheet(row: row, sessions: sessions)
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryCards: some View {
        HStack(spacing: 10) {
            summaryCard(value: "\(prRows.count)", label: "EXERCICES", icon: "list.bullet")
            summaryCard(
                value: bestEverOneRM > 0 ? "\(Int(bestEverOneRM))" : "—",
                label: "MEILLEUR 1RM",
                icon: "trophy.fill"
            )
            summaryCard(
                value: totalVolumeAllTime > 0 ? "\(Int(totalVolumeAllTime / 1000))t" : "—",
                label: "VOLUME TOTAL",
                icon: "chart.bar.fill"
            )
        }
        .padding(.horizontal)
    }

    private func summaryCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(theme.color.accent)
            Text(value)
                .font(.title3)
                .fontWeight(.black)
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Goal Tracking

    private var goalTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let goal = userGoal {
                    Image(systemName: goal.icon)
                        .font(.caption)
                        .foregroundStyle(theme.color.accent)
                }
                Text("OBJECTIF")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundStyle(.secondary)
            }

            if let goal = userGoal, let currentKg = lastWeight?.kg {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.label)
                                .font(.headline.bold())
                            if goal.hasWeightTarget && targetWeight > 0 {
                                Text("Objectif : \(String(format: "%.1f", targetWeight)) kg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f", currentKg))
                                .font(.title3.bold())
                                .foregroundStyle(theme.color.accent)
                            Text("kg actuels")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Progress bar for cut/bulk
                    if goal.hasWeightTarget && targetWeight > 0 {
                        goalProgressBar(goal: goal, current: currentKg)
                    }

                    // Smart feedback
                    goalFeedback(goal: goal, current: currentKg)
                }
            } else if userGoal != nil && lastWeight == nil {
                Text("Ajoute ton poids pour suivre ta progression")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func goalProgressBar(goal: FitnessGoal, current: Double) -> some View {
        let startKg = weights.last?.kg ?? current
        let totalDiff = abs(targetWeight - startKg)
        let currentDiff = abs(current - startKg)
        let progress = totalDiff > 0 ? min(1, currentDiff / totalDiff) : 0
        let isCorrectDirection = (goal == .cut && current <= startKg) || (goal == .bulk && current >= startKg)
        let effectiveProgress = isCorrectDirection ? progress : 0

        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.color.accent.gradient)
                        .frame(width: geo.size.width * effectiveProgress)
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: "%.1f kg", startKg))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(effectiveProgress * 100))%")
                    .font(.caption2.bold())
                    .foregroundStyle(theme.color.accent)
                Spacer()
                Text(String(format: "%.1f kg", targetWeight))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }

        if let weeks = goal.estimatedWeeks(from: current, to: targetWeight) {
            let months = weeks / 4
            let remWeeks = weeks % 4
            let eta: String = months > 0
                ? "\(months) mois\(remWeeks > 0 ? " et \(remWeeks) sem." : "")"
                : "\(weeks) semaines"
            Text("Objectif atteint dans ~\(eta)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func goalFeedback(goal: FitnessGoal, current: Double) -> some View {
        let recentWeights = weights.prefix(4) // Last ~month
        if recentWeights.count >= 2 {
            let newest = recentWeights.first!.kg
            let oldest = recentWeights.last!.kg
            let weekCount = max(1, Calendar.current.dateComponents([.weekOfYear], from: recentWeights.last!.date, to: recentWeights.first!.date).weekOfYear ?? 1)
            let actualWeeklyChange = (newest - oldest) / Double(weekCount)
            let expectedWeeklyChange = goal.weeklyRate

            let (icon, message, color) = feedbackContent(
                goal: goal,
                actual: actualWeeklyChange,
                expected: expectedWeeklyChange,
                current: current
            )

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func feedbackContent(goal: FitnessGoal, actual: Double, expected: Double, current: Double) -> (String, String, Color) {
        switch goal {
        case .cut:
            if actual <= expected * 1.5 {
                // Losing too fast
                return ("exclamationmark.triangle.fill",
                        "Tu perds vite (\(String(format: "%.1f", abs(actual))) kg/sem). Augmente un peu tes calories pour préserver ton muscle.",
                        .orange)
            } else if actual <= expected * 0.5 {
                // Good pace
                return ("checkmark.seal.fill",
                        "Parfait, tu es sur la bonne voie ! Continue comme ça.",
                        .green)
            } else if actual < 0 {
                // Losing but slow
                return ("tortoise.fill",
                        "Tu perds du poids mais lentement. Réduis légèrement tes calories ou ajoute du cardio.",
                        .yellow)
            } else {
                // Gaining weight on a cut
                return ("arrow.up.circle.fill",
                        "Tu prends du poids au lieu d'en perdre. Vérifie ton déficit calorique.",
                        .red)
            }

        case .bulk:
            if actual >= expected * 2 {
                // Gaining too fast
                return ("exclamationmark.triangle.fill",
                        "Tu prends vite (\(String(format: "%.1f", actual)) kg/sem). Réduis un peu pour limiter le gras.",
                        .orange)
            } else if actual >= expected * 0.5 {
                // Good pace
                return ("checkmark.seal.fill",
                        "Bonne progression ! Tu es dans le bon rythme.",
                        .green)
            } else if actual > 0 {
                // Gaining but slow
                return ("tortoise.fill",
                        "Tu progresses mais lentement. Augmente tes calories de 200-300 kcal.",
                        .yellow)
            } else {
                // Losing weight on a bulk
                return ("arrow.down.circle.fill",
                        "Tu perds du poids au lieu d'en prendre. Mange plus !",
                        .red)
            }

        case .maintain:
            if abs(actual) < 0.15 {
                return ("checkmark.seal.fill", "Poids stable, c'est parfait !", .green)
            } else if actual > 0 {
                return ("arrow.up.circle.fill", "Tu prends un peu. Attention à tes calories.", .orange)
            } else {
                return ("arrow.down.circle.fill", "Tu perds un peu. Mange légèrement plus.", .orange)
            }

        case .strength:
            if actual >= 0 {
                return ("checkmark.seal.fill", "Poids stable ou en hausse, bon pour la force !", .green)
            } else {
                return ("info.circle.fill", "Tu perds du poids, ça peut impacter tes perfs. Mange suffisamment.", .yellow)
            }

        case .recomp:
            if abs(actual) < 0.3 {
                return ("checkmark.seal.fill", "Poids stable — si tu progresses en force, la recomp fonctionne !", .green)
            } else if actual < -0.5 {
                return ("arrow.down.circle.fill", "Tu perds trop vite pour une recomp. Augmente un peu tes calories.", .orange)
            } else {
                return ("info.circle.fill", "Légère variation, continue à surveiller tes perfs.", .yellow)
            }
        }
    }

    // MARK: - Weekly Progress

    private var weeklyProgressSection: some View {
        let weekSessions = sessions.filter {
            $0.started > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
        return HStack(spacing: 10) {
            VStack(spacing: 6) {
                Text("\(weekSessions.count)/\(weeklyGoal)")
                    .font(.title3).fontWeight(.black)
                    .foregroundStyle(weekSessions.count >= weeklyGoal ? .green : theme.color.accent)
                Text("SÉANCES / SEM.")
                    .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // Week streak dots
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<weeklyGoal, id: \.self) { i in
                        Circle()
                            .fill(i < weekSessions.count ? theme.color.accent : Color.secondary.opacity(0.2))
                            .frame(width: 12, height: 12)
                    }
                }
                Text(weekSessions.count >= weeklyGoal ? "OBJECTIF ATTEINT" : "CONTINUE")
                    .font(.caption2).fontWeight(.bold).tracking(1)
                    .foregroundStyle(weekSessions.count >= weeklyGoal ? .green : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal)
    }

    // MARK: - Weight Section

    private var weightSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("POIDS (KG)")
                        .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                    TextField(lastWeight?.kg.formatted() ?? "75", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("BF %")
                        .font(.caption2).fontWeight(.bold).tracking(1).foregroundStyle(.secondary)
                    TextField("opt.", text: $bfInput)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button { addWeight() } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(theme.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            if let w = lastWeight {
                HStack(spacing: 12) {
                    miniStat(value: String(format: "%.1f", w.kg), unit: "kg", label: "Actuel")
                    miniStat(
                        value: w.bodyFat.map { String(format: "%.1f", $0) } ?? "—",
                        unit: "%", label: "BF"
                    )
                    let delta = weights.count >= 2 ? w.kg - weights[1].kg : 0
                    miniStat(
                        value: (delta >= 0 ? "+" : "") + String(format: "%.1f", delta),
                        unit: "kg",
                        label: "Δ",
                        color: delta > 0 ? .red : delta < 0 ? .green : .secondary
                    )
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    private func miniStat(value: String, unit: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value).font(.callout).fontWeight(.black).foregroundStyle(color)
                Text(unit).font(.caption2).foregroundStyle(.secondary)
            }
            Text(label).font(.caption2).fontWeight(.bold).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func addWeight() {
        guard let kg = Double(weightInput.replacingOccurrences(of: ",", with: ".")), kg > 0 else { return }
        let bf = Double(bfInput.replacingOccurrences(of: ",", with: "."))
        let entry = WeightEntry(kg: kg, bodyFat: bf)
        context.insert(entry)

        weightInput = ""
        bfInput = ""
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Évolution du poids")
                .font(.subheadline)
                .fontWeight(.bold)
            let data = Array(weights.suffix(30).reversed())
            Chart(data) { w in
                AreaMark(x: .value("Date", w.date), y: .value("Kg", w.kg))
                    .foregroundStyle(theme.color.accent.opacity(0.15).gradient)
                LineMark(x: .value("Date", w.date), y: .value("Kg", w.kg))
                    .foregroundStyle(theme.color.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(x: .value("Date", w.date), y: .value("Kg", w.kg))
                    .foregroundStyle(theme.color.accent)
                    .symbolSize(30)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    private var bfChart: some View {
        let bfWeights = weights.suffix(30).reversed().filter { $0.bodyFat != nil }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Évolution du body fat")
                .font(.subheadline)
                .fontWeight(.bold)
            Chart(Array(bfWeights)) { w in
                AreaMark(x: .value("Date", w.date), y: .value("BF", w.bodyFat ?? 0))
                    .foregroundStyle(.orange.opacity(0.15).gradient)
                LineMark(x: .value("Date", w.date), y: .value("BF", w.bodyFat ?? 0))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(x: .value("Date", w.date), y: .value("BF", w.bodyFat ?? 0))
                    .foregroundStyle(.orange)
                    .symbolSize(30)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 160)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    // MARK: - PR List

    private var prList: some View {
        VStack(spacing: 10) {
            ForEach(MuscleGroup.allCases) { group in
                let rows = prRows.filter { $0.group == group }
                if !rows.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: group.icon)
                                .font(.caption)
                                .foregroundStyle(theme.color.accent)
                            Text(group.label.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 6) {
                            ForEach(rows) { row in
                                Button {
                                    selectedExerciseName = row.name
                                } label: {
                                    prRow(row)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal)
                }
            }
        }
    }

    private func prRow(_ row: PRRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                if let date = row.lastDate {
                    Text(date.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(row.bestKg)) kg")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
                Text("1RM \(Int(row.oneRM))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
            Text("Aucun record")
                .font(.headline)
            Text("Termine ta première séance pour débloquer tes records")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 60)
    }
}

private struct ExerciseNameWrapper: Identifiable {
    var id: String { name }
    let name: String
}

// MARK: - PR Detail Sheet

struct PRDetailSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    fileprivate let row: RecordsView.PRRow
    let sessions: [WorkoutSession]

    fileprivate init(row: RecordsView.PRRow, sessions: [WorkoutSession]) {
        self.row = row
        self.sessions = sessions
    }

    private struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let bestKg: Double
        let bestOneRM: Double
        let totalVolume: Double
    }

    private var points: [Point] {
        var result: [Point] = []
        for session in sessions {
            guard session.finished != nil else { continue }
            let matching = session.exercisesArray.filter { $0.name == row.name }
            guard !matching.isEmpty else { continue }
            let allSets = matching.flatMap { $0.setsArray }.filter { $0.done && $0.kg > 0 }
            guard !allSets.isEmpty else { continue }
            let bestKg = allSets.map(\.kg).max() ?? 0
            let bestOneRM = allSets.map(\.estimatedOneRM).max() ?? 0
            let volume = allSets.reduce(0) { $0 + $1.volume }
            result.append(Point(date: session.started, bestKg: bestKg, bestOneRM: bestOneRM, totalVolume: volume))
        }
        return result.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: row.group.icon)
                            .font(.title)
                            .foregroundStyle(theme.color.accent)
                            .frame(width: 56, height: 56)
                            .background(theme.color.accent.opacity(0.12))
                            .clipShape(Circle())
                        Text(row.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    HStack(spacing: 10) {
                        statBox(title: "PR", value: "\(Int(row.bestKg)) kg")
                        statBox(title: "1RM", value: "\(Int(row.oneRM)) kg")
                        statBox(title: "SÉANCES", value: "\(points.count)")
                    }
                    .padding(.horizontal)

                    if points.count >= 2 {
                        chartCard
                    }

                    if !points.isEmpty {
                        historyList
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Détail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(theme.color.accent)
                }
            }
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.black)
                .foregroundStyle(theme.color.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progression du 1RM estimé")
                .font(.subheadline)
                .fontWeight(.bold)
            Chart(points) { p in
                AreaMark(x: .value("Date", p.date), y: .value("1RM", p.bestOneRM))
                    .foregroundStyle(theme.color.accent.opacity(0.15).gradient)
                LineMark(x: .value("Date", p.date), y: .value("1RM", p.bestOneRM))
                    .foregroundStyle(theme.color.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(x: .value("Date", p.date), y: .value("1RM", p.bestOneRM))
                    .foregroundStyle(theme.color.accent)
                    .symbolSize(40)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Historique")
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            ForEach(points.reversed()) { p in
                HStack {
                    Text(p.date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(p.bestKg)) kg")
                        .font(.caption.bold())
                    Text("·").foregroundStyle(.tertiary)
                    Text("vol \(Int(p.totalVolume))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                if p.id != points.first?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}
