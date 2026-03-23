import Foundation

/// Number of weeks of submission history shared between DashboardViewModel (which writes
/// the calendar slice) and WidgetHeatmapView (which reads it). Both must agree on this value.
let widgetHeatmapWeeks = 25

// File-level constant — created once per process (CLAUDE.md: never inside computed properties).
private let sharedUTCCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}()

/// Returns true if recentCalendar contains at least one solve for today (UTC).
/// Compiled into both app and widget targets via Shared/ so both can call it.
/// Missing key = 0 = not solved. Normal state every morning before first solve.
func didSolveToday(in recentCalendar: [String: Int]) -> Bool {
    let ts = Int(sharedUTCCalendar.startOfDay(for: Date()).timeIntervalSince1970)
    return (recentCalendar[String(ts)] ?? 0) > 0
}

/// Data written by the main app and read by the widget extension.
/// Stored in App Group UserDefaults under key "widgetData".
struct WidgetData: Codable {
    let anysolveStreak: Int
    let dccStreak: Int
    /// False when the user has not authenticated — widget shows "–" instead of the streak count.
    let isDCCAvailable: Bool
    let easySolved: Int
    let mediumSolved: Int
    let hardSolved: Int
    /// Unix timestamp strings → solve count, covering the last 25 weeks.
    let recentCalendar: [String: Int]
    /// When this data was fetched. nil means unknown age (treat as stale).
    var fetchedAt: Date?

    static let placeholder = WidgetData(
        anysolveStreak: 0,
        dccStreak: 0,
        isDCCAvailable: false,
        easySolved: 0,
        mediumSolved: 0,
        hardSolved: 0,
        recentCalendar: [:],
        fetchedAt: nil
    )

    // Custom decode so that data encoded before isDCCAvailable was added
    // (which lacks the key) defaults to true — preserving existing behaviour.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        anysolveStreak   = try c.decode(Int.self,    forKey: .anysolveStreak)
        dccStreak        = try c.decode(Int.self,    forKey: .dccStreak)
        isDCCAvailable   = try c.decodeIfPresent(Bool.self, forKey: .isDCCAvailable) ?? true
        easySolved       = try c.decode(Int.self,    forKey: .easySolved)
        mediumSolved     = try c.decode(Int.self,    forKey: .mediumSolved)
        hardSolved       = try c.decode(Int.self,    forKey: .hardSolved)
        recentCalendar   = try c.decode([String: Int].self, forKey: .recentCalendar)
        fetchedAt        = try c.decodeIfPresent(Date.self, forKey: .fetchedAt)
    }

    init(anysolveStreak: Int, dccStreak: Int, isDCCAvailable: Bool,
         easySolved: Int, mediumSolved: Int, hardSolved: Int,
         recentCalendar: [String: Int], fetchedAt: Date?) {
        self.anysolveStreak = anysolveStreak
        self.dccStreak      = dccStreak
        self.isDCCAvailable = isDCCAvailable
        self.easySolved     = easySolved
        self.mediumSolved   = mediumSolved
        self.hardSolved     = hardSolved
        self.recentCalendar = recentCalendar
        self.fetchedAt      = fetchedAt
    }
}
