import SwiftUI
import WidgetKit


private let settingsRelativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .full
    return f
}()

struct SettingsView: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @AppStorage("lastUpdated", store: .appGroup) private var lastUpdated: Double = 0
    @AppStorage("widgetDimOpacity", store: .appGroup) private var widgetDimOpacity: Double = 0.25

    @State private var newUsername = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showUsernameSheet = false
    @State private var showLoginSheet = false
    @State private var isSignedIn = KeychainService.hasCredentials()

    var body: some View {
        // Compute once per body evaluation — `Date()` is captured at the start of render,
        // not re-evaluated inside nested expressions.
        let lastUpdatedText: String = {
            guard lastUpdated > 0 else { return "Never" }
            let date = Date(timeIntervalSince1970: lastUpdated)
            return settingsRelativeFormatter.localizedString(for: date, relativeTo: Date())
        }()

        NavigationStack {
            List {
                // Account
                Section("Account") {
                    HStack {
                        Label("Username", systemImage: "person.circle")
                        Spacer()
                        Text(username)
                            .foregroundStyle(.gray)
                    }
                    Button("Change Username") {
                        newUsername = username
                        showUsernameSheet = true
                    }
                    .foregroundStyle(Color.leetcodeOrange)
                }

                // Authentication
                Section {
                    HStack {
                        Label("Status", systemImage: "person.badge.key.fill")
                        Spacer()
                        Text(isSignedIn ? "Signed in" : "Not signed in")
                            .foregroundStyle(isSignedIn ? .green : .red)
                            .font(.caption)
                    }
                    if !isSignedIn {
                        Button("Sign in to LeetCode") {
                            showLoginSheet = true
                        }
                        .foregroundStyle(Color.leetcodeOrange)
                    } else {
                        Button("Sign Out") {
                            KeychainService.clearAll()
                            isSignedIn = false
                            markWidgetDCCUnavailable()
                        }
                        .foregroundStyle(.red)
                    }
                } header: {
                    Text("Authentication")
                } footer: {
                    Text("Required for Daily Question Streak. Sign in with your LeetCode account via the in-app browser.")
                        .font(.caption)
                }

                // Widgets
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Background Dim", systemImage: "circle.lefthalf.filled")
                            Spacer()
                            Text("\(Int(widgetDimOpacity * 100))%")
                                .foregroundStyle(.gray)
                                .monospacedDigit()
                        }
                        Slider(value: $widgetDimOpacity, in: 0...0.8, step: 0.05)
                            .tint(Color.leetcodeOrange)
                            .onChange(of: widgetDimOpacity) { _, _ in
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Widgets")
                } footer: {
                    Text("Controls how dark the overlay on the widget background image is. Adjust to taste, then this can be baked into code.")
                        .font(.caption)
                }

                // Info
                Section("Info") {
                    HStack {
                        Label("Last Refreshed", systemImage: "clock")
                        Spacer()
                        Text(lastUpdatedText)
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { isSignedIn = KeychainService.hasCredentials() }
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
        .sheet(isPresented: $showLoginSheet) {
            LeetCodeLoginSheet {
                isSignedIn = true
            }
        }
    }

    /// After sign-out, immediately reflect isDCCAvailable=false in the stored WidgetData
    /// so the widget shows "–" without waiting for the next Dashboard load.
    private func markWidgetDCCUnavailable() {
        WidgetDataWriter.markDCCUnavailable()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct UsernameChangeSheet: View {
    @Binding var newUsername: String
    @Binding var isValidating: Bool
    @Binding var validationError: String?
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("LeetCode username", text: $newUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if let error = validationError {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Change Username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

