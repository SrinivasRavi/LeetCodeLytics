import SwiftUI

struct ProfileHeaderView: View {
    let profile: MatchedUser

    var body: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: profile.profile.userAvatar.flatMap(URL.init(string:))) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.gray)
                    )
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.username)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                if let realName = profile.profile.realName, !realName.isEmpty {
                    Text(realName)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(profile.profile.ranking == 0 ? "Unranked" : "Rank \(profile.profile.ranking.formatted())")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
