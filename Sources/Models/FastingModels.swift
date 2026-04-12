import Foundation
import SwiftData

// MARK: - Fasting Method
enum FastingMethod: String, Codable, CaseIterable, Identifiable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "OMAD"
    case fourteen10 = "14:10"
    case twelve12 = "12:12"
    case custom = "Custom"

    var id: String { rawValue }

    var label: String { rawValue }

    var subtitle: String {
        switch self {
        case .sixteen8: "16h jeûne · 8h alimentation"
        case .eighteen6: "18h jeûne · 6h alimentation"
        case .twenty4: "20h jeûne · 4h alimentation"
        case .omad: "Un seul repas par jour"
        case .fourteen10: "14h jeûne · 10h alimentation"
        case .twelve12: "Pour débuter en douceur"
        case .custom: "Durée personnalisée"
        }
    }

    /// Default fasting window in hours.
    var hours: Int {
        switch self {
        case .sixteen8: 16
        case .eighteen6: 18
        case .twenty4: 20
        case .omad: 23
        case .fourteen10: 14
        case .twelve12: 12
        case .custom: 16
        }
    }

    var emoji: String {
        switch self {
        case .sixteen8: "🦊"
        case .eighteen6: "🔥"
        case .twenty4: "🐉"
        case .omad: "👑"
        case .fourteen10: "🌱"
        case .twelve12: "🌙"
        case .custom: "⚙️"
        }
    }
}

// MARK: - Fasting Stage
/// Body milestones during a fast, mapped to elapsed hours.
enum FastingStage: Int, CaseIterable, Identifiable {
    case fed = 0           // 0–4h
    case earlyFasting = 4  // 4–12h
    case fatBurning = 12   // 12–18h
    case ketosis = 18      // 18–24h
    case autophagy = 24    // 24h+

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .fed: "Digestion"
        case .earlyFasting: "Début de jeûne"
        case .fatBurning: "Brûle-graisses"
        case .ketosis: "Cétose"
        case .autophagy: "Autophagie"
        }
    }

    var icon: String {
        switch self {
        case .fed: "fork.knife"
        case .earlyFasting: "hourglass"
        case .fatBurning: "flame.fill"
        case .ketosis: "bolt.fill"
        case .autophagy: "sparkles"
        }
    }

    static func current(elapsedHours: Double) -> FastingStage {
        let stages = allCases.reversed()
        for stage in stages where Double(stage.rawValue) <= elapsedHours {
            return stage
        }
        return .fed
    }
}

// MARK: - Fasting Session
@Model
final class FastingSession {
    var startDate: Date = Date()
    var plannedEndDate: Date = Date()
    var actualEndDate: Date?
    var methodRaw: String = FastingMethod.sixteen8.rawValue

    init(method: FastingMethod = .sixteen8, startDate: Date = Date()) {
        self.startDate = startDate
        self.methodRaw = method.rawValue
        self.plannedEndDate = Calendar.current.date(byAdding: .hour, value: method.hours, to: startDate) ?? startDate.addingTimeInterval(TimeInterval(method.hours * 3600))
    }

    var method: FastingMethod {
        FastingMethod(rawValue: methodRaw) ?? .sixteen8
    }

    var isActive: Bool { actualEndDate == nil }

    var totalDuration: TimeInterval {
        plannedEndDate.timeIntervalSince(startDate)
    }

    var elapsed: TimeInterval {
        let end = actualEndDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    var remaining: TimeInterval {
        max(0, plannedEndDate.timeIntervalSinceNow)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(1.0, elapsed / totalDuration)
    }

    var elapsedHours: Double { elapsed / 3600.0 }

    var currentStage: FastingStage { FastingStage.current(elapsedHours: elapsedHours) }
}
