import Foundation

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published var tagCounts: TagProblemCounts?
    @Published var languageStats: [LanguageStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: LeetCodeServiceProtocol
    private var activeFetch = false

    init(service: LeetCodeServiceProtocol = LeetCodeService.shared) {
        self.service = service
    }

    // Stored @Published arrays — sorted once at fetch/cache time, not on every access.
    @Published private(set) var topAdvanced: [TagStat] = []
    @Published private(set) var topIntermediate: [TagStat] = []
    @Published private(set) var topFundamental: [TagStat] = []

    func load(username: String) async {
        guard !activeFetch else { return }
        activeFetch = true
        defer { activeFetch = false }
        let cacheKey = "skills_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load(SkillsCache.self, key: cacheKey) {
            tagCounts = cached.tagCounts
            languageStats = cached.languageStats
            updateTopTags(from: cached.tagCounts)
        }

        isLoading = tagCounts == nil
        errorMessage = nil

        async let skillsTask = service.fetchSkillStats(username: username)
        async let langTask = service.fetchLanguageStats(username: username)

        do {
            let (skills, langs) = try await (skillsTask, langTask)
            tagCounts = skills
            updateTopTags(from: skills)
            languageStats = langs.sorted { $0.problemsSolved > $1.problemsSolved }
            CacheService.save(SkillsCache(tagCounts: skills, languageStats: languageStats), key: cacheKey)
            CacheService.saveTimestamp(for: cacheKey)
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    private func updateTopTags(from counts: TagProblemCounts) {
        topAdvanced = Array(counts.advanced.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10))
        topIntermediate = Array(counts.intermediate.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10))
        topFundamental = Array(counts.fundamental.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10))
    }
}

private struct SkillsCache: Codable {
    let tagCounts: TagProblemCounts
    let languageStats: [LanguageStat]
}
