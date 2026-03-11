import SwiftUI
import Charts

struct SkillsView: View {
    @AppStorage("username") private var username = ""
    @StateObject private var vm = SkillsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {

                if vm.isLoading && vm.tagCounts == nil {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let tags = vm.tagCounts {
                    VStack(spacing: 16) {
                        if !tags.advanced.isEmpty {
                            TagSection(title: "Advanced", tags: Array(tags.advanced.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10)), color: .red)
                        }
                        if !tags.intermediate.isEmpty {
                            TagSection(title: "Intermediate", tags: Array(tags.intermediate.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10)), color: .orange)
                        }
                        if !tags.fundamental.isEmpty {
                            TagSection(title: "Fundamental", tags: Array(tags.fundamental.sorted { $0.problemsSolved > $1.problemsSolved }.prefix(10)), color: .green)
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

    private var maxCount: Int { tags.map(\.problemsSolved).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)

            ForEach(tags) { tag in
                HStack(spacing: 8) {
                    Text(tag.tagName)
                        .font(.caption)
                        .foregroundColor(.white)
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
                        .foregroundColor(.gray)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct LanguageSection: View {
    let languages: [LanguageStat]
    private var maxCount: Int { languages.map(\.problemsSolved).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Languages")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(languages) { lang in
                HStack(spacing: 8) {
                    Text(lang.languageName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 120, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "FFA116").opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "FFA116").opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(lang.problemsSolved) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 16)

                    Text("\(lang.problemsSolved)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.gray)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
