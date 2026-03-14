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

