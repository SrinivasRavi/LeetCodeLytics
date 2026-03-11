import SwiftUI
import Charts

struct ContestView: View {
    @AppStorage("username") private var username = ""
    @StateObject private var vm = ContestViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading && vm.ranking == nil {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let ranking = vm.ranking {
                    VStack(spacing: 16) {
                        // Rating Card
                        RatingCard(ranking: ranking)

                        // Rating History Chart
                        if !vm.history.isEmpty {
                            RatingChartView(history: vm.history)

                            // Contest List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Contests")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                ForEach(vm.history.prefix(10)) { contest in
                                    ContestRow(contest: contest)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "wifi.slash",
                        description: Text(error)
                    )
                } else {
                    ContentUnavailableView(
                        "No Contest Data",
                        systemImage: "trophy",
                        description: Text("No contest history found for this user.")
                    )
                }
            }
            .navigationTitle("Contest")
            .toolbar {
                if vm.isLoading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
        .task {
            await vm.load(username: username)
        }
    }
}

private struct RatingCard: View {
    let ranking: ContestRanking

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contest Rating")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f", ranking.rating))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(Color(hex: "FFA116"))
                }
                Spacer()
                if let badge = ranking.badge {
                    AsyncImage(url: URL(string: badge.icon)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "medal")
                            .foregroundColor(Color(hex: "FFA116"))
                            .font(.largeTitle)
                    }
                    .frame(width: 60, height: 60)
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            HStack {
                StatItem(value: "#\(ranking.globalRanking.formatted())", label: "Global Rank")
                if let pct = ranking.topPercentage {
                    StatItem(value: String(format: "Top %.1f%%", pct), label: "Percentile")
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RatingChartView: View {
    let history: [ContestHistory]

    private var chartData: [ContestHistory] {
        history.sorted { $0.contest.startTime < $1.contest.startTime }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating History")
                .font(.headline)
                .foregroundColor(.white)

            Chart(chartData) { contest in
                LineMark(
                    x: .value("Date", contest.date),
                    y: .value("Rating", contest.rating)
                )
                .foregroundStyle(Color(hex: "FFA116"))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", contest.date),
                    y: .value("Rating", contest.rating)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FFA116").opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct ContestRow: View {
    let contest: ContestHistory

    private var trendIcon: String {
        switch contest.trendDirection {
        case "UP": return "arrow.up.right"
        case "DOWN": return "arrow.down.right"
        default: return "minus"
        }
    }

    private var trendColor: Color {
        switch contest.trendDirection {
        case "UP": return .green
        case "DOWN": return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trendIcon)
                .foregroundColor(trendColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(contest.contest.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("\(contest.problemsSolved)/\(contest.totalProblems) solved · Rank \(contest.ranking.formatted())")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(String(format: "%.0f", contest.rating))
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "FFA116"))
        }
        .padding(.vertical, 4)
    }
}
