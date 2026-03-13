import Foundation

@MainActor
final class SubmissionsViewModel: ObservableObject {
    @Published var submissions: [RecentSubmission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: LeetCodeServiceProtocol

    init(service: LeetCodeServiceProtocol = LeetCodeService.shared) {
        self.service = service
    }

    func load(username: String) async {
        let cacheKey = "submissions_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load([RecentSubmission].self, key: cacheKey) {
            submissions = cached
        }

        isLoading = submissions.isEmpty
        errorMessage = nil

        do {
            let fresh = try await service.fetchRecentSubmissions(username: username)
            submissions = fresh
            CacheService.save(fresh, key: cacheKey)
            CacheService.saveTimestamp(for: cacheKey)
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
