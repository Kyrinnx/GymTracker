import SwiftUI
import SwiftData

struct XPView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.started, order: .reverse) private var sessions: [WorkoutSession]

    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4

    private var rank: Rank { Rank.from(xp: totalXP) }
    private var finishedSessions: [WorkoutSession] {
        sessions.filter { $0.finished != nil }
    }

    /// Recalculate XP from stored session data to stay consistent
    private func reconcileXP() {
        let storedXP = finishedSessions.reduce(0) { $0 + $1.xpAwarded }
        if storedXP != totalXP {
            totalXP = max(0, storedXP)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero: mascot + rank
                    heroSection

                    // XP progress to next rank
                    progressSection

                    // Streak
                    streakSection

                    // Stats XP
                    xpStatsRow

                    // All ranks
                    allRanksSection
                }
                .padding(.bottom, 80)
            }
            .navigationTitle("Progression")
            .onAppear { reconcileXP() }
        }
    }

    // MARK: - Hero

    private var isHighTierRank: Bool {
        [Rank.elite, .legende, .titan, .mythique].contains(rank)
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            if isHighTierRank {
                GIFView(name: rank.mascot)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Image(systemName: rank.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        LinearGradient(
                            colors: [theme.color.accent, rank.color == .gray ? theme.color.accent.opacity(0.7) : rank.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: theme.color.accent.opacity(0.3), radius: 12, y: 6)
            }

            Text(rank.label)
                .font(.title)
                .fontWeight(.black)
                .foregroundStyle(theme.color.accent)

            Text("\(totalXP) XP")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        )
        .padding(.horizontal)
    }

    // MARK: - Progress

    private var progressSection: some View {
        let nextRank = rank.next
        let xpInRank = totalXP - rank.xpRequired
        let xpForNext = (nextRank?.xpRequired ?? rank.xpRequired) - rank.xpRequired
        let progress: Double = xpForNext > 0 ? min(Double(xpInRank) / Double(xpForNext), 1.0) : 1.0

        return VStack(spacing: 10) {
            if let next = nextRank {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: rank.icon)
                            .font(.caption)
                            .foregroundStyle(rank.color)
                        Text(rank.label)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(rank.color)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Text(next.label)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(next.color)
                        Image(systemName: next.icon)
                            .font(.caption)
                            .foregroundStyle(next.color)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 10)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [rank.color, next.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)

                Text("\(next.xpRequired - totalXP) XP restants")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Rang maximum atteint !")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Streak

    private var streakSection: some View {
        let streak = StreakCalculator.currentStreak(sessions: Array(sessions), weeklyGoal: weeklyGoal)
        let days = StreakCalculator.weekDays(sessions: Array(sessions))
        let dayLabels = ["L", "M", "M", "J", "V", "S", "D"]
        let calendar = Calendar.current
        let todayIndex = (calendar.component(.weekday, from: Date()) + 5) % 7

        return VStack(spacing: 14) {
            Text("STREAK")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                // Flame + count
                VStack(spacing: 4) {
                    ZStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(
                                streak > 0
                                ? LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top)
                                : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                            )
                            .symbolEffect(.pulse, options: .repeating, isActive: streak > 0)
                    }
                    Text("\(streak)")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                    Text("JOURS")
                        .font(.system(size: 8))
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80)

                // Week days
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 6) {
                            Text(dayLabels[i])
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(i == todayIndex ? .primary : .secondary)

                            ZStack {
                                Circle()
                                    .fill(days[i] ? theme.color.accent : Color(.systemGray5))
                                    .frame(width: 30, height: 30)
                                if days[i] {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Weekly goal progress
            let weekSessions = sessions.filter {
                $0.started > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            }
            HStack(spacing: 8) {
                Text("\(weekSessions.count)/\(weeklyGoal) séances cette semaine")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if weekSessions.count >= weeklyGoal {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text("Objectif atteint")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - XP Stats Row

    private var xpStatsRow: some View {
        HStack(spacing: 10) {
            xpStatCard(
                value: "\(finishedSessions.count)",
                label: "SÉANCES",
                icon: "figure.strengthtraining.traditional"
            )
            xpStatCard(
                value: "\(totalXP)",
                label: "XP TOTAL",
                icon: "star.fill",
                accent: true
            )
            xpStatCard(
                value: finishedSessions.isEmpty ? "—" : "\(totalXP / finishedSessions.count)",
                label: "XP / SÉANCE",
                icon: "chart.line.uptrend.xyaxis"
            )
        }
        .padding(.horizontal)
    }

    private func xpStatCard(value: String, label: String, icon: String, accent: Bool = false) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(accent ? theme.color.accent : .secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.black)
                .foregroundStyle(accent ? theme.color.accent : .primary)
            Text(label)
                .font(.system(size: 7))
                .fontWeight(.bold)
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - All Ranks

    private var allRanksSection: some View {
        VStack(spacing: 12) {
            Text("TOUS LES RANGS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Rank.allCases, id: \.self) { r in
                    let isHighTier = [Rank.elite, .legende, .titan, .mythique].contains(r)
                    HStack(spacing: 14) {
                        if isHighTier {
                            GIFView(name: r.mascot)
                                .frame(width: 38, height: 38)
                                .clipped()
                                .clipShape(Circle())
                                .opacity(totalXP >= r.xpRequired ? 1.0 : 0.35)
                        } else {
                            Image(systemName: r.icon)
                                .font(.body)
                                .foregroundStyle(r == rank ? r.color : .secondary)
                                .frame(width: 38, height: 38)
                                .background(r == rank ? r.color.opacity(0.15) : Color(.systemGray6))
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.label)
                                .font(.subheadline)
                                .fontWeight(r == rank ? .bold : .regular)
                                .foregroundStyle(totalXP >= r.xpRequired ? .primary : .tertiary)
                            Text("\(r.xpRequired) XP")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if totalXP >= r.xpRequired {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("\(r.xpRequired - totalXP)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            + Text(" XP")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 10)
                    if r != Rank.allCases.last {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal)
    }
}
