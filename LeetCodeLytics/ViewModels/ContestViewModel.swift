import Foundation

@MainActor
final class ContestViewModel: ObservableObject {
    @Published var ranking: ContestRanking?
    @Published var history: [ContestHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    func load(username: String) async {
        let cacheKey = "contest_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load(ContestCache.self, key: cacheKey) {
            ranking = cached.ranking
            history = cached.history
        }

        isLoading = ranking == nil
        errorMessage = nil

        async let rankingTask = service.fetchContestRanking(username: username)
        async let historyTask = service.fetchContestHistory(username: username)

        do {
            let (r, h) = try await (rankingTask, historyTask)
            ranking = r
            history = h.filter { $0.attended }.sorted { $0.contest.startTime > $1.contest.startTime }
            CacheService.save(ContestCache(ranking: ranking, history: history), key: cacheKey)
            CacheService.saveTimestamp(for: cacheKey)
        } catch {
            if ranking == nil {
                errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
            }
        }

        isLoading = false
    }
}

private struct ContestCache: Codable {
    let ranking: ContestRanking?
    let history: [ContestHistory]
}
