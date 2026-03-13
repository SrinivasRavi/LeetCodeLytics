import SwiftUI

private let heatmapDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    return df
}()

struct HeatmapGridView: View {
    let calendar: SubmissionCalendar
    @State private var selectedDate: Date?
    @State private var selectedCount: Int?

    private let columns = 52
    private let rows = 7
    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3

    private var weeks: [[Date?]] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1 // Sunday

        let today = cal.startOfDay(for: Date())
        // Go back to end of last full week
        let weekday = cal.component(.weekday, from: today)
        let daysToSunday = (weekday - 1) % 7
        guard let lastSunday = cal.date(byAdding: .day, value: -daysToSunday, to: today) else { return [] }

        // We want 52 weeks ending at lastSunday + 6 days (Saturday)
        guard let startDate = cal.date(byAdding: .weekOfYear, value: -(columns - 1), to: lastSunday) else { return [] }

        var weeks: [[Date?]] = []
        var weekStart = startDate

        for _ in 0..<columns {
            var week: [Date?] = []
            for day in 0..<rows {
                if let date = cal.date(byAdding: .day, value: day, to: weekStart) {
                    week.append(date <= today ? date : nil)
                } else {
                    week.append(nil)
                }
            }
            weeks.append(week)
            weekStart = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        }
        return weeks
    }

    private var monthLabels: [(String, Int)] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let df = DateFormatter()
        df.dateFormat = "MMM"
        df.timeZone = TimeZone(identifier: "UTC")

        var labels: [(String, Int)] = []
        var lastMonth = -1

        for (idx, week) in weeks.enumerated() {
            if let firstDate = week.first(where: { $0 != nil }) as? Date {
                let month = cal.component(.month, from: firstDate)
                if month != lastMonth {
                    labels.append((df.string(from: firstDate), idx))
                    lastMonth = month
                }
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: 16)
                ForEach(monthLabels, id: \.1) { label, col in
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
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
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }

    private func solveCount(for date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let start = cal.startOfDay(for: date)
        let ts = Int(start.timeIntervalSince1970)
        return calendar.dailyCounts[ts] ?? 0
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color(hex: "FFA116").opacity(0.3)
        case 2: return Color(hex: "FFA116").opacity(0.5)
        case 3: return Color(hex: "FFA116").opacity(0.7)
        default: return Color(hex: "FFA116")
        }
    }
}
