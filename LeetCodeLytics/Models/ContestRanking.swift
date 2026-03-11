import Foundation

struct ContestBadge: Codable {
    let name: String
    let icon: String
}

struct ContestInfo: Codable {
    let title: String
    let startTime: Int
}

struct ContestHistory: Codable, Identifiable {
    let attended: Bool
    let trendDirection: String?
    let problemsSolved: Int
    let totalProblems: Int
    let finishTimeInSeconds: Int
    let rating: Double
    let ranking: Int
    let contest: ContestInfo

    var id: String { contest.title }

    var date: Date {
        Date(timeIntervalSince1970: Double(contest.startTime))
    }
}

struct ContestRanking: Codable {
    let rating: Double
    let globalRanking: Int
    let localRanking: Int?
    let topPercentage: Double?
    let badge: ContestBadge?
    let contestHistory: [ContestHistory]?
}

struct ContestRankingInfo: Codable {
    let userContestRankingInfo: ContestRanking?
}
