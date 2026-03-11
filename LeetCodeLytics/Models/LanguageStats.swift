import Foundation

struct LanguageStat: Codable, Identifiable {
    let languageName: String
    let problemsSolved: Int
    var id: String { languageName }
}

struct TagStat: Codable, Identifiable {
    let tagName: String
    let tagSlug: String
    let problemsSolved: Int
    var id: String { tagSlug }
}

struct TagProblemCounts: Codable {
    let advanced: [TagStat]
    let intermediate: [TagStat]
    let fundamental: [TagStat]
}

struct SkillStatsMatchedUser: Codable {
    let tagProblemCounts: TagProblemCounts
}

struct SkillStats: Codable {
    let matchedUser: SkillStatsMatchedUser
}

struct LanguageStatsMatchedUser: Codable {
    let languageProblemCount: [LanguageStat]
}

struct LanguageStatsResponse: Codable {
    let matchedUser: LanguageStatsMatchedUser
}
