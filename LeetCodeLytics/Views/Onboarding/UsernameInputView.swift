import SwiftUI

struct UsernameInputView: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @State private var inputText = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "FFA116"))

                    Text("LeetCodeLytics")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Track your LeetCode progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 16) {
                    TextField("Enter your LeetCode username", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Button(action: validate) {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Get Started")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "FFA116"))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                }

                Spacer()
            }
        }
    }

    private func validate() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isValidating = true
        errorMessage = nil

        Task {
            do {
                _ = try await LeetCodeService.shared.fetchUserProfile(username: trimmed)
                username = trimmed
            } catch LeetCodeError.invalidUsername {
                errorMessage = "Username not found. Please check and try again."
            } catch {
                errorMessage = "Could not connect. Check your internet connection."
            }
            isValidating = false
        }
    }
}
