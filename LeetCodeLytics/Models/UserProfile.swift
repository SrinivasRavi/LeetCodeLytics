import Foundation

struct SubmissionCount: Codable {
    let difficulty: String
    let count: Int
    let submissions: Int
}

struct SubmitStats: Codable {
    let acSubmissionNum: [SubmissionCount]
    let totalSubmissionNum: [SubmissionCount]
}

struct UserProfileInfo: Codable {
    let ranking: Int
    let userAvatar: String
    let realName: String
    let reputation: Int
}

struct UserBadge: Codable {
    let id: String?
    let name: String
    let icon: String
    let creationDate: String?
}

struct MatchedUser: Codable {
    let username: String
    let profile: UserProfileInfo
    let submitStats: SubmitStats
    let badges: [UserBadge]
}

struct ProblemCount: Codable {
    let difficulty: String
    let count: Int
}

struct UserProfileResponse: Codable {
    let matchedUser: MatchedUser
    let allQuestionsCount: [ProblemCount]

    var easySolved: Int {
        matchedUser.submitStats.acSubmissionNum.first { $0.difficulty == "Easy" }?.count ?? 0
    }
    var mediumSolved: Int {
        matchedUser.submitStats.acSubmissionNum.first { $0.difficulty == "Medium" }?.count ?? 0
    }
    var hardSolved: Int {
        matchedUser.submitStats.acSubmissionNum.first { $0.difficulty == "Hard" }?.count ?? 0
    }
    var totalSolved: Int {
        matchedUser.submitStats.acSubmissionNum.first { $0.difficulty == "All" }?.count ?? 0
    }
    var totalEasy: Int {
        allQuestionsCount.first { $0.difficulty == "Easy" }?.count ?? 0
    }
    var totalMedium: Int {
        allQuestionsCount.first { $0.difficulty == "Medium" }?.count ?? 0
    }
    var totalHard: Int {
        allQuestionsCount.first { $0.difficulty == "Hard" }?.count ?? 0
    }
    var totalQuestions: Int {
        allQuestionsCount.first { $0.difficulty == "All" }?.count ?? 0
    }
    var totalSubmissions: Int {
        matchedUser.submitStats.totalSubmissionNum.first { $0.difficulty == "All" }?.submissions ?? 0
    }
    var totalAccepted: Int {
        matchedUser.submitStats.acSubmissionNum.first { $0.difficulty == "All" }?.submissions ?? 0
    }
    var acceptanceRate: Double {
        guard totalSubmissions > 0 else { return 0 }
        return Double(totalAccepted) / Double(totalSubmissions) * 100
    }
}
