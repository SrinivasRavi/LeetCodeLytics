import SwiftUI

/// Live streak values — not tied to any fixed time window.
struct CurrentStreakCard: View {
    let dccStreak: Int
    let anysolveStreak: Int
    let isViewingOwnProfile: Bool
    let sessionExpired: Bool
    let onSignIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 0) {
                if !isViewingOwnProfile || sessionExpired {
                    DCCStreakUnauthenticatedItem(onSignIn: onSignIn)
                } else {
                    StreakItem(value: dccStreak, icon: "🔥", label: "Daily Question")
                }
                Divider().background(Color.gray.opacity(0.3)).frame(height: 50)
                StreakItem(value: anysolveStreak, icon: "⚡", label: "Solved (any question)")
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct DCCStreakUnauthenticatedItem: View {
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("🔥")
                .font(.title2)
            Text("–")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Daily Question")
                .font(.caption2)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Button("Sign in", action: onSignIn)
                .font(.system(size: 10))
                .foregroundStyle(Color.leetcodeOrange)
        }
        .frame(maxWidth: .infinity)
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
            Text("\(value) \(value == 1 ? "day" : "days")")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
