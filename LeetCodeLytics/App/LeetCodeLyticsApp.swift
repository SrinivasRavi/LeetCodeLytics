import SwiftUI

@main
struct LeetCodeLyticsApp: App {

    init() {
        let defaults = UserDefaults.appGroup
        if defaults.string(forKey: "leetcodeSession")?.isEmpty != false {
            defaults.set("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfYXV0aF91c2VyX2lkIjoiMTIzNTcyMiIsIl9hdXRoX3VzZXJfYmFja2VuZCI6ImFsbGF1dGguYWNjb3VudC5hdXRoX2JhY2tlbmRzLkF1dGhlbnRpY2F0aW9uQmFja2VuZCIsIl9hdXRoX3VzZXJfaGFzaCI6ImU3MDZjOTRiODQwMGY2YjhiZDRhMjc1NTQ5YjllZTJlZmIwMTM5NTNhYWQyZjUwMmEzZmI3Zjc3MGJiODg1YmEiLCJzZXNzaW9uX3V1aWQiOiI3ZTlhYTY5MiIsImlkIjoxMjM1NzIyLCJlbWFpbCI6InNyaW5pdmFzcm9oYW4xMUBnbWFpbC5jb20iLCJ1c2VybmFtZSI6InNwYWNld2FuZGVyZXIiLCJ1c2VyX3NsdWciOiJzcGFjZXdhbmRlcmVyIiwiYXZhdGFyIjoiaHR0cHM6Ly9hc3NldHMubGVldGNvZGUuY29tL3VzZXJzL3NwYWNld2FuZGVyZXIvYXZhdGFyXzE1NTM0NzY2NTMucG5nIiwicmVmcmVzaGVkX2F0IjoxNzczMzYzOTM5LCJpcCI6IjIwMi4xNDEuMzYuOCIsImlkZW50aXR5IjoiZGY0YmYwNGY5YmY3YjZhZjA5ZTNlOTQxNzk3MzM3NzAiLCJkZXZpY2Vfd2l0aF9pcCI6WyIwZmE3Nzk3ODFmMjUxNjhkOTIwMTBhZTBiNTZhMTVhZiIsIjIwMi4xNDEuMzYuOCJdLCJfc2Vzc2lvbl9leHBpcnkiOjEyMDk2MDB9.-l6fez0TENoSdxsymS3hzc8Wne_5EZQDjpNE_2kzi6g", forKey: "leetcodeSession")
        }
        if defaults.string(forKey: "csrfToken")?.isEmpty != false {
            defaults.set("eV1JvjNCIh0MSxOL5i0tbg9mnW22xsmc", forKey: "csrfToken")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await LeetCodeService.shared.bootstrapCSRF()
                }
        }
    }
}
