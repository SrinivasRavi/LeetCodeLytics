import SwiftUI
import WidgetKit

// MARK: - Small Widget: Solved Streak

struct SmallSolvedWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("⚡")
                .font(.system(size: 34))
            Text("\(entry.data.anysolveStreak)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text("days solved")
                .font(.caption2)
                .foregroundStyle(Color(white: 0.6))
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "leetcodelytics://dashboard"))
    }
}

// MARK: - Small Widget: Daily Question Streak

struct SmallDCCWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 34))
            Text("\(entry.data.dccStreak)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text("daily streak")
                .font(.caption2)
                .foregroundStyle(Color(white: 0.6))
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "leetcodelytics://dashboard"))
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        HStack(spacing: 0) {
            StreakPill(icon: "⚡", value: entry.data.anysolveStreak, label: "Solved")
                .frame(maxWidth: .infinity)

            Divider()
                .background(Color(white: 0.3))
                .frame(height: 50)

            StreakPill(icon: "🔥", value: entry.data.dccStreak, label: "Daily Q")
                .frame(maxWidth: .infinity)

            Divider()
                .background(Color(white: 0.3))
                .frame(height: 50)

            VStack(spacing: 4) {
                DifficultyDot(label: "E", value: entry.data.easySolved, color: .green)
                DifficultyDot(label: "M", value: entry.data.mediumSolved, color: .orange)
                DifficultyDot(label: "H", value: entry.data.hardSolved, color: .red)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "leetcodelytics://dashboard"))
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                StreakPill(icon: "⚡", value: entry.data.anysolveStreak, label: "Solved")
                    .frame(maxWidth: .infinity)
                StreakPill(icon: "🔥", value: entry.data.dccStreak, label: "Daily Q")
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 16) {
                DifficultyDot(label: "E", value: entry.data.easySolved, color: .green)
                DifficultyDot(label: "M", value: entry.data.mediumSolved, color: .orange)
                DifficultyDot(label: "H", value: entry.data.hardSolved, color: .red)
            }

            Divider().background(Color(white: 0.3))

            Text("Activity")
                .font(.caption)
                .foregroundStyle(Color(white: 0.6))

            WidgetHeatmapView(recentCalendar: entry.data.recentCalendar)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "leetcodelytics://dashboard"))
    }
}

// MARK: - Shared sub-views

private struct StreakPill: View {
    let icon: String
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 20))
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.6))
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
                .foregroundStyle(Color.white)
        }
    }
}

// MARK: - Heatmap for Large widget

private let widgetHeatmapCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    cal.firstWeekday = 1
    return cal
}()

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
        let cal = widgetHeatmapCalendar
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
        let ts = Int(widgetHeatmapCalendar.startOfDay(for: date).timeIntervalSince1970)
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
