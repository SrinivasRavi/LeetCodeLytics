import SwiftUI

struct AcceptanceRateView: View {
    let rate: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Acceptance Rate")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(String(format: "%.1f%%", rate))
                    .font(.title.bold())
                    .foregroundStyle(Color.leetcodeOrange)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.leetcodeOrange.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: rate / 100)
                    .stroke(Color.leetcodeOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: rate)
            }
            .frame(width: 60, height: 60)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
