import Foundation

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published var tagCounts: TagProblemCounts?
    @Published var languageStats: [LanguageStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    func load(username: String) async {
        isLoading = true
        errorMessage = nil
        async let skillsTask = service.fetchSkillStats(username: username)
        async let langTask = service.fetchLanguageStats(username: username)
        do {
            let (skills, langs) = try await (skillsTask, langTask)
            tagCounts = skills
            languageStats = langs.sorted { $0.problemsSolved > $1.problemsSolved }
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
