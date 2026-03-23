import SwiftUI

struct SkillsView: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @StateObject private var vm = SkillsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {

                if vm.isLoading && vm.tagCounts == nil {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if vm.tagCounts != nil {
                    VStack(spacing: 16) {
                        if !vm.topicSuggestions.isEmpty {
                            MuscleMemoryCard(suggestions: vm.topicSuggestions)
                        }

                        if !vm.topAdvanced.isEmpty {
                            TagSection(title: "Advanced", tags: vm.topAdvanced, color: .red)
                        }
                        if !vm.topIntermediate.isEmpty {
                            TagSection(title: "Intermediate", tags: vm.topIntermediate, color: .orange)
                        }
                        if !vm.topFundamental.isEmpty {
                            TagSection(title: "Fundamental", tags: vm.topFundamental, color: .green)
                        }
                        if !vm.languageStats.isEmpty {
                            LanguageSection(languages: Array(vm.languageStats.prefix(10)))
                        }
                    }
                    .padding()
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "wifi.slash",
                        description: Text(error)
                    )
                }
            }
            .refreshable {
                await vm.load(username: username)
            }
            .navigationTitle("Skills")
            .toolbar {
                if vm.isLoading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
        .task {
            await vm.load(username: username)
        }
    }
}

private struct TagSection: View {
    let title: String
    let tags: [TagStat]
    let color: Color

    var body: some View {
        // Computed once per render, not once per cell — avoids O(n) max() inside ForEach.
        let maxCount = tags.map(\.problemsSolved).max() ?? 1

        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)

            ForEach(tags) { tag in
                HStack(spacing: 8) {
                    Text(tag.tagName)
                        .font(.caption)
                        .foregroundStyle(Color.white)
                        .frame(width: 120, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(tag.problemsSolved) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 16)

                    Text("\(tag.problemsSolved)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.gray)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct LanguageSection: View {
    let languages: [LanguageStat]

    var body: some View {
        // Computed once per render, not once per cell.
        let maxCount = languages.map(\.problemsSolved).max() ?? 1

        VStack(alignment: .leading, spacing: 12) {
            Text("Languages")
                .font(.headline)
                .foregroundStyle(Color.white)

            ForEach(languages) { lang in
                HStack(spacing: 8) {
                    Text(lang.languageName)
                        .font(.caption)
                        .foregroundStyle(Color.white)
                        .frame(width: 120, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.leetcodeOrange.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.leetcodeOrange.opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(lang.problemsSolved) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 16)

                    Text("\(lang.problemsSolved)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.gray)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
