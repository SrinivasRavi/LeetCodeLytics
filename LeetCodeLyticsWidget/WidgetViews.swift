import SwiftUI
import WidgetKit

// MARK: - Small Widget: Solved Streak

struct SmallSolvedWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 8) {
            Image("AstroLeet")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("⚡ \(entry.data.anysolveStreak) days")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("Solved")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.black, for: .widget)
    }
}

// MARK: - Small Widget: Daily Question Streak

struct SmallDCCWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 8) {
            Image("AstroLeet")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("🔥 \(entry.data.dccStreak) days")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("Daily Question")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.black, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        HStack(spacing: 16) {
            Image("AstroLeet")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 20) {
                    StreakPill(icon: "⚡", value: entry.data.anysolveStreak, label: "Solved")
                    StreakPill(icon: "🔥", value: entry.data.dccStreak, label: "Daily Q")
                }

                HStack(spacing: 12) {
                    DifficultyDot(label: "E", value: entry.data.easySolved, color: .green)
                    DifficultyDot(label: "M", value: entry.data.mediumSolved, color: .orange)
                    DifficultyDot(label: "H", value: entry.data.hardSolved, color: .red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color.black, for: .widget)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Same as medium top section
            HStack(spacing: 16) {
                Image("AstroLeet")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 20) {
                        StreakPill(icon: "⚡", value: entry.data.anysolveStreak, label: "Solved")
                        StreakPill(icon: "🔥", value: entry.data.dccStreak, label: "Daily Q")
                    }
                    HStack(spacing: 12) {
                        DifficultyDot(label: "E", value: entry.data.easySolved, color: .green)
                        DifficultyDot(label: "M", value: entry.data.mediumSolved, color: .orange)
                        DifficultyDot(label: "H", value: entry.data.hardSolved, color: .red)
                    }
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            Text("Activity")
                .font(.caption)
                .foregroundColor(.gray)

            WidgetHeatmapView(recentCalendar: entry.data.recentCalendar)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Color.black, for: .widget)
    }
}

// MARK: - Shared sub-views

private struct StreakPill: View {
    let icon: String
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(icon) \(value)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

private struct DifficultyDot: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(label): \(value)")
                .font(.system(size: 11))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Heatmap for Large widget

struct WidgetHeatmapView: View {
    let recentCalendar: [String: Int]
    private let weeks = 10
    private let cellSize: CGFloat = 10
    private let spacing: CGFloat = 2

    private var dailyCounts: [Int: Int] {
        Dictionary(
            recentCalendar.compactMap { k, v in Int(k).map { ($0, v) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private var weekDates: [[Date?]] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysToSunday = (weekday - 1) % 7
        guard let lastSunday = cal.date(byAdding: .day, value: -daysToSunday, to: today),
              let startDate = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: lastSunday) else { return [] }

        var result: [[Date?]] = []
        var weekStart = startDate
        for _ in 0..<weeks {
            var week: [Date?] = []
            for day in 0..<7 {
                if let date = cal.date(byAdding: .day, value: day, to: weekStart) {
                    week.append(date <= today ? date : nil)
                } else {
                    week.append(nil)
                }
            }
            result.append(week)
            weekStart = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        }
        return result
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { _, week in
                VStack(spacing: spacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatmapColor(count: countFor(date: date)))
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func countFor(date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let ts = Int(cal.startOfDay(for: date).timeIntervalSince1970)
        return dailyCounts[ts] ?? 0
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.2)
        case 1: return Color(red: 1, green: 0.631, blue: 0.086).opacity(0.4)
        case 2: return Color(red: 1, green: 0.631, blue: 0.086).opacity(0.65)
        default: return Color(red: 1, green: 0.631, blue: 0.086)
        }
    }
}
