import SwiftUI

struct SubmissionsView: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @StateObject private var vm = SubmissionsViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Submissions").tag(0)
                    Text("Unique Problems").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectedTab == 0 {
                    submissionsContent
                } else {
                    uniqueProblemsContent
                }
            }
            .navigationTitle("Activity")
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

    // MARK: - Submissions Sub-Tab

    private var submissionsContent: some View {
        ScrollView {
            if vm.isLoading && vm.submissions.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if !vm.submissions.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(vm.submissions) { submission in
                        SubmissionRow(submission: submission)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        Divider()
                            .padding(.leading, 16)
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            } else if let error = vm.errorMessage {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "wifi.slash",
                    description: Text(error)
                )
                .frame(minHeight: 300)
            } else {
                ContentUnavailableView(
                    "No Submissions",
                    systemImage: "tray",
                    description: Text("No recent submissions found.")
                )
                .frame(minHeight: 300)
            }
        }
        .refreshable {
            await vm.load(username: username)
        }
    }

    // MARK: - Unique Problems Sub-Tab

    private var uniqueProblemsContent: some View {
        let entries = UniqueProblemStore.recentEntries()
        return ScrollView {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Problems Tracked",
                    systemImage: "tray",
                    description: Text("Accepted submissions will appear here as you use the app.")
                )
                .frame(minHeight: 300)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("\(entries.count) unique problems")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Last \(Int(UniqueProblemStore.rollingWindowDays)) days")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding()

                    Divider()

                    LazyVStack(spacing: 0) {
                        ForEach(entries, id: \.slug) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Text(entry.slug)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                Text(Date(timeIntervalSince1970: entry.solvedAt), style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
    }
}

private struct SubmissionRow: View {
    let submission: RecentSubmission

    private var statusColor: Color {
        switch submission.statusDisplay {
        case "Accepted": return .green
        case "Wrong Answer": return .red
        case "Time Limit Exceeded": return .orange
        case "Runtime Error", "Compile Error": return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(submission.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text(submission.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 8) {
                Text(submission.statusDisplay)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)

                Text("·")
                    .foregroundStyle(.gray)

                Text(submission.lang)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
