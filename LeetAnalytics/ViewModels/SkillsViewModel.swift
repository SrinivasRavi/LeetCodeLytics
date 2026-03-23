import Foundation
import SwiftUI

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published var tagCounts: TagProblemCounts?
    @Published var languageStats: [LanguageStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Muscle Memory — topic suggestions computed from cached tag data
    @Published var topicSuggestions: [TopicSuggestion] = []

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
            computeTopicSuggestions(from: cached)
        }

        isLoading = tagCounts == nil
        errorMessage = nil

        await withCancellationSafeTask {
            async let skillsTask = self.service.fetchSkillStats(username: username)
            async let langTask = self.service.fetchLanguageStats(username: username)

            do {
                let (skills, langs) = try await (skillsTask, langTask)
                self.tagCounts = skills
                self.updateTopTags(from: skills)
                self.languageStats = langs.sorted { $0.problemsSolved > $1.problemsSolved }

                // Fetch tag totals and problem suggestions for Muscle Memory
                let tagTotals = await self.fetchTagTotals(from: skills)
                let tagProblems = await self.fetchTagProblems(from: skills)

                let cache = SkillsCache(
                    tagCounts: skills,
                    languageStats: self.languageStats,
                    tagTotals: tagTotals,
                    tagProblems: tagProblems
                )
                CacheService.save(cache, key: cacheKey)
                CacheService.saveTimestamp(for: cacheKey)

                self.computeTopicSuggestions(from: cache)
            } catch {
                self.errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
            }

            self.isLoading = false
        }
    }

    private func updateTopTags(from counts: TagProblemCounts) {
        topAdvanced = Array(counts.advanced.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10))
        topIntermediate = Array(counts.intermediate.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10))
        topFundamental = Array(counts.fundamental.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10))
    }

    /// Computes the 3 topics with lowest solved/total ratio.
    private func computeTopicSuggestions(from cache: SkillsCache) {
        let counts = cache.tagCounts
        let tagTotals = cache.tagTotals
        let tagProblems = cache.tagProblems
        let recentSlugs = UniqueProblemStore.recentSlugs()

        var all: [TopicSuggestion] = []

        func build(tag: TagStat, level: String, color: Color) -> TopicSuggestion {
            let total = tagTotals[tag.tagSlug] ?? 0
            let ratio = total > 0 ? Double(tag.problemsSolved) / Double(total) : 1.0
            let problems = (tagProblems[tag.tagSlug] ?? [])
                .filter { !recentSlugs.contains($0.titleSlug) }
            return TopicSuggestion(
                tagName: tag.tagName, tagSlug: tag.tagSlug,
                problemsSolved: tag.problemsSolved, totalProblems: total,
                ratio: ratio, level: level, color: color,
                suggestedProblems: Array(problems.prefix(3))
            )
        }

        for tag in counts.advanced { all.append(build(tag: tag, level: "Advanced", color: .red)) }
        for tag in counts.intermediate { all.append(build(tag: tag, level: "Intermediate", color: .orange)) }
        for tag in counts.fundamental { all.append(build(tag: tag, level: "Fundamental", color: .green)) }

        topicSuggestions = Array(all.sorted { $0.ratio < $1.ratio }.prefix(3))
    }

    /// Fetches total question counts for every tag the user has solved at least one problem in.
    private func fetchTagTotals(from counts: TagProblemCounts) async -> [String: Int] {
        let allTags = counts.advanced + counts.intermediate + counts.fundamental
        return await withTaskGroup(of: (String, Int).self) { group in
            for tag in allTags {
                group.addTask {
                    let total = (try? await self.service.fetchProblemsForTag(tagSlug: tag.tagSlug, limit: 0).totalNum) ?? 0
                    return (tag.tagSlug, total)
                }
            }
            var result: [String: Int] = [:]
            for await (slug, total) in group {
                result[slug] = total
            }
            return result
        }
    }

    /// Fetches top 5 problems for every tag. Used for Muscle Memory suggestions.
    private func fetchTagProblems(from counts: TagProblemCounts) async -> [String: [ProblemSummary]] {
        let allTags = counts.advanced + counts.intermediate + counts.fundamental
        return await withTaskGroup(of: (String, [ProblemSummary]).self) { group in
            for tag in allTags {
                group.addTask {
                    let problems = (try? await self.service.fetchProblemsForTag(tagSlug: tag.tagSlug, limit: 5))?.data ?? []
                    return (tag.tagSlug, problems)
                }
            }
            var result: [String: [ProblemSummary]] = [:]
            for await (slug, problems) in group {
                result[slug] = problems
            }
            return result
        }
    }
}

struct SkillsCache: Codable {
    let tagCounts: TagProblemCounts
    let languageStats: [LanguageStat]
    var tagTotals: [String: Int] = [:]
    var tagProblems: [String: [ProblemSummary]] = [:]
}
