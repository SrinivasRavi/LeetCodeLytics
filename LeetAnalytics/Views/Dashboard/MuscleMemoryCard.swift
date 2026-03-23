import SwiftUI

/// Shows the 3 topics with the lowest solved/total ratio — suggesting they
/// need more practice ("muscle memory"). Data comes from the cached tagProblemCounts
/// and tagTotals which are populated when the user visits the Skills tab.
///
/// Ratio = problemsSolved / totalQuestions. This avoids biasing toward small categories.
/// For example, if Dynamic Programming has 500 total and you solved 50 (10%),
/// and Bitmask has 30 total and you solved 4 (13%), DP ranks lower (needs more practice).
struct MuscleMemoryCard: View {
    let suggestions: [TopicSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Muscle Memory")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            Text("Topics with lowest solve ratio — practice these to stay sharp")
                .font(.caption)
                .foregroundStyle(.gray)

            ForEach(suggestions) { suggestion in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(suggestion.color)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.tagName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            if suggestion.totalProblems > 0 {
                                Text("\(suggestion.problemsSolved)/\(suggestion.totalProblems) solved (\(Int(suggestion.ratio * 100))%) · \(suggestion.level)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            } else {
                                Text("\(suggestion.problemsSolved) solved · \(suggestion.level)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }

                        Spacer()
                    }

                    // Problem suggestions — unsolved problems in this category
                    if !suggestion.suggestedProblems.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(suggestion.suggestedProblems) { problem in
                                HStack(spacing: 6) {
                                    Text("LC \(problem.questionFrontendId)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.leetcodeOrange)
                                    Text(problem.title)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TopicSuggestion: Identifiable {
    let tagName: String
    let tagSlug: String
    let problemsSolved: Int
    let totalProblems: Int
    let ratio: Double
    let level: String // "Advanced", "Intermediate", "Fundamental"
    let color: Color
    let suggestedProblems: [ProblemSummary]

    var id: String { tagSlug }
}
