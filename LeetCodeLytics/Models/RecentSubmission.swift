import Foundation

struct RecentSubmission: Codable, Identifiable {
    let title: String
    let titleSlug: String
    let timestamp: String
    let statusDisplay: String
    let lang: String

    var id: String { titleSlug + timestamp }

    var date: Date {
        Date(timeIntervalSince1970: Double(timestamp) ?? 0)
    }

    var relativeTime: String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<60:
            return "just now"
        case ..<3600:
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        case ..<86400:
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        case ..<604800:
            let days = Int(interval / 86400)
            return "\(days)d ago"
        default:
            let weeks = Int(interval / 604800)
            return "\(weeks)w ago"
        }
    }

}
