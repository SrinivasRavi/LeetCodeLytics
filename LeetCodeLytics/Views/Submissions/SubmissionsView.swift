import SwiftUI

struct SubmissionsView: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @StateObject private var vm = SubmissionsViewModel()

    var body: some View {
        NavigationStack {
            // ScrollView wraps all states so .refreshable works even when the
            // list is empty or an error is showing — not just when data is present.
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
            .navigationTitle("Submissions")
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
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text(submission.relativeTime)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 8) {
                Text(submission.statusDisplay)
                    .font(.caption.weight(.medium))
                    .foregroundColor(statusColor)

                Text("·")
                    .foregroundColor(.gray)

                Text(submission.lang)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
