import SwiftUI
import BackgroundTasks
import WidgetKit

@main
struct LeetCodeLyticsApp: App {

    init() {
        let defaults = UserDefaults.appGroup

        // Seed widgetDimOpacity default on first launch.
        if defaults.object(forKey: "widgetDimOpacity") == nil {
            defaults.set(0.25, forKey: "widgetDimOpacity")
        }

        // One-time migration: v2.19 moved credential storage from UserDefaults to Keychain.
        // If Keychain is empty but the old UserDefaults keys still hold credentials (written
        // by the pre-v2.19 hardcoded seed), copy them over so buildRequest finds them.
        if !KeychainService.hasCredentials() {
            if let session = defaults.string(forKey: "leetcodeSession"), !session.isEmpty {
                KeychainService.store(session, key: KeychainService.sessionKey)
            }
            if let csrf = defaults.string(forKey: "csrfToken"), !csrf.isEmpty {
                KeychainService.store(csrf, key: KeychainService.csrfKey)
            }
        }

        // Register the background refresh handler. Must be called before
        // the app finishes launching (i.e., in init, not in .task).
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.leetcodelytics.app.refresh",
            using: nil
        ) { task in
            Self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        // Queue the first wakeup. The handler reschedules itself smartly
        // (UTC midnight if solved today, 15 min otherwise) after each run.
        Self.scheduleBackgroundRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await LeetCodeService.shared.bootstrapCSRF()
                }
        }
    }

    // MARK: - Background App Refresh

    /// Schedules the next background wakeup.
    /// - Parameter interval: Earliest seconds from now. Default = 15 min (not-solved cadence).
    static func scheduleBackgroundRefresh(after interval: TimeInterval = 15 * 60) {
        let request = BGAppRefreshTaskRequest(identifier: "com.leetcodelytics.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        let fetchTask = Task {
            defer { task.setTaskCompleted(success: true) }

            let username = UserDefaults.appGroup.string(forKey: "username") ?? ""
            guard !username.isEmpty else {
                scheduleBackgroundRefresh()
                return
            }

            guard let streakData = try? await LeetCodeService.shared.fetchCalendar(username: username)
            else {
                scheduleBackgroundRefresh() // retry in 15 min on failure
                return
            }

            let updatedRecentCal = updateWidgetCalendarData(from: streakData)
            WidgetCenter.shared.reloadAllTimelines()

            // Smart scheduling: solved today → no more refreshes until next UTC midnight.
            // Not solved → keep checking every 15 min so the widget reacts promptly.
            if didSolveToday(in: updatedRecentCal) {
                var utcCal = Calendar(identifier: .gregorian)
                utcCal.timeZone = TimeZone(identifier: "UTC")!
                let nextMidnight = utcCal.date(byAdding: .day, value: 1, to: utcCal.startOfDay(for: Date()))!
                scheduleBackgroundRefresh(after: nextMidnight.timeIntervalSinceNow)
            } else {
                scheduleBackgroundRefresh()
            }
        }

        task.expirationHandler = { fetchTask.cancel() }
    }

    /// Non-destructive widget update: replaces only `anysolveStreak` + `recentCalendar`.
    /// DCC streak, solved counts, and `isDCCAvailable` are preserved from the last full app refresh.
    /// Returns the updated recentCalendar so the caller can call `didSolveToday` for smart scheduling.
    @discardableResult
    static func updateWidgetCalendarData(from streakData: StreakData) -> [String: Int] {
        let cal = SubmissionCalendar(jsonString: streakData.submissionCalendar)
        let anysolveStreak = StreakCalculator.computeStreak(from: cal)
        let cutoff = Date().timeIntervalSince1970 - Double(widgetHeatmapWeeks * 7 * 86400)
        let recentCal = Dictionary(
            cal.dailyCounts
                .filter { Double($0.key) >= cutoff }
                .map { (String($0.key), $0.value) },
            uniquingKeysWith: { first, _ in first }
        )

        let defaults = UserDefaults.appGroup
        guard let existing = defaults.data(forKey: "widgetData"),
              let current = try? JSONDecoder().decode(WidgetData.self, from: existing)
        else { return recentCal }

        let updated = WidgetData(
            anysolveStreak: anysolveStreak,
            dccStreak: current.dccStreak,
            isDCCAvailable: current.isDCCAvailable,
            easySolved: current.easySolved,
            mediumSolved: current.mediumSolved,
            hardSolved: current.hardSolved,
            recentCalendar: recentCal,
            fetchedAt: Date()
        )
        if let encoded = try? JSONEncoder().encode(updated) {
            defaults.set(encoded, forKey: "widgetData")
        }
        return recentCal
    }
}
