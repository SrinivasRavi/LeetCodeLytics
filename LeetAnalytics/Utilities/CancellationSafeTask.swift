import Foundation

/// Runs a @MainActor closure in an unstructured Task that survives caller cancellation.
/// SwiftUI's `.refreshable` cancels structured child tasks on certain view lifecycle events.
/// This helper wraps the work in an unstructured `Task` so it runs to completion regardless,
/// while `withCheckedContinuation` keeps the caller suspended (and the refresh spinner alive)
/// until the work finishes.
///
/// Used by all three ViewModels (Dashboard, Submissions, Skills).
@MainActor
func withCancellationSafeTask(_ work: @escaping @MainActor () async -> Void) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        Task { @MainActor in
            defer { continuation.resume() }
            await work()
        }
    }
}
