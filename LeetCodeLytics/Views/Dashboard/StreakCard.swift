import SwiftUI

/// Live streak values — not tied to any fixed time window.
struct CurrentStreakCard: View {
    let dccStreak: Int
    let anysolveStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 0) {
                StreakItem(value: dccStreak, icon: "🔥", label: "Daily Question")
                Divider().background(Color.gray.opacity(0.3)).frame(height: 50)
                StreakItem(value: anysolveStreak, icon: "⚡", label: "Solved (any question)")
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct StreakItem: View {
    let value: Int
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text("\(value) days")
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
