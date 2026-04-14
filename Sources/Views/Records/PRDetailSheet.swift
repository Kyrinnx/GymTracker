import SwiftUI
import SwiftData
import Charts

// MARK: - PR Row Model

struct PRRow: Identifiable {
    var id: String { name }
    let name: String
    let group: MuscleGroup
    let bestKg: Double
    let oneRM: Double
    let lastDate: Date?
}

// MARK: - PR Detail Sheet

struct PRDetailSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let row: PRRow
    let sessions: [WorkoutSession]

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
