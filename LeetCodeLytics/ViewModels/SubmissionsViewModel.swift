import Foundation

@MainActor
final class SubmissionsViewModel: ObservableObject {
    @Published var submissions: [RecentSubmission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    func load(username: String) async {
        isLoading = true
        errorMessage = nil
        do {
            submissions = try await service.fetchRecentSubmissions(username: username)
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
