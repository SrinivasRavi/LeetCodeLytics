import SwiftUI

struct SubmissionsView: View {
    @AppStorage("username") private var username = ""
    @StateObject private var vm = SubmissionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.submissions.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if !vm.submissions.isEmpty {
                    List(vm.submissions) { submission in
                        SubmissionRow(submission: submission)
                            .listRowBackground(Color(UIColor.secondarySystemBackground))
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "wifi.slash",
                        description: Text(error)
                    )
                } else {
                    ContentUnavailableView(
                        "No Submissions",
                        systemImage: "tray",
                        description: Text("No recent submissions found.")
                    )
                }
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
