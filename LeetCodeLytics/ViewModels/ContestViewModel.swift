import Foundation

@MainActor
final class ContestViewModel: ObservableObject {
    @Published var ranking: ContestRanking?
    @Published var history: [ContestHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    func load(username: String) async {
        isLoading = true
        errorMessage = nil
        async let rankingTask = service.fetchContestRanking(username: username)
        async let historyTask = service.fetchContestHistory(username: username)
        do {
            let (r, h) = try await (rankingTask, historyTask)
            ranking = r
            history = h.filter { $0.attended }.sorted { $0.contest.startTime > $1.contest.startTime }
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
