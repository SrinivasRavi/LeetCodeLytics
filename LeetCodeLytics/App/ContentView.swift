import SwiftUI

struct ContentView: View {
    @AppStorage("username", store: .appGroup) private var username = ""

    var body: some View {
        if username.isEmpty {
            UsernameInputView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(0)

            SubmissionsView()
                .tabItem { Label("Submissions", systemImage: "list.bullet.clipboard") }
                .tag(1)

            SkillsView()
                .tabItem { Label("Skills", systemImage: "brain.head.profile") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .tint(Color(hex: "FFA116"))
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            if url.scheme == "leetcodelytics" {
                selectedTab = 0
            }
        }
    }
}
