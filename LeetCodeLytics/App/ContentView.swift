import SwiftUI

struct ContentView: View {
    @AppStorage("username") private var username = ""

    var body: some View {
        if username.isEmpty {
            UsernameInputView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            SubmissionsView()
                .tabItem {
                    Label("Submissions", systemImage: "list.bullet.clipboard")
                }

            SkillsView()
                .tabItem {
                    Label("Skills", systemImage: "brain.head.profile")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(Color(hex: "FFA116"))
        .preferredColorScheme(.dark)
    }
}
