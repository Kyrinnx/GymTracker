import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.started, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var exerciseInfos: [ExerciseInfo]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]

    @State private var selectedExerciseName: String?
    @State private var weightInput: String = ""
    @State private var bfInput: String = ""

    private var lastWeight: WeightEntry? { weights.first }

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
                    weightSection
                    if weights.count >= 2 {
                        weightChart
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
                .padding(.bottom, 20)
            }
            .navigationTitle("Progrès")
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
            Chart(weights.suffix(30).reversed()) { w in
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
