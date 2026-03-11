import SwiftUI

struct AcceptanceRateView: View {
    let rate: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Acceptance Rate")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(String(format: "%.1f%%", rate))
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "FFA116"))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(hex: "FFA116").opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: rate / 100)
                    .stroke(Color(hex: "FFA116"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: rate)
            }
            .frame(width: 60, height: 60)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
