import SwiftUI

// Static instances — DateFormatter and Calendar are expensive to create.
// These are shared across all HeatmapGridView renders.
private let heatmapDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    return df
}()

private let heatmapMonthFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM"
    df.timeZone = TimeZone(identifier: "UTC")
    return df
}()

// Pre-computed heatmap colours — evaluated once per process, not per cell per render.
// With 364 cells, inlining Color(hex:) would run Scanner + bit-shifts 364 times per render.
private let heatmapColorEmpty   = Color.gray.opacity(0.15)
private let heatmapColorLight   = Color.leetcodeOrange.opacity(0.3)
private let heatmapColorMid     = Color.leetcodeOrange.opacity(0.5)
private let heatmapColorHigh    = Color.leetcodeOrange.opacity(0.7)
private let heatmapColorMax     = Color.leetcodeOrange

private let heatmapCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    cal.firstWeekday = 1
    return cal
}()

struct HeatmapGridView: View {
    let calendar: SubmissionCalendar
    @State private var selectedDate: Date?
    @State private var selectedCount: Int?

    private let columns = 52
    private let rows = 7
    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3

    // Builds the 52×7 grid of dates. Called once per body render via local variable.
    private func buildWeeks() -> [[Date?]] {
        let today = heatmapCalendar.startOfDay(for: Date())
        let weekday = heatmapCalendar.component(.weekday, from: today)
        let daysToSunday = (weekday - 1) % 7
        guard let lastSunday = heatmapCalendar.date(byAdding: .day, value: -daysToSunday, to: today),
              let startDate = heatmapCalendar.date(byAdding: .weekOfYear, value: -(columns - 1), to: lastSunday)
        else { return [] }

        var result: [[Date?]] = []
        var weekStart = startDate
        for _ in 0..<columns {
            var week: [Date?] = []
            for day in 0..<rows {
                if let date = heatmapCalendar.date(byAdding: .day, value: day, to: weekStart) {
                    week.append(date <= today ? date : nil)
                } else {
                    week.append(nil)
                }
            }
            result.append(week)
            weekStart = heatmapCalendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        }
        return result
    }

    // Derives month labels from an already-computed weeks array — no second computation.
    private func buildMonthLabels(from weeks: [[Date?]]) -> [(String, Int)] {
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for (idx, week) in weeks.enumerated() {
            if let firstDate = week.compactMap({ $0 }).first {
                let month = heatmapCalendar.component(.month, from: firstDate)
                if month != lastMonth {
                    labels.append((heatmapMonthFormatter.string(from: firstDate), idx))
                    lastMonth = month
                }
            }
        }
        return labels
    }

    var body: some View {
        // Compute once — used for both the grid and month labels below.
        let weeks = buildWeeks()
        let monthLabels = buildMonthLabels(from: weeks)

        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: 16)
                ForEach(monthLabels, id: \.1) { label, col in
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                        .offset(x: CGFloat(col) * (cellSize + spacing))
                }
            }

            // Grid
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: spacing) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                            if let date = date {
                                let count = solveCount(for: date)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(heatmapColor(count: count))
                                    .frame(width: cellSize, height: cellSize)
                                    .onTapGesture {
                                        selectedDate = date
                                        selectedCount = count
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.clear)
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }

            if let date = selectedDate, let count = selectedCount {
                Text("\(count) solve\(count == 1 ? "" : "s") on \(heatmapDateFormatter.string(from: date))")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 4)
            }
        }
    }

    private func solveCount(for date: Date) -> Int {
        // Dates in `weeks` are already start-of-day values (built by buildWeeks via startOfDay).
        // The redundant startOfDay call is omitted — it added 364 Calendar operations per render.
        let ts = Int(date.timeIntervalSince1970)
        return calendar.dailyCounts[ts] ?? 0
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0:  return heatmapColorEmpty
        case 1:  return heatmapColorLight
        case 2:  return heatmapColorMid
        case 3:  return heatmapColorHigh
        default: return heatmapColorMax
        }
    }
}
