import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var streakData: StreakData?
    @Published var submissionCalendar: SubmissionCalendar?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = LeetCodeService.shared

    func load(username: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await service.fetchCalendar(username: username)
            streakData = data
            submissionCalendar = SubmissionCalendar(jsonString: data.submissionCalendar)
        } catch {
            errorMessage = (error as? LeetCodeError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func solveCount(for date: Date) -> Int {
        guard let calendar = submissionCalendar else { return 0 }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let startOfDay = cal.startOfDay(for: date)
        let ts = Int(startOfDay.timeIntervalSince1970)
        return calendar.dailyCounts[ts] ?? 0
    }
}
