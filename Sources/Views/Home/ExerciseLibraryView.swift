import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query private var exerciseInfos: [ExerciseInfo]
    @Query(sort: \WorkoutSession.started, order: .reverse) private var sessions: [WorkoutSession]

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedExercise: ExerciseInfo?

    enum FilterOption: Hashable, Identifiable {
        case all
        case favorites
        case group(MuscleGroup)
        var id: String {
            switch self {
            case .all: return "all"
            case .favorites: return "favorites"
            case .group(let g): return g.rawValue
            }
        }
        var label: String {
            switch self {
            case .all: return "Tous"
            case .favorites: return "Favoris"
            case .group(let g): return g.label
            }
        }
    }

    private static var allFilters: [FilterOption] {
        [.all, .favorites] + MuscleGroup.allCases.map { .group($0) }
    }

    private var filteredExercises: [ExerciseInfo] {
        var result = exerciseInfos
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .group(let g):
            result = result.filter { $0.muscleGroup == g.rawValue }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result.sorted { $0.name < $1.name }
    }

    private var groupedExercises: [(MuscleGroup, [ExerciseInfo])] {
        let dict = Dictionary(grouping: filteredExercises) { $0.group }
        return MuscleGroup.allCases.compactMap { group in
            guard let items = dict[group], !items.isEmpty else { return nil }
            return (group, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.allFilters) { filter in
                        filterPill(filter)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Exercise list
            List {
                ForEach(groupedExercises, id: \.0) { group, exercises in
                    Section {
                        ForEach(exercises) { info in
                            exerciseRow(info)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedExercise = info
                                }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: group.icon)
                                .font(.caption2)
                                .foregroundStyle(theme.color.accent)
                            Text(group.label.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                        }
                    }
                }
                // Spacer row so the last exercises scroll above the custom tab bar
                Section {} footer: {
                    Color.clear.frame(height: 60)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Rechercher un exercice")
        }
        .navigationTitle("Exercices")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            seedIfNeeded()
            updatePersonalRecords()
        }
        .sheet(item: $selectedExercise) { info in
            ExerciseDetailSheet(exerciseInfo: info, sessions: sessions)
        }
    }

    // MARK: - Filter Pill

    private func filterPill(_ filter: FilterOption) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                if case .favorites = filter {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                }
                Text(filter.label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? theme.color.accent : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ info: ExerciseInfo) -> some View {
        HStack(spacing: 12) {
            // Favorite toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    info.isFavorite.toggle()
                }
            } label: {
                Image(systemName: info.isFavorite ? "star.fill" : "star")
                    .font(.body)
                    .foregroundStyle(info.isFavorite ? Color.yellow : Color.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(info.isFavorite ? "Retirer \(info.name) des favoris" : "Ajouter \(info.name) aux favoris")

            VStack(alignment: .leading, spacing: 4) {
                Text(info.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    // Muscle group pill
                    Text(info.group.label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.color.accent.opacity(0.12))
                        .foregroundStyle(theme.color.accent)
                        .clipShape(Capsule())

                    if info.personalRecord > 0 {
                        Text("PR: \(Int(info.personalRecord))kg")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.color.accent)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Seeding

    private func seedIfNeeded() {
        guard exerciseInfos.isEmpty else { return }
        for (group, names) in ExerciseLibrary.exercises {
            for name in names {
                let info = ExerciseInfo(name: name, muscleGroup: group)
                context.insert(info)
            }
        }
    }

    // MARK: - PR Updates

    private func updatePersonalRecords() {
        // Build a dictionary of max kg per exercise name from all sessions
        var maxKg: [String: Double] = [:]
        for session in sessions {
            guard session.finished != nil else { continue }
            for exercise in session.exercisesArray {
                for aSet in exercise.setsArray where aSet.done && aSet.kg > 0 {
                    let current = maxKg[exercise.name] ?? 0
                    if aSet.kg > current {
                        maxKg[exercise.name] = aSet.kg
                    }
                }
            }
        }
        // Update ExerciseInfo records
        for info in exerciseInfos {
            if let best = maxKg[info.name], best > info.personalRecord {
                info.personalRecord = best
            }
        }
    }
}

// MARK: - Exercise Detail Sheet

struct ExerciseDetailSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var exerciseInfo: ExerciseInfo
    let sessions: [WorkoutSession]

    private var exerciseHistory: [(date: Date, sets: [WorkoutSet])] {
        var history: [(date: Date, sets: [WorkoutSet])] = []
        for session in sessions {
            guard session.finished != nil else { continue }
            for exercise in session.exercisesArray where exercise.name == exerciseInfo.name {
                let doneSets = exercise.setsArray.filter { $0.done }.sorted { $0.order < $1.order }
                if !doneSets.isEmpty {
                    history.append((date: session.started, sets: doneSets))
                }
            }
        }
        return history.sorted { $0.date > $1.date }
    }

    /// Best estimated 1RM across all done sets, using Epley formula.
    private var bestOneRM: Double {
        var best: Double = 0
        for entry in exerciseHistory {
            for s in entry.sets {
                if s.estimatedOneRM > best { best = s.estimatedOneRM }
            }
        }
        return best
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    VStack(spacing: 14) {
                        Image(systemName: exerciseInfo.group.icon)
                            .font(.title)
                            .foregroundStyle(theme.color.accent)
                            .frame(width: 56, height: 56)
                            .background(theme.color.accent.opacity(0.12))
                            .clipShape(Circle())

                        Text(exerciseInfo.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(exerciseInfo.group.label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(theme.color.accent.opacity(0.12))
                            .foregroundStyle(theme.color.accent)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Favorite toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            exerciseInfo.isFavorite.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: exerciseInfo.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(exerciseInfo.isFavorite ? Color.yellow : .secondary)
                            Text(exerciseInfo.isFavorite ? "Favori" : "Ajouter aux favoris")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)

                    // PR + Estimated 1RM row
                    HStack(spacing: 12) {
                        statCard(
                            label: "RECORD",
                            value: exerciseInfo.personalRecord > 0 ? "\(Int(exerciseInfo.personalRecord)) kg" : "—"
                        )
                        statCard(
                            label: "1RM ESTIMÉ",
                            value: bestOneRM > 0 ? "\(Int(bestOneRM)) kg" : "—",
                            tooltip: "Formule Epley\u{00A0}: kg × (1 + reps / 30)"
                        )
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("NOTES")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $exerciseInfo.notes)
                            .font(.subheadline)
                            .frame(minHeight: 80)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                    }

                    // History
                    if !exerciseHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HISTORIQUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundStyle(.secondary)

                            ForEach(Array(exerciseHistory.prefix(10).enumerated()), id: \.offset) { _, entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.date.formatted(.dateTime.day().month(.abbreviated).year()))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 8) {
                                        ForEach(Array(entry.sets.enumerated()), id: \.offset) { _, aSet in
                                            Text("\(Int(aSet.kg))kg x\(aSet.reps)")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text("Aucun historique")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding()
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
        .presentationDetents([.large])
    }

    private func statCard(label: String, value: String, tooltip: String? = nil) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(.secondary)
                if tooltip != nil {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Text(value)
                .font(.title3)
                .fontWeight(.black)
                .foregroundStyle(value == "—" ? AnyShapeStyle(.tertiary) : AnyShapeStyle(theme.color.accent))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .help(tooltip ?? "")
    }
}
