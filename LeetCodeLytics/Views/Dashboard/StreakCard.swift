import SwiftUI

struct StreakCard: View {
    let dccStreak: Int
    let anysolveStreak: Int
    let totalActiveDays: Int

    var body: some View {
        HStack(spacing: 0) {
            StreakItem(value: dccStreak, icon: "🔥", label: "DCC Streak")
            Divider().background(Color.gray.opacity(0.3)).frame(height: 50)
            StreakItem(value: anysolveStreak, icon: "⚡", label: "Solve Streak")
            Divider().background(Color.gray.opacity(0.3)).frame(height: 50)
            StreakItem(value: totalActiveDays, icon: "📅", label: "Active Days")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct StreakItem: View {
    let value: Int
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
