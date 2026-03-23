import SwiftUI

private struct ProblemRing: View {
    let solved: Int
    let total: Int
    let color: Color
    let label: String

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(solved) / Double(total)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: progress)

                VStack(spacing: 1) {
                    Text("\(solved)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("/\(total)")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 70, height: 70)

            Text(label)
                .font(.caption)
                .foregroundStyle(color)
        }
    }
}

struct ProblemStatsCard: View {
    let easySolved: Int
    let mediumSolved: Int
    let hardSolved: Int
    let totalSolved: Int
    let totalEasy: Int
    let totalMedium: Int
    let totalHard: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Problems Solved")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                VStack(spacing: 4) {
                    Text("\(totalSolved)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .frame(minWidth: 80)

                Spacer()

                HStack(spacing: 20) {
                    ProblemRing(solved: easySolved, total: totalEasy, color: .green, label: "Easy")
                    ProblemRing(solved: mediumSolved, total: totalMedium, color: .orange, label: "Medium")
                    ProblemRing(solved: hardSolved, total: totalHard, color: .red, label: "Hard")
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
