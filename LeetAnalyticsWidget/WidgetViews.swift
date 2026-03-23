import SwiftUI
import WidgetKit

// MARK: - Small Widget: Solved Streak

struct SmallSolvedWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("⚡ \(entry.data.anysolveStreak) \(entry.data.anysolveStreak == 1 ? "day" : "days")")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text("Solved Streak")
                .font(.caption)
                .foregroundStyle(Color(white: 0.75))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
        .widgetURL(URL(string: "leetanalytics://dashboard"))
    }
}

// MARK: - Small Widget: Daily Question Streak

struct SmallDCCWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 6) {
            if entry.data.isDCCAvailable {
                Text("🔥 \(entry.data.dccStreak) \(entry.data.dccStreak == 1 ? "day" : "days")")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            } else {
                Text("🔥 –")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            Text("Daily Question Streak")
                .font(.caption)
                .foregroundStyle(Color(white: 0.75))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
        .widgetURL(URL(string: entry.data.isDCCAvailable
            ? "leetanalytics://dashboard"
            : "leetanalytics://login"))
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StreakPill(icon: "⚡", value: entry.data.anysolveStreak, label: "Solved Streak",
                           valueFontSize: 18, labelFontSize: 12)
                    .frame(maxWidth: .infinity)
                StreakPill(icon: "🔥", value: entry.data.dccStreak, label: "Daily Question Streak",
                           valueFontSize: 18, labelFontSize: 12, isAvailable: entry.data.isDCCAvailable)
                    .frame(maxWidth: .infinity)
            }

            Spacer()

            HStack(spacing: 16) {
                DifficultyDot(label: "Easy",   value: entry.data.easySolved,   color: .green,  fontSize: 13)
                DifficultyDot(label: "Medium", value: entry.data.mediumSolved, color: .orange, fontSize: 13)
                DifficultyDot(label: "Hard",   value: entry.data.hardSolved,   color: .red,    fontSize: 13)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "leetanalytics://dashboard"))
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: LeetCodeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                StreakPill(icon: "⚡", value: entry.data.anysolveStreak, label: "Solved Streak")
                    .frame(maxWidth: .infinity)
                StreakPill(icon: "🔥", value: entry.data.dccStreak, label: "Daily Question Streak",
                           isAvailable: entry.data.isDCCAvailable)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 16) {
                DifficultyDot(label: "Easy",   value: entry.data.easySolved,   color: .green)
                DifficultyDot(label: "Medium", value: entry.data.mediumSolved, color: .orange)
                DifficultyDot(label: "Hard",   value: entry.data.hardSolved,   color: .red)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Divider().background(Color(white: 0.3))

            Text("Activity")
                .font(.caption)
                .foregroundStyle(Color(white: 0.6))

            WidgetHeatmapView(recentCalendar: entry.data.recentCalendar)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "leetanalytics://dashboard"))
    }
}

// MARK: - Shared sub-views

private struct StreakPill: View {
    let icon: String
    let value: Int
    let label: String
    var valueFontSize: CGFloat = 16
    var labelFontSize: CGFloat = 10
    var isAvailable: Bool = true

    var body: some View {
        VStack(spacing: 3) {
            Text(isAvailable
                 ? "\(icon) \(value) \(value == 1 ? "day" : "days")"
                 : "\(icon) –")
                .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(label)
                .font(.system(size: labelFontSize))
                .foregroundStyle(Color(white: 0.65))
                .multilineTextAlignment(.center)
        }
    }
}

private struct DifficultyDot: View {
    let label: String
    let value: Int
    let color: Color
    var fontSize: CGFloat = 11

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(label): \(value)")
                .font(.system(size: fontSize))
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

private let widgetMonthFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM"
    df.timeZone = TimeZone(identifier: "UTC")
    return df
}()

// Heatmap cell colors — file-level constants so they are created once per process,
// not on every body evaluation across 175 cells.
private let widgetHeatmapColorEmpty = Color.gray.opacity(0.2)
private let widgetHeatmapColorLight = Color(red: 1, green: 0.631, blue: 0.086).opacity(0.4)
private let widgetHeatmapColorMid   = Color(red: 1, green: 0.631, blue: 0.086).opacity(0.65)
private let widgetHeatmapColorFull  = Color(red: 1, green: 0.631, blue: 0.086)

struct WidgetHeatmapView: View {
    let recentCalendar: [String: Int]
    private let cellSize: CGFloat = 10
    private let spacing: CGFloat = 2
    // All three derived collections computed once in init — never rebuilt on body evaluation.
    private let dailyCounts: [Int: Int]
    private let allWeeks: [[Date?]]
    private let monthLabelPositions: [(String, Int)]

    init(recentCalendar: [String: Int]) {
        self.recentCalendar = recentCalendar

        self.dailyCounts = Dictionary(
            recentCalendar.compactMap { k, v in Int(k).map { ($0, v) } },
            uniquingKeysWith: { first, _ in first }
        )

        // Build the week grid once. widgetHeatmapCalendar and widgetHeatmapWeeks are
        // file-level constants — safe to read before self is fully initialized.
        let cal = widgetHeatmapCalendar
        let weeks = widgetHeatmapWeeks
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysToSunday = (weekday - 1) % 7

        var computedWeeks: [[Date?]] = []
        if let lastSunday = cal.date(byAdding: .day, value: -daysToSunday, to: today),
           let startDate = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: lastSunday) {
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
                computedWeeks.append(week)
                weekStart = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
            }
        }
        self.allWeeks = computedWeeks

        // Build month label positions once from the same grid.
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for (idx, week) in computedWeeks.enumerated() {
            if let firstDate = week.compactMap({ $0 }).first {
                let month = cal.component(.month, from: firstDate)
                if month != lastMonth {
                    labels.append((widgetMonthFormatter.string(from: firstDate), idx))
                    lastMonth = month
                }
            }
        }
        self.monthLabelPositions = labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Month labels
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: 14)
                ForEach(monthLabelPositions, id: \.1) { label, col in
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(Color(white: 0.55))
                        .offset(x: CGFloat(col) * (cellSize + spacing))
                }
            }

            // Grid
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(allWeeks.enumerated()), id: \.offset) { _, week in
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
    }

    private func countFor(date: Date) -> Int {
        let ts = Int(widgetHeatmapCalendar.startOfDay(for: date).timeIntervalSince1970)
        return dailyCounts[ts] ?? 0
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0:  return widgetHeatmapColorEmpty
        case 1:  return widgetHeatmapColorLight
        case 2:  return widgetHeatmapColorMid
        default: return widgetHeatmapColorFull
        }
    }
}
