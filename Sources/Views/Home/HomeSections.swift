import SwiftUI

// MARK: - Rank Bar

struct HomeRankBar: View {
    @Environment(ThemeManager.self) private var theme
    let totalXP: Int

    private var currentRank: Rank { Rank.from(xp: totalXP) }

    var body: some View {
        let rank = currentRank
        let nextRank = rank.next
        let xpInRank = totalXP - rank.xpRequired
        let xpForNext = (nextRank?.xpRequired ?? rank.xpRequired) - rank.xpRequired
        let progress: Double = xpForNext > 0 ? min(Double(xpInRank) / Double(xpForNext), 1.0) : 1.0

        return HStack(spacing: 12) {
            Image(systemName: rank.icon)
                .font(.title3)
                .foregroundStyle(rank.color)
                .frame(width: 36, height: 36)
                .background(rank.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(rank.label)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(rank.color)
                    Spacer()
                    Text("\(totalXP) XP")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 6)
                        Capsule()
                            .fill(rank.color.gradient)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                if let next = nextRank {
                    Text("\(next.xpRequired - totalXP) XP avant \(next.label)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Streak Card

struct HomeStreakCard: View {
    @Environment(ThemeManager.self) private var theme
    let sessions: [WorkoutSession]
    let weeklyGoal: Int

    var body: some View {
        let streak = StreakCalculator.currentStreak(sessions: sessions, weeklyGoal: weeklyGoal)
        let days = StreakCalculator.weekDays(sessions: sessions)
        let dayLabels = ["L", "M", "M", "J", "V", "S", "D"]
        let calendar = Calendar.current
        let todayIndex = (calendar.component(.weekday, from: Date()) + 5) % 7

        return HStack(spacing: 0) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            streak > 0
                            ? LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                        )
                        .symbolEffect(.pulse, options: .repeating, isActive: streak > 0)
                }
                Text("\(streak)")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundStyle(streak > 0 ? .orange : .secondary)
                Text("JOURS")
                    .font(.system(size: 7))
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(dayLabels[i])
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(i == todayIndex ? .primary : .secondary)

                        ZStack {
                            Circle()
                                .fill(days[i] ? theme.color.accent : Color(.systemGray5))
                                .frame(width: 28, height: 28)
                            if days[i] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Body Stats Card

struct HomeBodyStatsCard: View {
    @Environment(ThemeManager.self) private var theme
    let lastWeight: WeightEntry?
    let recentGroups: [MuscleGroup]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    RadialGradient(
                        colors: [theme.color.accent.opacity(0.10), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                    BodyMapView(activeGroups: recentGroups)
                        .frame(width: 100, height: 150)
                }
                .frame(width: 110, height: 160)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        HomeStatBox(value: lastWeight.map { String(format: "%.1f", $0.kg) } ?? "—", label: "KG", tooltip: "Poids actuel")
                        HomeStatBox(value: lastWeight?.bodyFat.map { String(format: "%.1f", $0) } ?? "—", label: "% BF", tooltip: "Taux de masse grasse")
                    }
                    HStack(spacing: 8) {
                        HomeStatBox(value: lastWeight?.leanMass.map { String(format: "%.1f", $0) } ?? "—",
                                label: "MM", tooltip: "Masse maigre (poids - gras)")
                        HomeStatBox(value: lastWeight?.bmr.map { "\(Int($0))" } ?? "—",
                                label: "MB", tooltip: "Métabolisme basal (kcal/jour)")
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if !recentGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(recentGroups) { group in
                            Text(group.label)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.color.accent.opacity(0.12))
                                .foregroundStyle(theme.color.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                Text("Aucun muscle ces 7 derniers jours")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}

// MARK: - Stat Box with Tooltip

struct HomeStatBox: View {
    let value: String
    let label: String
    let tooltip: String?
    @State private var showTooltip = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3)
                .fontWeight(.black)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            if tooltip != nil {
                showTooltip = true
            }
        }
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            Text(tooltip ?? "")
                .font(.subheadline)
                .padding(12)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Favorites Section

struct HomeFavoritesSection: View {
    @Environment(ThemeManager.self) private var theme
    let favoriteExercises: [ExerciseInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FAVORIS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2.5)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    Text("Voir tout")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.color.accent)
                }
            }
            .padding(.horizontal)

            if favoriteExercises.isEmpty {
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "star")
                            .font(.title3)
                            .foregroundStyle(theme.color.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aucun favori")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text("Explore la bibliothèque d'exercices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favoriteExercises) { info in
                            NavigationLink {
                                ExerciseLibraryView()
                            } label: {
                                HomeFavoriteCard(info: info)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

private struct HomeFavoriteCard: View {
    @Environment(ThemeManager.self) private var theme
    let info: ExerciseInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: info.group.icon)
                    .font(.caption2)
                    .foregroundStyle(theme.color.accent)
                    .frame(width: 22, height: 22)
                    .background(theme.color.accent.opacity(0.12))
                    .clipShape(Circle())
                Spacer()
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
            Text(info.name)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if info.personalRecord > 0 {
                Text("PR: \(Int(info.personalRecord))kg")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
            } else {
                Text(info.group.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 130, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

// MARK: - Last Session Card

struct HomeLastSessionCard: View {
    @Environment(ThemeManager.self) private var theme
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DERNIÈRE SÉANCE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(session.started.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.color.accent)
            }
            Text(session.templateName)
                .font(.headline)
            HStack(spacing: 8) {
                Text("\(session.totalSets) séries")
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("\(Int(session.totalVolume)) kg")
                if session.durationMinutes > 0 {
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(session.durationMinutes) min")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
