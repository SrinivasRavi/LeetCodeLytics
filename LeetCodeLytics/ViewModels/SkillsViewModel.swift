import Foundation

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published var tagCounts: TagProblemCounts?
    @Published var languageStats: [LanguageStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    func load(username: String) async {
        let cacheKey = "skills_\(username)"

        // Show cached data immediately if available
        if let cached = CacheService.load(SkillsCache.self, key: cacheKey) {
            tagCounts = cached.tagCounts
            languageStats = cached.languageStats
        }

        isLoading = tagCounts == nil
        errorMessage = nil

        async let skillsTask = service.fetchSkillStats(username: username)
        async let langTask = service.fetchLanguageStats(username: username)

        do {
            let (skills, langs) = try await (skillsTask, langTask)
            tagCounts = skills
            languageStats = langs.sorted { $0.problemsSolved > $1.problemsSolved }
            CacheService.save(SkillsCache(tagCounts: skills, languageStats: languageStats), key: cacheKey)
            CacheService.saveTimestamp(for: cacheKey)
        } catch {
            if tagCounts == nil {
                errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
            }
        }

        isLoading = false
    }
}

private struct SkillsCache: Codable {
    let tagCounts: TagProblemCounts
    let languageStats: [LanguageStat]
}
