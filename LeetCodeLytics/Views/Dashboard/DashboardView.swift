import SwiftUI

struct DashboardView: View {
    @AppStorage("username") private var username = ""
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading && vm.profile == nil {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let profile = vm.profile {
                    VStack(spacing: 16) {
                        ProfileHeaderView(profile: profile)

                        ProblemStatsCard(
                            easySolved: vm.easySolved,
                            mediumSolved: vm.mediumSolved,
                            hardSolved: vm.hardSolved,
                            totalSolved: vm.totalSolved,
                            totalEasy: vm.totalEasy,
                            totalMedium: vm.totalMedium,
                            totalHard: vm.totalHard
                        )

                        StreakCard(
                            dccStreak: vm.dccStreak,
                            anysolveStreak: vm.anysolveStreak,
                            maxStreak: vm.streakData?.streak ?? 0,
                            totalActiveDays: vm.streakData?.totalActiveDays ?? 0
                        )

                        AcceptanceRateView(rate: vm.acceptanceRate)

                        if let calendar = vm.submissionCalendar {
                            HeatmapCard(calendar: calendar)
                        }

                        if !profile.badges.isEmpty {
                            BadgesView(badges: profile.badges)
                        }
                    }
                    .padding()
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "wifi.slash",
                        description: Text(error)
                    )
                }
            }
            .navigationTitle("Dashboard")
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

private struct HeatmapCard: View {
    let calendar: SubmissionCalendar

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Submission Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("Last 52 weeks")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HeatmapGridView(calendar: calendar)
                    .padding(.bottom, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct BadgesView: View {
    let badges: [UserBadge]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(badges, id: \.name) { badge in
                        VStack(spacing: 4) {
                            AsyncImage(url: URL(string: badge.icon)) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "rosette")
                                    .foregroundColor(Color(hex: "FFA116"))
                            }
                            .frame(width: 40, height: 40)

                            Text(badge.name)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
