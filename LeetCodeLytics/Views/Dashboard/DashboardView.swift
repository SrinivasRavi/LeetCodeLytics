import SwiftUI

// File-level static — RelativeDateTimeFormatter init is expensive; create once per process.
private let dashboardRelativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f
}()

struct DashboardView: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @StateObject private var vm = DashboardViewModel()
    @State private var lastUpdatedText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading && vm.profile == nil {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    VStack(spacing: 16) {
                        // Inline error banner — shown even when cached data is visible
                        if let error = vm.errorMessage {
                            if vm.profile != nil {
                                RefreshErrorBanner(message: error)
                            } else {
                                ContentUnavailableView(
                                    "Failed to Load",
                                    systemImage: "wifi.slash",
                                    description: Text(error)
                                )
                            }
                        }

                        if let profile = vm.profile {
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

                            AcceptanceRateView(rate: vm.acceptanceRate)

                            CurrentStreakCard(
                                dccStreak: vm.dccStreak,
                                anysolveStreak: vm.anysolveStreak
                            )

                            if let calendar = vm.submissionCalendar {
                                Last52WeeksCard(
                                    maxStreak: vm.streakData?.streak ?? 0,
                                    totalActiveDays: vm.streakData?.totalActiveDays ?? 0,
                                    calendar: calendar
                                )
                            }

                            if !profile.badges.isEmpty {
                                BadgesView(badges: profile.badges)
                            }
                        }
                    }
                    .padding()
                }
            }
            .refreshable {
                await vm.load(username: username)
                refreshTimestamp()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.isLoading {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !lastUpdatedText.isEmpty {
                        Text(lastUpdatedText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .task {
            await vm.load(username: username)
            refreshTimestamp()
        }
    }

    private func refreshTimestamp() {
        let cacheKey = "dashboard_\(username)"
        guard let ts = CacheService.timestamp(for: cacheKey) else { return }
        lastUpdatedText = "Updated \(dashboardRelativeFormatter.localizedString(for: ts, relativeTo: Date()))"
    }
}

private struct RefreshErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            Text("Refresh failed: \(message)")
                .font(.caption)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct Last52WeeksCard: View {
    let maxStreak: Int
    let totalActiveDays: Int
    let calendar: SubmissionCalendar

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 52 weeks")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 0) {
                StreakItem(value: maxStreak, icon: "🏆", label: "Max Streak")
                Divider().background(Color.gray.opacity(0.3)).frame(height: 50)
                StreakItem(value: totalActiveDays, icon: "📅", label: "Active for")
            }

            Divider().background(Color.gray.opacity(0.2))

            HStack {
                Text("Submission Activity")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
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

private let badgeInputFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    return df
}()

private let badgeDisplayFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
}()

private struct BadgesView: View {
    let badges: [UserBadge]

    private func formattedDate(_ raw: String?) -> String? {
        guard let raw, let date = badgeInputFormatter.date(from: raw) else { return nil }
        return badgeDisplayFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                        VStack(spacing: 4) {
                            AsyncImage(url: URL(string: badge.icon)) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "rosette")
                                    .foregroundColor(Color(hex: "FFA116"))
                            }
                            .frame(width: 44, height: 44)

                            Text(badge.name)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 70)

                            if let date = formattedDate(badge.creationDate) {
                                Text(date)
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 70)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
