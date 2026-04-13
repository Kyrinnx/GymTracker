import SwiftUI

// MARK: - Rank Definition

enum Rank: Int, CaseIterable {
    case debutant = 0
    case habitue = 1000
    case confirme = 3000
    case avance = 6000
    case elite = 12000
    case legende = 25000
    case titan = 50000
    case mythique = 100000

    var label: String {
        switch self {
        case .debutant: "Débutant"
        case .habitue: "Habitué"
        case .confirme: "Confirmé"
        case .avance: "Avancé"
        case .elite: "Élite"
        case .legende: "Légende"
        case .titan: "Titan"
        case .mythique: "Mythique"
        }
    }

    var icon: String {
        switch self {
        case .debutant: "figure.walk"
        case .habitue: "figure.run"
        case .confirme: "figure.strengthtraining.traditional"
        case .avance: "flame.fill"
        case .elite: "star.fill"
        case .legende: "crown.fill"
        case .titan: "bolt.fill"
        case .mythique: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .debutant: .gray
        case .habitue: .green
        case .confirme: .blue
        case .avance: .purple
        case .elite: .orange
        case .legende: .red
        case .titan: .yellow
        case .mythique: Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }

    var mascot: String {
        switch self {
        case .debutant, .habitue, .confirme, .avance: "mascot_debut"
        case .elite: "mascot_debut"
        case .legende: "mascot_confirme"
        case .titan: "mascot_elite"
        case .mythique: "mascot_legende"
        }
    }

    var xpRequired: Int { rawValue }

    var next: Rank? {
        let all = Rank.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    static func from(xp: Int) -> Rank {
        Rank.allCases.last { xp >= $0.rawValue } ?? .debutant
    }
}

// MARK: - XP Breakdown

struct XPBreakdown {
    var base: Int = 0
    var exerciseBonus: Int = 0
    var setsBonus: Int = 0
    var volumeBonus: Int = 0
    var durationBonus: Int = 0
    var weightBonus: Int = 0
    var repsBonus: Int = 0
    var prBonus: Int = 0
    var streakBonus: Int = 0
    var goalBonus: Int = 0

    var total: Int {
        base + exerciseBonus + setsBonus + volumeBonus + durationBonus
        + weightBonus + repsBonus + prBonus + streakBonus + goalBonus
    }

    var details: [(label: String, value: Int, icon: String)] {
        var items: [(String, Int, String)] = []
        if base > 0 { items.append(("Séance terminée", base, "checkmark.circle.fill")) }
        if exerciseBonus > 0 { items.append(("Exercices complétés", exerciseBonus, "figure.strengthtraining.traditional")) }
        if setsBonus > 0 { items.append(("Séries validées", setsBonus, "checkmark.seal.fill")) }
        if volumeBonus > 0 { items.append(("Volume soulevé", volumeBonus, "scalemass.fill")) }
        if durationBonus > 0 { items.append(("Durée", durationBonus, "clock.fill")) }
        if weightBonus > 0 { items.append(("Poids augmenté", weightBonus, "arrow.up.right")) }
        if repsBonus > 0 { items.append(("Reps augmentées", repsBonus, "plus.circle.fill")) }
        if prBonus > 0 { items.append(("Nouveau PR", prBonus, "trophy.fill")) }
        if streakBonus > 0 { items.append(("Streak semaine", streakBonus, "flame.fill")) }
        if goalBonus > 0 { items.append(("Objectif atteint", goalBonus, "target")) }
        return items
    }
}

// MARK: - XP Calculator

struct XPCalculator {

    static func calculate(
        session: WorkoutSession,
        previousSession: WorkoutSession?,
        exerciseInfos: [ExerciseInfo],
        currentStreak: Int,
        weekSessionCount: Int,
        weeklyGoal: Int
    ) -> XPBreakdown {
        var b = XPBreakdown()

        let doneExercises = session.exercisesArray.filter { ex in
            ex.setsArray.contains { $0.done }
        }
        guard !doneExercises.isEmpty else { return b }

        let doneSets = doneExercises.flatMap { $0.setsArray.filter { $0.done } }
        let totalVolume = doneSets.reduce(0.0) { $0 + $1.kg * Double($1.reps) }
        let durationMin = session.durationMinutes

        // 1. Base: 50 XP par séance
        b.base = 50

        // 2. Exercices complétés: 10 XP par exo
        b.exerciseBonus = doneExercises.count * 10

        // 3. Séries validées: 3 XP par série
        b.setsBonus = doneSets.count * 3

        // 4. Volume: 1 XP par tranche de 500 kg soulevés
        if totalVolume > 0 {
            b.volumeBonus = max(1, Int(totalVolume / 500))
        }

        // 5. Durée: 1 XP par 2 minutes (max 30)
        b.durationBonus = min(30, max(0, durationMin / 2))

        // 6. Progression vs séance précédente
        if let prev = previousSession {
            for exercise in doneExercises {
                let bestKg = exercise.setsArray.filter { $0.done && $0.kg > 0 }.map(\.kg).max() ?? 0
                let bestReps = exercise.setsArray.filter { $0.done }.map(\.reps).max() ?? 0

                if let prevEx = prev.exercisesArray.first(where: { $0.name == exercise.name }) {
                    let prevBestKg = prevEx.setsArray.filter { $0.done && $0.kg > 0 }.map(\.kg).max() ?? 0
                    let prevBestReps = prevEx.setsArray.filter { $0.done }.map(\.reps).max() ?? 0

                    if bestKg > prevBestKg && prevBestKg > 0 {
                        b.weightBonus += 25
                    }
                    if bestReps > prevBestReps && prevBestReps > 0 {
                        b.repsBonus += 15
                    }
                }

                // 7. PR
                if let info = exerciseInfos.first(where: { $0.name == exercise.name }) {
                    if bestKg > info.personalRecord && bestKg > 0 {
                        b.prBonus += 50
                    }
                }
            }
        }

        // 8. Streak semaines : 15 XP par semaine consécutive d'objectif atteint (max 60)
        if currentStreak > 0 {
            b.streakBonus = min(60, currentStreak * 15)
        }

        // 9. Objectif semaine atteint avec cette séance
        if weekSessionCount + 1 >= weeklyGoal {
            b.goalBonus = 100
        }

        return b
    }
}

// MARK: - Streak Calculator (weekly goal based)

struct StreakCalculator {
    /// Counts consecutive weeks where the weekly session goal was met.
    static func currentStreak(sessions: [WorkoutSession], weeklyGoal: Int = 4) -> Int {
        let calendar = Calendar.current
        let finishedDates = sessions.compactMap(\.finished)
        guard !finishedDates.isEmpty else { return 0 }

        // Group sessions by ISO week
        var weekCounts: [Int: Int] = [:]  // weekOfYear*100+year -> count
        for date in finishedDates {
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            let key = (comps.yearForWeekOfYear ?? 0) * 100 + (comps.weekOfYear ?? 0)
            weekCounts[key, default: 0] += 1
        }

        // Get current week
        let todayComps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        var checkYear = todayComps.yearForWeekOfYear ?? 0
        var checkWeek = todayComps.weekOfYear ?? 0

        var streak = 0
        // Check current week first - only count if goal already met
        let currentKey = checkYear * 100 + checkWeek
        if (weekCounts[currentKey] ?? 0) >= weeklyGoal {
            streak = 1
        }

        // Go back through previous weeks
        for _ in 0..<52 {
            // Move to previous week
            if let prevWeekDate = calendar.date(byAdding: .weekOfYear, value: -(streak == 0 ? 1 : streak), to: Date()) {
                let prevComps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: prevWeekDate)
                checkYear = prevComps.yearForWeekOfYear ?? 0
                checkWeek = prevComps.weekOfYear ?? 0
            } else {
                break
            }
            let key = checkYear * 100 + checkWeek
            if (weekCounts[key] ?? 0) >= weeklyGoal {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    /// Days in the current week that have sessions (Mon=0 to Sun=6).
    static func weekDays(sessions: [WorkoutSession]) -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = (calendar.component(.weekday, from: today) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -weekday, to: today)!

        let finishedDates = Set(
            sessions
                .compactMap(\.finished)
                .map { calendar.startOfDay(for: $0) }
        )

        return (0..<7).map { dayOffset in
            let day = calendar.date(byAdding: .day, value: dayOffset, to: monday)!
            return finishedDates.contains(day)
        }
    }
}
