import SwiftUI

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable, Codable {
    case light, dark, system
    var label: String {
        switch self {
        case .light: "Clair"
        case .dark: "Sombre"
        case .system: "Système"
        }
    }
    var icon: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "gear"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

// MARK: - Theme Color
enum ThemeColor: String, CaseIterable, Codable, Identifiable {
    case solaire, ocean, foret, lavande, nuit, candy
    var id: String { rawValue }

    var label: String {
        switch self {
        case .solaire: "Solaire"
        case .ocean: "Océan"
        case .foret: "Forêt"
        case .lavande: "Lavande"
        case .nuit: "Nuit"
        case .candy: "Candy"
        }
    }
    var icon: String {
        switch self {
        case .solaire: "sun.max.fill"
        case .ocean: "drop.fill"
        case .foret: "leaf.fill"
        case .lavande: "sparkles"
        case .nuit: "moon.stars.fill"
        case .candy: "heart.fill"
        }
    }
    var accent: Color {
        switch self {
        case .solaire: Color(red: 1.0, green: 0.42, blue: 0.21)    // #FF6B35
        case .ocean: Color(red: 0.07, green: 0.65, blue: 0.86)     // #12A5DB
        case .foret: Color(red: 0.13, green: 0.79, blue: 0.59)     // #22C997
        case .lavande: Color(red: 0.49, green: 0.42, blue: 0.94)   // #7C6CF0
        case .nuit: Color(red: 0.38, green: 0.51, blue: 0.92)      // #6183EB
        case .candy: Color(red: 0.99, green: 0.36, blue: 0.56)     // #FD5C8F
        }
    }
    var accentLight: Color {
        switch self {
        case .solaire: Color(red: 1.0, green: 0.55, blue: 0.35)
        case .ocean: Color(red: 0.30, green: 0.78, blue: 0.95)
        case .foret: Color(red: 0.40, green: 0.90, blue: 0.72)
        case .lavande: Color(red: 0.65, green: 0.58, blue: 0.98)
        case .nuit: Color(red: 0.55, green: 0.66, blue: 0.96)
        case .candy: Color(red: 1.0, green: 0.55, blue: 0.70)
        }
    }
    var gradient: LinearGradient {
        LinearGradient(colors: [accent, accentLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var bgLight: Color {
        switch self {
        case .solaire: Color(red: 1.0, green: 0.97, blue: 0.95)
        case .ocean: Color(red: 0.94, green: 0.98, blue: 1.0)
        case .foret: Color(red: 0.94, green: 0.99, blue: 0.96)
        case .lavande: Color(red: 0.96, green: 0.95, blue: 1.0)
        case .nuit: Color(red: 0.94, green: 0.96, blue: 1.0)
        case .candy: Color(red: 1.0, green: 0.95, blue: 0.97)
        }
    }
    var bgDark: Color {
        switch self {
        case .solaire: Color(red: 0.10, green: 0.09, blue: 0.08)
        case .ocean: Color(red: 0.06, green: 0.09, blue: 0.12)
        case .foret: Color(red: 0.06, green: 0.10, blue: 0.08)
        case .lavande: Color(red: 0.08, green: 0.07, blue: 0.12)
        case .nuit: Color(red: 0.06, green: 0.07, blue: 0.12)
        case .candy: Color(red: 0.12, green: 0.07, blue: 0.09)
        }
    }
}

// MARK: - Theme Manager
@Observable
final class ThemeManager {
    var mode: ThemeMode {
        didSet { save() }
    }
    var color: ThemeColor {
        didSet { save() }
    }

    init() {
        let m = UserDefaults.standard.string(forKey: "themeMode") ?? "system"
        let c = UserDefaults.standard.string(forKey: "themeColor") ?? "solaire"
        self.mode = ThemeMode(rawValue: m) ?? .system
        self.color = ThemeColor(rawValue: c) ?? .solaire
    }

    private func save() {
        UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        UserDefaults.standard.set(color.rawValue, forKey: "themeColor")
    }
}
