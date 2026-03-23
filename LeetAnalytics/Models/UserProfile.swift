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
    let userAvatar: String?
    let realName: String?
}

struct UserBadge: Codable, Identifiable {
    // `badgeID` holds the raw API "id" field (a numeric string like "7588899", may be absent).
    // The Codable mapping is done via CodingKeys so the API "id" field decodes into `badgeID`.
    let badgeID: String?
    let name: String
    let icon: String
    let creationDate: String?

    // Stable, non-optional key for `Identifiable` and SwiftUI `ForEach`.
    // Falls back to `name` if the API did not supply an id — badges have unique names.
    var id: String { badgeID ?? name }

    enum CodingKeys: String, CodingKey {
        case badgeID = "id"
        case name, icon, creationDate
    }
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

