import SwiftUI

struct ProfileHeaderView: View {
    let profile: MatchedUser

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: profile.profile.userAvatar)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.username)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                if !profile.profile.realName.isEmpty {
                    Text(profile.profile.realName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Rank \(profile.profile.ranking.formatted())")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
