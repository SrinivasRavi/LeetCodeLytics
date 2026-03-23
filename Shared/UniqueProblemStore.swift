import Foundation

/// Persists accepted problem entries (slug + title + solve date) with a 100-day rolling window.
/// Stored in App Group UserDefaults so widgets can read the count if needed.
///
/// The LeetCode API only returns the last 20 submissions. We cannot retroactively
/// know which of a user's 300+ solved problems were unique. This store accumulates
/// entries over time as the app processes new submissions — accuracy improves with use.
///
/// Entries older than 100 days are evicted on every write. The 100-day window means
/// problems solved long ago become eligible for re-suggestion in Muscle Memory.
enum UniqueProblemStore {
    private static let entriesKey = "uniqueProblemEntries"
    static let rollingWindowDays: Double = 100

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: "group.com.leetanalytics.shared") ?? .standard
    }

    struct Entry: Codable {
        let slug: String
        let title: String
        let solvedAt: TimeInterval
    }

    /// Adds accepted problems to the persistent store. Duplicates (by slug) are ignored.
    /// Evicts entries older than 100 days.
    static func add(problems: [(slug: String, title: String)]) {
        guard !problems.isEmpty else { return }
        var entries = loadEntries()
        var existing = Set(entries.map(\.slug))
        let now = Date().timeIntervalSince1970
        var changed = false

        for problem in problems {
            if !existing.contains(problem.slug) {
                entries.append(Entry(slug: problem.slug, title: problem.title, solvedAt: now))
                existing.insert(problem.slug)
                changed = true
            }
        }
        guard changed else { return }

        // Evict entries older than 100 days
        let cutoff = now - rollingWindowDays * 86400
        entries = entries.filter { $0.solvedAt >= cutoff }
        saveEntries(entries)
    }

    /// Number of unique accepted problems within the rolling window.
    static func count() -> Int {
        loadRecentEntries().count
    }

    /// Whether a specific problem slug was solved within the rolling window.
    static func contains(slug: String) -> Bool {
        loadRecentEntries().contains { $0.slug == slug }
    }

    /// All entries within the rolling window, sorted by most recent first.
    static func recentEntries() -> [Entry] {
        loadRecentEntries().sorted { $0.solvedAt > $1.solvedAt }
    }

    /// Set of slugs solved within the rolling window — used by Muscle Memory
    /// to filter out recently-solved problems from suggestions.
    static func recentSlugs() -> Set<String> {
        Set(loadRecentEntries().map(\.slug))
    }

    /// Date of the earliest entry in the rolling window.
    static func earliestDate() -> Date? {
        guard let earliest = loadRecentEntries().min(by: { $0.solvedAt < $1.solvedAt }) else { return nil }
        return Date(timeIntervalSince1970: earliest.solvedAt)
    }

    // MARK: - Internal

    private static func loadEntries() -> [Entry] {
        guard let data = defaults.data(forKey: entriesKey) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    private static func loadRecentEntries() -> [Entry] {
        let cutoff = Date().timeIntervalSince1970 - rollingWindowDays * 86400
        return loadEntries().filter { $0.solvedAt >= cutoff }
    }

    private static func saveEntries(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: entriesKey)
    }
}
