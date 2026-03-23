import SwiftUI
import BackgroundTasks
import WidgetKit

@main
struct LeetAnalyticsApp: App {

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
            forTaskWithIdentifier: "com.leetanalytics.app.refresh",
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
        let request = BGAppRefreshTaskRequest(identifier: "com.leetanalytics.app.refresh")
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

            let cal = SubmissionCalendar(jsonString: streakData.submissionCalendar)
            let anysolveStreak = StreakCalculator.computeStreak(from: cal)
            let recentCal = DashboardViewModel.recentCalendarSlice(from: cal)
            let updatedRecentCal = WidgetDataWriter.updateCalendar(
                anysolveStreak: anysolveStreak,
                recentCalendar: recentCal
            )
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

}
