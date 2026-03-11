import SwiftUI

struct CalendarView: View {
    @AppStorage("username") private var username = ""
    @StateObject private var vm = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.isLoading && vm.submissionCalendar == nil {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let calendar = vm.submissionCalendar {
                        VStack(alignment: .leading, spacing: 16) {
                            // Stats summary
                            if let streak = vm.streakData {
                                HStack(spacing: 0) {
                                    StatPill(value: "\(streak.totalActiveDays)", label: "Active Days")
                                    StatPill(value: "\(streak.streak)", label: "Current Streak")
                                    StatPill(value: "\(streak.activeYears.count)", label: "Active Years")
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(16)
                            }

                            // Heatmap
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Submission Activity")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HeatmapGridView(calendar: calendar)
                                        .padding(.bottom, 8)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(16)
                        }
                    } else if let error = vm.errorMessage {
                        ContentUnavailableView(
                            "Failed to Load",
                            systemImage: "wifi.slash",
                            description: Text(error)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Calendar")
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

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
