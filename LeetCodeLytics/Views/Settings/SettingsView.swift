import SwiftUI

struct SettingsView: View {
    @AppStorage("username") private var username = ""
    @AppStorage("leetcodeSession") private var leetcodeSession = ""
    @AppStorage("csrfToken") private var csrfToken = ""
    @AppStorage("lastUpdated") private var lastUpdated: Double = 0

    @State private var newUsername = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showUsernameSheet = false
    @State private var showSessionSheet = false

    private var lastUpdatedText: String {
        guard lastUpdated > 0 else { return "Never" }
        let date = Date(timeIntervalSince1970: lastUpdated)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        NavigationStack {
            List {
                // Account
                Section("Account") {
                    HStack {
                        Label("Username", systemImage: "person.circle")
                        Spacer()
                        Text(username)
                            .foregroundColor(.gray)
                    }
                    Button("Change Username") {
                        newUsername = username
                        showUsernameSheet = true
                    }
                    .foregroundColor(Color(hex: "FFA116"))
                }

                // Session Cookies
                Section {
                    HStack {
                        Label("Session Cookie", systemImage: "key.fill")
                        Spacer()
                        Text(leetcodeSession.isEmpty ? "Not set" : "••••••••")
                            .foregroundColor(leetcodeSession.isEmpty ? .red : .green)
                            .font(.caption)
                    }
                    HStack {
                        Label("CSRF Token", systemImage: "lock.shield")
                        Spacer()
                        Text(csrfToken.isEmpty ? "Not set" : "••••••••")
                            .foregroundColor(csrfToken.isEmpty ? .red : .green)
                            .font(.caption)
                    }
                    Button("Update Session Cookies") {
                        showSessionSheet = true
                    }
                    .foregroundColor(Color(hex: "FFA116"))
                } header: {
                    Text("Authentication")
                } footer: {
                    Text("Required for DCC streak and private data. Find these in your browser cookies after logging in to leetcode.com.")
                        .font(.caption)
                }

                // Info
                Section("Info") {
                    HStack {
                        Label("Last Updated", systemImage: "clock")
                        Spacer()
                        Text(lastUpdatedText)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.2.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showUsernameSheet) {
            UsernameChangeSheet(
                newUsername: $newUsername,
                isValidating: $isValidating,
                validationError: $validationError
            ) { validated in
                username = validated
                showUsernameSheet = false
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSessionSheet) {
            SessionCookieSheet(
                session: $leetcodeSession,
                csrf: $csrfToken
            )
            .presentationDetents([.medium])
        }
    }
}

private struct UsernameChangeSheet: View {
    @Binding var newUsername: String
    @Binding var isValidating: Bool
    @Binding var validationError: String?
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("LeetCode username", text: $newUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if let error = validationError {
                        Text(error).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Change Username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSave("") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { validate() }
                        .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                }
            }
            .overlay {
                if isValidating { ProgressView() }
            }
        }
    }

    private func validate() {
        let trimmed = newUsername.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isValidating = true
        validationError = nil
        Task {
            do {
                _ = try await LeetCodeService.shared.fetchUserProfile(username: trimmed)
                onSave(trimmed)
            } catch LeetCodeError.invalidUsername {
                validationError = "Username not found."
            } catch {
                validationError = "Connection failed. Try again."
            }
            isValidating = false
        }
    }
}

private struct SessionCookieSheet: View {
    @Binding var session: String
    @Binding var csrf: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("LEETCODE_SESSION") {
                    TextEditor(text: $session)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 80)
                }
                Section("csrftoken") {
                    TextField("csrftoken value", text: $csrf)
                        .font(.system(.caption, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Session Cookies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        session = ""
                        csrf = ""
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}
