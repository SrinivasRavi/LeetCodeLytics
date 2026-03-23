import Foundation

@MainActor
final class SubmissionsViewModel: ObservableObject {
    @Published var submissions: [RecentSubmission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: LeetCodeServiceProtocol
    private var activeFetch = false

    init(service: LeetCodeServiceProtocol = LeetCodeService.shared) {
        self.service = service
    }

    func load(username: String) async {
        guard !activeFetch else { return }
        activeFetch = true
        defer { activeFetch = false }
        let cacheKey = "submissions_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load([RecentSubmission].self, key: cacheKey) {
            submissions = cached
        }

        isLoading = submissions.isEmpty
        errorMessage = nil

        await withCancellationSafeTask {
            do {
                let fresh = try await self.service.fetchRecentSubmissions(username: username)
                self.submissions = fresh
                CacheService.save(fresh, key: cacheKey)
                CacheService.saveTimestamp(for: cacheKey)
            } catch {
                self.errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
            }

            self.isLoading = false
        }
    }
}
