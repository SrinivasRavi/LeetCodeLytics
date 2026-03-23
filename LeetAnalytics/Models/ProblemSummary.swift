import Foundation

struct ProblemSummary: Codable, Identifiable {
    let questionFrontendId: String
    let title: String
    let titleSlug: String
    let difficulty: String

    var id: String { titleSlug }
}

struct QuestionListResponse: Codable {
    let totalNum: Int
    let data: [ProblemSummary]
}
