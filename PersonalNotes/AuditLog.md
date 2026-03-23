# LeetCodeLytics — Senior Developer Code Audit

**Audit date:** 2026-03-14
**Auditor:** Claude Sonnet 4.6 (automated senior review)
**Codebase version:** v2.15.0 (project.yml MARKETING_VERSION)
**Scope:** All Swift source files in LeetCodeLytics/, LeetCodeLyticsWidget/, Shared/, LeetCodeLyticsTests/

---

## Executive Summary

The codebase is well-structured overall with a clear MVVM architecture, consistent async/await usage, and a solid test suite. The most critical finding is a **severe security issue**: a real, personal LEETCODE_SESSION JWT is hardcoded in the app binary and will be distributed to any device the app is installed on. Beyond that, there are several genuine bugs, architectural concerns, and a cluster of SwiftUI view body performance issues. This audit is organized from highest severity to stylistic observations.

---

## 1. CRITICAL SECURITY ISSUE

### 1.1 — Real session credentials hardcoded in LeetCodeLyticsApp.swift

**File:** `LeetCodeLytics/App/LeetCodeLyticsApp.swift`, lines 9 and 12

**Issue:** A full, real LEETCODE_SESSION JWT token and a csrfToken are hardcoded as string literals in `LeetCodeLyticsApp.init()`. These are seeded into App Group UserDefaults on every first launch. This means:

1. The token is embedded in the compiled binary (visible via `strings` on the .app bundle, Hopper, Frida, etc.)
2. Anyone who installs a copy of this app (TestFlight, Ad Hoc, direct install) gets the developer's real session token — they can use it to log into leetcode.com as the developer.
3. The token contains a decoded JWT payload with a real email address (`srinivasrohan11@gmail.com`), IP address, user UUID, and session UUID — all personally identifiable information.
4. The token appears to be a long-lived JWT (`_session_expiry: 1209600` = 14 days, but `refreshed_at: 1773363939` suggests it has been refreshed recently and may still be valid).
5. If this repository is ever made public, the token is exposed in git history permanently.

**Why it matters:** If the session token is still valid, any third party with the binary can access the developer's full LeetCode account (submission history, profile data, potentially contest data). The CSRF token amplifies this — it enables write actions on behalf of the account.

**Correct approach:** Default credentials must NEVER be a real account's session token. Options:
- Leave both fields empty by default and always require the user to provide credentials
- Use a dedicated test/demo account with no sensitive data, and rotate the token periodically
- If credentials must be pre-seeded, use a Keychain-based secret injection mechanism that never embeds the token in the binary (e.g., server-side provisioning)
- At minimum, revoke the current session immediately on leetcode.com, and replace the hardcoded value with empty strings

**This is a P0 issue that must be resolved before any distribution beyond personal use.**

**Dev reply (v2.18.0):** Agreed — this is a genuine P0. Explicitly deferred by the developer: "Leave that P0 thing for now. We will come to it before shipping it in AppStore/TestFlight." The app is currently a personal-use-only tool installed only on the developer's own device. The session token seeds the developer's own account credentials for convenience. This will be addressed before any distribution — either by removing the hardcoded values and requiring manual setup, or by using a dedicated demo account. No timeline yet; tracked as a pre-submission blocker.

---

## 2. GENUINE BUGS

### 2.1 — `SubmissionsViewModel` missing `activeFetch` pattern for structured task cancellation

**File:** `LeetCodeLytics/ViewModels/SubmissionsViewModel.swift`, lines 30–40

**Issue:** `SubmissionsViewModel.load()` is marked as `async` and called directly from SwiftUI's `.task` and `.refreshable` modifiers, but it does NOT use the `withCheckedContinuation` + unstructured `Task` pattern that `DashboardViewModel` uses. This means if SwiftUI cancels the structured task (which it will do on view disappear, tab switch, or aggressive scroll during pull-to-refresh), the network fetch is cancelled mid-flight. The `isLoading = false` in the `defer` block does execute (because `defer` runs even on cancellation), but the error path is unclear — `CancellationError` is not a `LeetCodeError`, so `errorMessage` would be set to the generic `localizedDescription` of `CancellationError`, which reads "The operation couldn't be completed." — a confusing message to show the user.

**Severity:** Medium. It will manifest as occasional "The operation couldn't be completed." error banner when switching tabs quickly, which the CLAUDE.md explicitly identified as a bug to fix in v1.5.4 and v1.5.5.

**Correct approach:** Apply the same `withCheckedContinuation` + `Task { @MainActor in }` pattern from `DashboardViewModel.load()` to `SubmissionsViewModel.load()`.

**Dev reply (v2.18.0):** Agreed. This is a valid finding — the same fix applied in DashboardViewModel v1.5.5 was not propagated to SubmissionsViewModel. Will be fixed in v2.19.0 by applying the identical `withCheckedContinuation` + unstructured `Task` pattern.

**Fixed in v2.19.0:** `SubmissionsViewModel.load()` now wraps the network call in `await withCheckedContinuation { continuation in Task { @MainActor in defer { continuation.resume() } ... } }` — identical to the DashboardViewModel pattern. The `activeFetch` guard remains at the outer level; the unstructured `Task` is immune to SwiftUI cancellation. A regression test was added (`testLoad_existingSubmissions_preservedOnRefreshFailure`) verifying existing submissions survive a failed refresh.

### 2.2 — `SkillsViewModel` same cancellation issue

**File:** `LeetCodeLytics/ViewModels/SkillsViewModel.swift`, lines 38–53

**Issue:** Same problem as 2.1. `SkillsViewModel.load()` uses `async let` but runs inside a structured task context — SwiftUI can cancel it. The `async let` child tasks are children of the outer task and will be cancelled when SwiftUI cancels the refresh task. Both `CancellationError` and the `async let` throwing `CancellationError` propagate to the catch block, setting `errorMessage` to a confusing message.

**Severity:** Medium. Same impact as 2.1.

**Dev reply (v2.18.0):** Agreed. Same fix needed as 2.1 — will be done in the same v2.19.0 pass alongside SubmissionsViewModel.

**Fixed in v2.19.0:** `SkillsViewModel.load()` now uses the same `withCheckedContinuation` + unstructured `Task` pattern. The parallel `async let` fetches (`fetchSkillStats` + `fetchLanguageStats`) are preserved inside the unstructured `Task` body — they run concurrently as before but are now immune to SwiftUI cancellation.

### 2.3 — `WidgetHeatmapView.dailyCounts` computed property called in `body`

**File:** `LeetCodeLyticsWidget/WidgetViews.swift`, lines 165–170

**Issue:** `dailyCounts` is a `private var` computed property on `WidgetHeatmapView`. It is called from `countFor(date:)`, which is called once per cell in `body`. Each call to `countFor` re-runs `dailyCounts` — which rebuilds the entire `[Int: Int]` dictionary from the `[String: Int]` input dictionary. With 25 weeks × 7 days = 175 cells, `dailyCounts` is reconstructed 175 times per render.

The correct approach (used properly in `HeatmapGridView` for `buildWeeks()`) is to compute this once at the top of `body` as a `let` constant, then pass it to `countFor`. Or make `dailyCounts` a stored property set from the init, which is impossible here since it's a View. Alternatively, compute it once in `body`:

```swift
// In body:
let counts = dailyCounts
// Then pass `counts` to countFor
```

**Severity:** Low-Medium for widget context. Widgets have a tight memory budget and CPU time is constrained at render time. This is a real inefficiency but unlikely to cause a crash — just slower renders.

**Dev reply (v2.18.0):** Already fixed in v2.17.0. `WidgetHeatmapView.dailyCounts` was converted from a computed property to a stored `let` initialized once in `init`, so it is computed exactly once per view instantiation rather than 175 times per render. This finding no longer applies to the current codebase.

### 2.4 — `RecentSubmission.relativeTime` uses `Date()` in a computed property, causing stale display

**File:** `LeetCodeLytics/Models/RecentSubmission.swift`, lines 16–34

**Issue:** `relativeTime` is a computed property that calls `Date()` at access time. When the view renders, it calls `submission.relativeTime` which correctly snapshots the current time. However, the displayed time never updates — it freezes at the moment of first render and never refreshes unless the view re-renders for another reason. A submission from "5 minutes ago" would still say "5m ago" an hour later without a refresh.

This is acceptable behavior for a list that is refreshed via pull-to-refresh, but it means submissions shown immediately after a successful load are slightly incorrect if the data was already sitting in the view model for a few seconds. There is no mechanism to periodically refresh relative times.

**Severity:** Low. Acceptable tradeoff for now but worth noting. `RelativeDateTimeFormatter` would be more correct and localizable.

**Dev reply (v2.18.0):** Agreed in principle, but accepted as-is for now. The submissions list is always refreshed via pull-to-refresh before the stale display would be noticeable (the data itself is stale far sooner than the relative time label). The manual formatting approach is intentional simplicity — `RelativeDateTimeFormatter` is on the backlog but not a priority for a personal tool.

### 2.5 — `SettingsView.lastUpdatedText` recomputed on every body evaluation with `Date()`

**File:** `LeetCodeLytics/Views/Settings/SettingsView.swift`, lines 23–27

**Issue:** `lastUpdatedText` is a computed `var` property of the view struct that calls `Date()` and uses `settingsRelativeFormatter.localizedString(for:relativeTo:)`. This is called on every SwiftUI body re-render. The result will freeze at the moment of the render — the relative time shown will not auto-update. More importantly, if SwiftUI re-renders the view frequently (e.g., while the slider is being dragged), `Date()` is called on every frame, creating a new relative time string and potentially causing layout thrash.

For the "Last Updated" text, the displayed value will also be wrong: it shows when the *app was last updated* but it is computed relative to `Date()` at render time. If the user opens Settings an hour after refreshing, the text shows "1 hour ago" which is correct, but only by coincidence (because it re-evaluates). This is actually fine functionally but architecturally wrong — relative time display should use a timer-based approach for live updates, or accept the stale-until-re-render behavior explicitly.

**Severity:** Low. No functional bug, but the pattern of calling `Date()` in a view body computed property is architecturally fragile.

**Dev reply (v2.18.0):** Agreed. The `Date()` call in a view computed property is a valid concern. The "Last Updated" text itself is functionally correct (it re-evaluates on each render which is what we want), but calling `Date()` in a computed view property rather than capturing it once in `body` is fragile. Will clean up in v2.19.0 by computing it as a `let` at the top of `body`.

**Fixed in v2.19.0:** Removed the `private var lastUpdatedText: String` computed property from `SettingsView`. It is now a `let` computed via an IIFE at the very top of `body`, before the `NavigationStack`. `Date()` is captured once per body evaluation rather than potentially re-evaluated inside nested view expressions.

### 2.6 — `HeatmapGridView.solveCount(for:)` called per cell with `startOfDay` computation

**File:** `LeetCodeLytics/Views/Calendar/HeatmapGridView.swift`, lines 127–131

**Issue:** `solveCount(for:)` calls `heatmapCalendar.startOfDay(for: date)` on every cell. With 52 × 7 = 364 cells, this is 364 Calendar operations per render. Each `buildWeeks()` already computes `startOfDay` once per date when building the grid. The dates stored in `weeks` are already start-of-day values (they come from `heatmapCalendar.date(byAdding: .day, value: day, to: weekStart)` where `weekStart` was derived from `startOfDay`). So the `startOfDay` call in `solveCount` is redundant — it adds overhead for no correctness benefit.

**Severity:** Low. Calendar operations are fast, but it is wasted work on every render of a 364-cell grid. Compound this with SwiftUI potentially re-rendering the heatmap multiple times during Dashboard load.

**Dev reply (v2.18.0):** Agreed. The `startOfDay` call is redundant since dates in `weeks` are already start-of-day values. This is a low-impact but genuine inefficiency — will fix in v2.19.0 by removing the redundant `startOfDay` call in `solveCount(for:)` and using the date directly as the dictionary key.

**Fixed in v2.19.0:** Removed the `heatmapCalendar.startOfDay(for: date)` call from `solveCount(for:)`. The `date` parameter is already a start-of-day value (all dates in `weeks` are generated from `heatmapCalendar.date(byAdding:)` starting from a `startOfDay`-derived base). Now uses `Int(date.timeIntervalSince1970)` directly as the dictionary key.

### 2.7 — `BadgesView` uses `Array(badges.enumerated())` with `id: \.offset` for `ForEach`

**File:** `LeetCodeLytics/Views/Dashboard/DashboardView.swift`, line 191

**Issue:** `ForEach(Array(badges.enumerated()), id: \.offset)` uses the array index as the identifier. This breaks SwiftUI's diffing — if badges are reordered or one is inserted/deleted, SwiftUI will not correctly animate or update existing views. Each `UserBadge` has an `id: String?` property that could be used directly if badges conformed to `Identifiable`. Since `UserBadge` does not conform to `Identifiable`, the right fix is to either:
1. Add `Identifiable` conformance to `UserBadge` (using `id ?? name` as fallback)
2. Use `ForEach(badges, id: \.name)` with a stable unique key

**Severity:** Low. Badges are unlikely to animate or update incrementally, so the visual impact is nil. But it is an anti-pattern that will break if badges are ever updated in-place.

**Dev reply (v2.18.0):** Agreed. Adding `Identifiable` conformance to `UserBadge` using `id ?? name` as the stable key is the clean fix. Will add in v2.19.0 alongside other model polish. Since badges are static display-only data and never animate in-place, the visual impact is nil — but the pattern is wrong and should be corrected.

**Fixed in v2.19.0:** `UserBadge` now conforms to `Identifiable`. The raw API field (which was `id: String?`) was renamed to `badgeID: String?` with a `CodingKeys` mapping so JSON decode still works correctly. The `Identifiable.id` computed property returns `badgeID ?? name` — always non-optional. `ForEach` in `BadgesView` now uses `ForEach(badges)` with proper identity. The `testUserBadge_missingOptionalFields` test was updated to assert on `badgeID` (nil) and `id` (falls back to name). The `testUserBadge_idIsString` test still passes — `badge.id` now returns the computed stable key which equals `badgeID` ("7588899") when present.

---

## 3. ARCHITECTURE REVIEW

### 3.1 — MVVM adherence: Good overall

The MVVM pattern is correctly applied:
- ViewModels own all business logic, computed stats, and data transformation
- Views are dumb data renderers — no business logic leaks into bodies
- The `LeetCodeServiceProtocol` correctly enables mock injection
- `@StateObject` is used correctly in Views (not `@ObservedObject`)
- `@MainActor` on all ViewModels is correct — `@Published` mutations must happen on main thread

**Notable correct decisions:**
- Moving `topAdvanced/Intermediate/Fundamental` sorting from `SkillsView.body` to `SkillsViewModel` is exactly right
- `DashboardCache` and `SkillsCache` as `private struct` in ViewModel files is good encapsulation
- The `LeetCodeServiceProtocol` extension for default parameters avoids duplicating call site logic

### 3.2 — `SubmissionsViewModel` does not use unstructured Task (inconsistency with Dashboard)

Already noted as Bug 2.1 and 2.2. The inconsistency between the three ViewModels is an architecture smell — `DashboardViewModel` was fixed in v1.5.5 but the same fix was not applied to `SubmissionsViewModel` and `SkillsViewModel`.

**Dev reply (v2.18.0):** Agreed. Duplicate of 2.1/2.2. Tracked for v2.19.0.

### 3.3 — `CacheService.suiteName` is a mutable static var — thread unsafe

**File:** `LeetCodeLytics/Services/CacheService.swift`, line 5

**Issue:** `static var suiteName: String?` is a mutable static property on `CacheService`. The `defaults` computed property reads it without any synchronization. In tests, `setUp()` and `tearDown()` mutate `suiteName` from the main actor (test class is `@MainActor`), and `CacheService` methods are called concurrently. If any test calls a CacheService method from a background task while another test is changing `suiteName`, this is a data race.

**In practice:** Tests are `@MainActor` so all operations are serial. The main app only ever sets `suiteName` once at init time (it's now hardcoded to the App Group in the production code). So this is low risk in practice but architecturally fragile.

**Better approach:** Make `suiteName` a constant, or use a proper dependency injection approach where the suite name is passed at init time.

**Dev reply (v2.18.0):** Partially agreed. The thread-safety concern is real in theory but harmless in practice — all callers are `@MainActor` (serial), and in production the suiteName is only ever set once. The mutable static exists purely for test isolation (tearDown resets it). We accept this tradeoff for now; the cleaner alternative (passing suiteName at init) would require changing all call sites. Low priority — not planned for v2.19.0.

### 3.4 — `LeetCodeService.shared` singleton used directly in some Views

**Files:**
- `LeetCodeLytics/Views/Onboarding/UsernameInputView.swift`, line 75
- `LeetCodeLytics/Views/Settings/SettingsView.swift`, line 182

**Issue:** `UsernameInputView.validate()` and `UsernameChangeSheet.validate()` call `LeetCodeService.shared.fetchUserProfile(username:)` directly — bypassing the `LeetCodeServiceProtocol` injection pattern used by ViewModels. This makes these views untestable in isolation. If you ever need to test the username validation flow, you cannot inject a mock service.

**Correct approach:** Extract the validation logic into a `UsernameValidationViewModel` (or add `validateUsername` to `SettingsViewModel`) that accepts an injected `LeetCodeServiceProtocol`.

**Dev reply (v2.18.0):** Agreed — this is a genuine testability gap. However, the username validation flow is simple, stable, and has never had a bug, so the cost of adding a ViewModel layer outweighs the benefit for this personal tool. Pushback: for a single-developer personal app with no CI/CD, this level of testability is acceptable. We acknowledge the pattern is wrong but explicitly defer extraction until there is a concrete test failure or bug to motivate it.

### 3.5 — `DashboardViewModel.load()` mixes widget logic into the ViewModel

**File:** `LeetCodeLytics/ViewModels/DashboardViewModel.swift`, lines 97–119

**Issue:** `DashboardViewModel` directly writes `WidgetData` to `UserDefaults.appGroup` and calls `WidgetCenter.shared.reloadAllTimelines()`. This is a cross-cutting concern — the ViewModel is responsible for both its own display state and widget data publishing. As the app grows, this coupling makes it harder to:
1. Change the widget data format without touching the Dashboard ViewModel
2. Trigger widget refreshes from other ViewModels (e.g., if a Settings change should update the widget)
3. Unit test the widget data writing in isolation

**Better approach:** Extract a `WidgetDataService` or `WidgetSyncService` that takes the relevant data and writes to App Group + triggers reload. The ViewModel calls `WidgetSyncService.sync(...)`.

**Dev reply (v2.18.0):** Agreed in principle, but pushback on priority. The widget data is Dashboard-specific by design — only Dashboard data feeds the widget. A `WidgetSyncService` abstraction would add indirection with no concrete benefit unless other ViewModels also need to write widget data (they don't currently). The widget format is stable. We accept this coupling as a deliberate design choice given the single-data-source nature of the feature.

### 3.6 — `activeFetch` is not `@MainActor`-synchronized — race condition risk

**Files:** All three ViewModels

**Issue:** `private var activeFetch = false` is a plain `Bool` stored on a `@MainActor` class. Because the entire class is `@MainActor`, all access to `activeFetch` will be on the main actor — which means no race condition in practice. However, the `activeFetch = true` assignment and the `guard !activeFetch else { return }` check are not atomic — if two callers reach `load()` at the same time from different async contexts, both could pass the guard before either sets `activeFetch = true`. In practice, since these are `@MainActor`, the checks and assignments are all serialized on the main actor, so concurrent access cannot occur. This is fine, but worth documenting.

**Dev reply (v2.18.0):** Agreed with the analysis — this is a non-issue. The `@MainActor` isolation guarantees serial execution so the guard + assignment is effectively atomic in this context. No code change needed. Worth adding a comment noting why `activeFetch` is safe without an `os_unfair_lock`.

### 3.7 — `widgetDimOpacity()` function in `LeetCodeLyticsWidget.swift` creates a `UserDefaults` on every call

**File:** `LeetCodeLyticsWidget/LeetCodeLyticsWidget.swift`, lines 6–10

**Issue:** `widgetDimOpacity()` is called in the `containerBackground` closure of all four `Widget` `body` computed properties. Each call creates a new `UserDefaults(suiteName:)` instance. The `Widget.body` is a computed property evaluated by WidgetKit. This function is called at least 4 times per widget configuration (once per widget type), and potentially more often during widget gallery preview. `UserDefaults(suiteName:)` is documented as not thread-safe to initialize concurrently, and each initialization has a non-trivial cost.

**Better approach:** Make `widgetDimOpacity()` return a lazily computed constant, or read from a shared `UserDefaults.appGroup` instance (equivalent to the main app's `AppGroup.swift` extension) instead of creating new instances each time.

**Dev reply (v2.18.0):** Agreed. The `widgetDimOpacity()` slider is an intentionally temporary feature (the developer is using it to find the right opacity value and will remove it). Once the opacity value is finalized and hardcoded, this function and its `UserDefaults` creation will be deleted entirely. No point refactoring a feature that will be removed.

---

## 4. SWIFTUI VIEW BODIES

### 4.1 — `TagSection.maxCount` computed property called per render

**File:** `LeetCodeLytics/Views/Skills/SkillsView.swift`, line 61

**Issue:** `private var maxCount: Int { tags.map(\.problemsSolved).max() ?? 1 }` is a computed property. It is referenced in `body` inside a `ForEach` over tags. SwiftUI does NOT cache computed properties — `maxCount` is re-evaluated on every body render. With up to 10 tags per section and 3 sections, this runs up to 30 `max()` computations per parent re-render. Each `max()` is O(n) over the tags array.

This is a minor inefficiency, but the same issue exists in `LanguageSection.maxCount` (line 103). The correct fix is to compute `maxCount` as a `let` at the top of `body`:

```swift
var body: some View {
    let maxCount = tags.map(\.problemsSolved).max() ?? 1
    // ...
}
```

Or store it as a computed property backed by a lazy cache. The CLAUDE.md documents this exact rule: "Never put sorting, filtering, or date arithmetic in a body."

**Dev reply (v2.18.0):** Agreed. Valid performance finding. Will fix in v2.19.0 by computing `maxCount` as a `let` at the top of `body` in both `TagSection` and `LanguageSection`, consistent with the CLAUDE.md rule already in place.

**Fixed in v2.19.0:** Removed the `private var maxCount` computed properties from both `TagSection` and `LanguageSection`. Each now computes `let maxCount = tags/languages.map(\.problemsSolved).max() ?? 1` as a `let` at the top of its `body`. Note: the `private var maxCount` was also removed from the struct body entirely — it was a computed property that ran on every body evaluation. The `let` in `body` runs once per render and is captured by the nested closures.

### 4.2 — `heatmapColor(count:)` creates `Color(hex:)` instances on every cell render

**File:** `LeetCodeLytics/Views/Calendar/HeatmapGridView.swift`, lines 133–141

**Issue:** `heatmapColor(count:)` calls `Color(hex: "FFA116")` in the switch statement. `Color(hex:)` runs `Scanner`, bit-shifts, and `Color.init(.sRGB, ...)` on every invocation. With 364 cells, and most cells having count >= 1, this creates hundreds of Color values per render that all resolve to the same orange. These should be `private let` constants at the file level:

```swift
private let heatmapOrangeLight = Color(hex: "FFA116").opacity(0.3)
private let heatmapOrangeMid   = Color(hex: "FFA116").opacity(0.5)
// etc.
```

The same issue exists in `WidgetHeatmapView.heatmapColor(count:)` in `WidgetViews.swift` (lines 253–259), although that version already uses `Color(red:green:blue:)` directly which avoids the hex parsing overhead.

**Dev reply (v2.18.0):** Agreed. The fix is straightforward — promote the computed colors to `private let` file-level constants in `HeatmapGridView.swift`. This is part of the broader 4.5 finding (centralize the LeetCode orange color). Will address in v2.19.0.

**Fixed in v2.19.0:** Added five file-level `private let` constants (`heatmapColorEmpty`, `heatmapColorLight`, `heatmapColorMid`, `heatmapColorHigh`, `heatmapColorMax`) to `HeatmapGridView.swift`. These reference `Color.leetcodeOrange` (the new shared static). `heatmapColor(count:)` now returns these constants — Color(hex:) is never called during rendering.

### 4.3 — `DashboardView` reads `CacheService.timestamp` synchronously on every `.task` and `.refreshable` completion

**File:** `LeetCodeLytics/Views/Dashboard/DashboardView.swift`, lines 98–102

**Issue:** `refreshTimestamp()` calls `CacheService.timestamp(for:)` which reads from `UserDefaults` on the main thread. `UserDefaults` reads are fast but should technically happen off the main thread in a performance-critical app. More importantly, `refreshTimestamp()` is called both from `.task` (on initial load) and from `.refreshable` — but NOT in response to any state change in the ViewModel. If the ViewModel updates but `refreshTimestamp()` is not called (e.g., on username change without pull-to-refresh), `lastUpdatedText` will be stale.

**Dev reply (v2.18.0):** Partially agreed. `UserDefaults` reads are synchronous but sub-millisecond — this is not a measurable performance issue. The stale `lastUpdatedText` concern is more relevant: if the username changes in Settings without a pull-to-refresh, the timestamp won't update. However, username changes already trigger a fresh load, so in practice `refreshTimestamp()` is always called when the data changes. Accepted as-is; low priority.

### 4.4 — `AcceptanceRateView` creates `Color(hex:)` on every render

**File:** `LeetCodeLytics/Views/Dashboard/AcceptanceRateView.swift`, lines 14 and 21

**Issue:** `Color(hex: "FFA116")` is called twice in `AcceptanceRateView.body`. This view re-renders whenever its parent re-renders (e.g., on `isLoading` changes). The correct approach is a file-level constant for the LeetCode orange color, which is used in at least 8 different files in this codebase. A centralized `extension Color { static let leetcodeOrange = Color(hex: "FFA116") }` would be cleaner, cheaper, and more maintainable.

**Dev reply (v2.18.0):** Agreed. This is part of the broader 4.5 finding. Will add `Color.leetcodeOrange` as a `static let` in `ColorExtension.swift` in v2.19.0 and replace all inline `Color(hex: "FFA116")` callsites.

**Fixed in v2.19.0:** See 4.5 fix below — done as a unified pass.

### 4.5 — `Color(hex:)` called in 8+ different files — no shared constant

**Files:** DashboardView.swift, StreakCard.swift (via StreakItem is called), AcceptanceRateView.swift, SettingsView.swift, UsernameInputView.swift, SkillsView.swift, HeatmapGridView.swift, WidgetViews.swift (avoids it), ContentView.swift

The hex color `"FFA116"` is the LeetCode brand orange. It appears as a string literal in at least 8 files. If the brand color ever changes, it requires 8+ edits. A single `static let` in `ColorExtension.swift` would centralize this.

**Dev reply (v2.18.0):** Agreed. Will add `static let leetcodeOrange = Color(hex: "FFA116")` to `ColorExtension.swift` in v2.19.0 and replace all callsites. This also fixes findings 4.2 and 4.4. Already fixed in v2.15.0 for image asset scaling; this is the remaining color consolidation step.

**Fixed in v2.19.0:** Added `static let leetcodeOrange = Color(hex: "FFA116")` to `Shared/ColorExtension.swift`. Replaced all `Color(hex: "FFA116")` literals across `ContentView.swift`, `UsernameInputView.swift`, `AcceptanceRateView.swift`, `SettingsView.swift`, `SkillsView.swift`, and `DashboardView.swift` with `Color.leetcodeOrange`. The heatmap color constants also use `Color.leetcodeOrange` (fixing 4.2 simultaneously).

### 4.6 — `.cornerRadius()` deprecated in iOS 17+ throughout the codebase

**Multiple files:** `DashboardView.swift`, `SubmissionsView.swift`, `SkillsView.swift`, `ProfileHeaderView.swift`, `StreakCard.swift`, `ProblemStatsCard.swift`, `AcceptanceRateView.swift`, `UsernameInputView.swift`

**Issue:** `.cornerRadius(_:)` was soft-deprecated in iOS 16 and the preferred API since iOS 17 is `.clipShape(RoundedRectangle(cornerRadius:))`. Xcode will generate warnings for this. The app targets iOS 17.0+ which means there is no backward-compatibility reason to use the old API.

**Severity:** Style/warning. Not a functional bug, but generates Xcode warnings and uses a deprecated API surface.

**Dev reply (v2.18.0):** Agreed. Will migrate all `.cornerRadius()` calls to `.clipShape(RoundedRectangle(cornerRadius:))` in v2.19.0. This is a mechanical find-and-replace sweep across 8 files — no logic change.

**Fixed in v2.19.0:** Replaced all `.cornerRadius()` calls with `.clipShape(RoundedRectangle(cornerRadius:))` across `UsernameInputView.swift`, `AcceptanceRateView.swift`, `ProblemStatsCard.swift`, `StreakCard.swift`, `ProfileHeaderView.swift`, `DashboardView.swift` (RefreshErrorBanner, Last52WeeksCard, BadgesView), and `SkillsView.swift` (TagSection, LanguageSection). Zero `.cornerRadius()` calls remain in the LeetCodeLytics target sources.

### 4.7 — `ContentView` uses `@AppStorage` with `store: .appGroup`, but `MainTabView.preferredColorScheme` is hardcoded

**File:** `LeetCodeLytics/App/ContentView.swift`, line 37

**Issue:** `.preferredColorScheme(.dark)` forces the app into dark mode permanently. There is no user preference, and it ignores the system's light/dark mode setting. This is a design decision but worth flagging — it makes the app inaccessible to users who prefer light mode.

**Dev reply (v2.18.0):** Pushback — this is an intentional design decision, not an oversight. The app's visual design was built exclusively for dark mode (color choices, contrast ratios, background colors). The developer is the only user. Light mode support is backlog material if the app is ever opened to others. No change planned.

---

## 5. CONCURRENCY

### 5.1 — `DashboardViewModel.load()` continuation pattern is correct but subtle

**File:** `LeetCodeLytics/ViewModels/DashboardViewModel.swift`, lines 60–123

**Issue (analysis, not bug):** The `withCheckedContinuation` + `Task { @MainActor in }` pattern is the documented fix for SwiftUI `.refreshable` cancellation. It works because:
1. The outer `withCheckedContinuation` keeps `load()` suspended (and the refresh spinner alive)
2. The inner `Task` is unstructured — it has no parent task relationship, so it cannot be cancelled by SwiftUI
3. The `defer { continuation.resume() }` guarantees the continuation fires even if the inner task throws

**However**, there is a subtle issue: if the view is dismissed while the inner Task is still running (e.g., the user navigates away), the inner Task continues to run because it is unstructured. All mutations go to `@MainActor`, so there is no crash, but the ViewModel's `@Published` properties will be updated even though no view is observing them. This is benign (the ViewModel will be deallocated once the view releases `@StateObject`) but is a slight CPU waste.

More importantly: the `activeFetch` guard at line 42 prevents concurrent calls, but the outer `withCheckedContinuation` call at line 60 is itself inside the `activeFetch` guard. This means: if a second caller arrives while the first is running, it returns immediately (correct). But if a third caller arrives after the first completes (normal sequential loads), `activeFetch` is reset by `defer` at line 44 — correct.

The `defer { activeFetch = false }` at line 44 fires when `load()` returns, which is AFTER `withCheckedContinuation` completes (i.e., after the inner Task finishes). This is correct behavior.

**Dev reply (v2.18.0):** Agreed with the analysis. This is a documentation of correctness, not a bug report. The pattern is working as intended. The observation about the unstructured Task continuing after view dismissal is accurate and benign — Swift ARC ensures the ViewModel is held alive for the Task's duration, then deallocated once the Task completes and the view has already released its `@StateObject`. No action needed.

### 5.2 — `UsernameInputView.validate()` and `UsernameChangeSheet.validate()` create unattached Tasks

**Files:**
- `LeetCodeLytics/Views/Onboarding/UsernameInputView.swift`, line 73
- `LeetCodeLytics/Views/Settings/SettingsView.swift`, line 180

**Issue:** Both `validate()` functions create `Task { }` blocks that mutate `@State` properties directly (`isValidating`, `errorMessage`, `username`). The mutations are on the main actor (via `Task`'s default actor inheritance in a `@MainActor` context), which is correct. However, these Tasks are not bound to the view's lifecycle — if the view is dismissed while validation is in progress, the Task continues and mutates `@State`. If `username` is set after the view has been dismissed (in `UsernameInputView`), this writes to `@AppStorage` which is fine. But setting `isValidating = false` on a deallocated `@State` is harmless (SwiftUI ignores it).

**Severity:** Low. No crash, no data corruption.

**Dev reply (v2.18.0):** Agreed with the severity assessment. The lifecycle is safe — Tasks are not bound to view lifecycle, but the mutations (`@State`, `@AppStorage`) are harmless after dismissal. No change planned.

### 5.3 — `bootstrapCSRF()` called in `.task` on `ContentView` body — fires on every re-render of WindowGroup

**File:** `LeetCodeLytics/App/LeetCodeLyticsApp.swift`, lines 22–24

**Issue:** `.task { await LeetCodeService.shared.bootstrapCSRF() }` is attached to `ContentView()` in the `WindowGroup`. SwiftUI's `.task` modifier is equivalent to `onAppear` + structured task management — it fires when the view appears. `ContentView` appears once (it's the root view). However, if the app is backgrounded and foregrounded, `.task` may or may not re-fire depending on iOS version and scene lifecycle.

In this case, `bootstrapCSRF()` has an early-return guard (`guard !alreadyHasCsrf else { return }`) so duplicate calls are harmless. The design is correct.

**Dev reply (v2.18.0):** Agreed — the design is correct and the early-return guard makes duplicate calls idempotent. No action needed.

### 5.4 — No timeout or retry on network requests

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`

**Issue:** `URLRequest` is created with no explicit `timeoutInterval` — the default is 60 seconds. If LeetCode's API is slow, the user will wait up to 60 seconds before seeing an error. There is also no retry logic. For a mobile app, 15–30 second timeouts with 1 retry are more appropriate.

**Severity:** Low. Default timeouts are acceptable for a personal tool.

**Dev reply (v2.18.0):** Agreed with the severity assessment. For a personal tool the 60-second default timeout is acceptable — if LeetCode's API hangs, the user knows to pull-to-refresh. Retry logic would add complexity not justified by the single-user context. Deferred indefinitely.

---

## 6. MEMORY

### 6.1 — No retain cycles detected

The ViewModel memory leak tests (MemoryLeakTests.swift) cover the three ViewModels. All three deallocate correctly in tests. No closures capture `self` strongly in ViewModels. The `Task { @MainActor in ... self.xxx }` pattern in `DashboardViewModel` captures `self` — but this is an unstructured Task, not a stored closure, so it does not create a retain cycle unless the Task runs indefinitely.

**Dev reply (v2.18.0):** Positive finding — no action needed. The Task-based self-capture is intentional and safe. The unstructured Task holds a temporary strong reference to self during execution but releases it when the task completes, which is expected behavior and does not create a cycle.

### 6.2 — `SubmissionsViewModel` test for dealloc after load is questionable

**File:** `LeetCodeLyticsTests/MemoryLeakTests.swift`, lines 45–62

**Issue:** The test creates the ViewModel inside a `Task { @MainActor in }` block. The `vm` goes out of scope when the task body exits. The test then calls `autoreleasepool {}` and asserts `weakVM == nil`. This pattern does NOT guarantee deallocation — Swift uses ARC, not autoreleasepool for Swift objects. The `autoreleasepool` call only drains Objective-C autorelease pools. For a pure Swift `ObservableObject` class, the deallocation happens immediately when the last strong reference is dropped, not via autorelease. The test may pass by coincidence (and does pass) but the `autoreleasepool` call is misleading — it does not guarantee the VM is deallocated at that point.

**Contrast with `DashboardViewModel` test (line 20–31):** That test uses `autoreleasepool` inside the Task body before releasing — which is also not meaningfully different for Swift ARC objects. Both tests work in practice because Swift ARC deallocates synchronously when reference count drops to zero.

**Severity:** Low. The tests work correctly, but the rationale for `autoreleasepool` is wrong — it is not needed for pure Swift classes and may give false confidence about memory behavior.

**Dev reply (v2.18.0):** Agreed. The `autoreleasepool` call is misleading but harmless. The tests pass because Swift ARC deallocates synchronously on reference count drop to zero — the `autoreleasepool` has no bearing on it. Will remove the misleading `autoreleasepool` wrapper in v2.19.0 for clarity, while keeping the `weak` reference assertion pattern intact.

**Fixed in v2.19.0:** Removed all `autoreleasepool {}` calls from `MemoryLeakTests.swift`. The `testXxx_deallocatesWithoutLoad` tests now use a plain `do { }` scope to control the VM's lifetime — the `weak` reference assertion after the scope exits is the correct and sufficient ARC test. The `testXxx_deallocatesAfterLoad` tests that use `withCheckedContinuation + Task` were also cleaned up. Added a new `testDashboardViewModel_deallocatesAfterLoad` test that actually calls `vm.load(username:)` before asserting deallocation (fixing gap 8.3).

### 6.3 — `WidgetHeatmapView` rebuilds the full date grid on every render

**File:** `LeetCodeLyticsWidget/WidgetViews.swift`, lines 172–195

**Issue:** `weekDates` is a computed property that builds a `[[Date?]]` matrix — a significant allocation — on every body evaluation. In the widget context, this is less of an issue because widget renders are infrequent. However, the property is used twice in `body` via `let allWeeks = weekDates` and `let labels = monthLabels(from: allWeeks)` which is correct — the single `let` prevents double computation. But since it's a `var` computed property, SwiftUI cannot cache it.

This is acceptable but could be improved by moving the computation into the `LeetCodeEntry` at timeline creation time.

**Dev reply (v2.18.0):** Partially agreed. The `let allWeeks = weekDates` pattern does prevent double-computation within a single body evaluation, which is the critical fix. Widget renders are infrequent (triggered by timeline refresh, not continuous animation), so rebuilding the grid per render is not a meaningful overhead. The suggestion to precompute in `LeetCodeEntry` at timeline creation time is architecturally cleaner but adds complexity to the data pipeline — deferred unless widget memory budget becomes a concern.

---

## 7. WIDGETKIT

### 7.1 — `containerBackground` placement is correct

**File:** `LeetCodeLyticsWidget/LeetCodeLyticsWidget.swift`

The `containerBackground(for: .widget)` modifier is correctly applied inside the `StaticConfiguration` content closure, not inside the view's `body`. This matches Apple's requirement and avoids the "Please adopt containerBackground API" overlay. This was fixed in v2.3.

**Dev reply (v2.18.0):** Confirmed correct. No action needed.

### 7.2 — Widget never makes network calls — correct

The design decision (documented in `Provider.swift` comments) to avoid network calls in the widget extension is correct given the ~30MB memory budget constraint. The widget reads from App Group UserDefaults exclusively. This is the right architecture.

**Dev reply (v2.18.0):** Confirmed correct. No action needed.

### 7.3 — `widgetDimOpacity()` function is not using the shared `UserDefaults.appGroup`

**File:** `LeetCodeLyticsWidget/LeetCodeLyticsWidget.swift`, lines 6–10

**Issue:** The widget extension has its own implementation for reading `UserDefaults` with the App Group suiteName, duplicating the logic in `AppGroup.swift`. The `AppGroup.swift` file is in the `Shared/` folder but is NOT included in the widget target (the widget's `sources` in project.yml lists `LeetCodeLyticsWidget` and `Shared`). Actually, looking at project.yml, `Shared` IS in the widget target sources. So `UserDefaults.appGroup` extension IS available in the widget — but `widgetDimOpacity()` duplicates its logic instead of using it. This is a consistency issue.

**Correct approach:** Use `UserDefaults.appGroup.double(forKey: "widgetDimOpacity")` (with the nil-object guard) inside `widgetDimOpacity()`.

**Dev reply (v2.18.0):** Agreed that using `UserDefaults.appGroup` extension would be more consistent. However, as noted in 3.7, `widgetDimOpacity()` is a temporary feature slated for removal once the right opacity value is found. No refactor planned — delete on finalization.

### 7.4 — Widget 15-minute fallback refresh is appropriate

The `policy: .after(nextRefresh)` with 15-minute interval is a reasonable fallback. Widget timeline refreshes are subject to iOS budget — the system may delay or batch them. The real refresh path (app opens → writes App Group → reloadAllTimelines) is correctly implemented.

**Dev reply (v2.18.0):** Confirmed correct. No action needed.

### 7.5 — `LargeWidgetView` has no "totalSolved" count display

**File:** `LeetCodeLyticsWidget/WidgetViews.swift`, lines 74–104

**Note:** The large widget shows both streaks, difficulty breakdown, and a heatmap — but no total solved count. This is a feature gap, not a bug, but the `MediumWidgetView` also doesn't show total solved. `WidgetData` carries `easySolved`, `mediumSolved`, `hardSolved` but no `totalSolved` field. If total solved is desired, it must be added to `WidgetData` (breaking the Codable schema — requires versioning).

**Dev reply (v2.18.0):** Acknowledged as a feature gap, not a bug. `totalSolved` can be derived from `easySolved + mediumSolved + hardSolved` at render time without a schema change, so adding it to `WidgetData` is unnecessary. If we want to display it, we'll compute it inline in the widget view. Tracked as a future enhancement.

---

## 8. TESTING

### 8.1 — Test count discrepancy: CLAUDE.md says "104 tests pass" but code suggests fewer

**File:** `CLAUDE.md`, executive summary

**Issue:** CLAUDE.md says "104 tests pass" but counting test methods across all test files yields approximately 77–80 tests (matching the v1.5.5 count listed in the test table). The CLAUDE.md history says "v2.1: Test suite expanded to 98 tests" and "v2.2: Memory leak tests (104 tests)". The test files include `MemoryLeakTests.swift` (6 tests), `WidgetDataTests.swift` (8 tests), `InfoPlistTests.swift` (3 tests), `SkillsViewModelTests.swift` (13 tests) — which were added in v2.1/v2.2. The actual count should be around 104 if all files are counted. No functional issue — just confirming the count seems right across all test files.

**Dev reply (v2.18.0):** Agreed — confirmed 104 tests pass via `xcodebuild test`. The audit was generated against the v2.15.0 codebase and this was a documentation check, not a real discrepancy. CLAUDE.md's "104 tests" count is correct.

### 8.2 — `MockLeetCodeService` has no call count tracking for `fetchLanguageStats` and `fetchSkillStats`

**File:** `LeetCodeLyticsTests/Mocks/MockLeetCodeService.swift`, lines 52–58

**Issue:** `fetchLanguageStats` and `fetchSkillStats` do not have corresponding `languageStatsCallCount` and `skillStatsCallCount` properties. The other 5 fetch methods all have call count tracking. This means tests for `SkillsViewModel` cannot verify "how many times was the service called" — they can only check the VM's output state. The `testMultipleCalls_eachCallsService` test in `SkillsViewModelTests` works around this by only checking `XCTAssertNotNil(vm.tagCounts)` rather than a call count assertion.

**Severity:** Low. The tests still work. But adding call counts would enable stronger assertions.

**Dev reply (v2.18.0):** Agreed. Will add `languageStatsCallCount` and `skillStatsCallCount` to `MockLeetCodeService` in v2.19.0 alongside the SkillsViewModel cancellation fix, so the new tests for that fix can use proper call-count assertions.

**Fixed in v2.19.0:** Added `private(set) var languageStatsCallCount = 0` and `private(set) var skillStatsCallCount = 0` to `MockLeetCodeService`, with corresponding `+= 1` increments in `fetchLanguageStats` and `fetchSkillStats`. Both call counts are now available for assertion in SkillsViewModel tests.

### 8.3 — `testDashboardViewModel_deallocatesAfterLoad` does not actually load

**File:** `LeetCodeLyticsTests/MemoryLeakTests.swift`, lines 12–32

**Issue:** The test sets up mock results and creates a `DashboardViewModel`, but does NOT call `vm.load(username:)`. The test only verifies that an unloaded VM deallocates correctly. There should also be a test for "deallocates after `load()` completes" — which the SubmissionsViewModel and SkillsViewModel tests do cover (lines 45–61 and 75–91). The `DashboardViewModel` dealloc-after-load test is missing.

**Dev reply (v2.18.0):** Agreed. Valid test coverage gap. Will add `testDashboardViewModel_deallocatesAfterLoad_withLoad` test in v2.19.0 that calls `vm.load(username:)` and then asserts deallocation.

**Fixed in v2.19.0:** Added `testDashboardViewModel_deallocatesAfterLoad` to `MemoryLeakTests.swift`. The test configures all four mock results (profile, questions, calendar, streakCounter), calls `vm.load(username: "spacewanderer")` inside a `withCheckedContinuation + Task` block, then asserts `weakVM == nil` after the Task scope exits. This mirrors the pattern used by the SubmissionsViewModel and SkillsViewModel dealloc-after-load tests.

### 8.4 — `StreakCalculatorTests` helper `utcCalendar` is an instance `var` (not `let`)

**File:** `LeetCodeLyticsTests/StreakCalculatorTests.swift`, lines 8–12

**Issue:** `private var utcCalendar: Calendar` is defined with a closure initializer — equivalent to a lazy initializer — but declared as `var` on the test class (a reference type). This is fine in practice but `var` allows accidental mutation. It should be `let`.

**Dev reply (v2.18.0):** Agreed. Simple fix — change `var` to `let`. Will fix in v2.19.0 alongside other test cleanup.

**Fixed in v2.19.0:** Changed `private var utcCalendar: Calendar` to `private let utcCalendar: Calendar` in `StreakCalculatorTests.swift`.

### 8.5 — No test for `UsernameInputView` validation or `SettingsView` validation

As noted in Architecture section (3.4), both views call `LeetCodeService.shared` directly. Since there is no injectable service in those views, there are no unit tests for the validation flow. This is a test coverage gap.

**Dev reply (v2.18.0):** Agreed — acknowledged as a known gap tied to the 3.4 finding (direct use of `LeetCodeService.shared` in views). The validation logic is simple (fetch profile, check for nil) and has been stable. Since adding testability requires extracting the logic to a ViewModel (3.4), these are linked. Deferred alongside 3.4.

### 8.6 — No test for `SubmissionsViewModel` DCC-style data preservation

The `DashboardViewModelTests` has a specific regression test for DCC streak preservation on failure. `SubmissionsViewModel` does not have an equivalent "data preserved on refresh failure" test (though its behavior is simpler — existing submissions remain in the array on error because the `submissions = fresh` assignment only happens in the `do` block).

**Dev reply (v2.18.0):** Agreed it's a gap, but low risk — the SubmissionsViewModel data preservation behavior is structurally guaranteed by the `do/catch` pattern (no mutation outside the `do` block on failure). Will add the regression test in v2.19.0 when addressing the SubmissionsViewModel cancellation fix (2.1), since those changes warrant new test coverage anyway.

**Fixed in v2.19.0:** Added `testLoad_existingSubmissions_preservedOnRefreshFailure` to `SubmissionsViewModelTests.swift`. The test performs a successful load (3 submissions), then a failing load (network error), and asserts that `vm.submissions.count` is still 3 and `vm.errorMessage` is non-nil after the failure.

### 8.7 — `CacheService.suiteName = nil` in tearDown — potential test isolation issue

**File:** Multiple test files

**Issue:** `tearDown()` sets `CacheService.suiteName = nil`. When `nil`, `CacheService.defaults` falls back to `UserDefaults(suiteName: nil) ?? .standard` — i.e., `.standard`. If a subsequent test reads from the cache before `setUp` is called, it would read from `.standard` instead of the test suite. In practice, `setUp` always runs before any test method, so this is safe. But the ordering of `tearDown`/`setUp` between tests in an `XCTestCase` is guaranteed by XCTest.

**Dev reply (v2.18.0):** Agreed the analysis is correct — XCTest guarantees setUp/tearDown ordering so this is safe in practice. No action needed. Worth a code comment explaining that the nil reset is intentional for teardown and that setUp re-establishes the test suite name before each test.

### 8.8 — `InfoPlistTests` checks version is not "1.0" — but version is "2.15.0"

**File:** `LeetCodeLyticsTests/InfoPlistTests.swift`, line 12

This test makes sense as a guard against accidentally leaving the XcodeGen placeholder. With the version currently at 2.15.0, this passes. Good guard.

**Dev reply (v2.18.0):** Confirmed — this guard is working as intended at v2.18.0. No action needed.

---

## 9. API USAGE PATTERNS

### 9.1 — GraphQL queries could be combined but are intentionally separated

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`

The three parallel fetches in `DashboardViewModel` (`fetchUserProfile`, `fetchAllQuestionsCount`, `fetchCalendar`) make 3 separate HTTP requests. GraphQL supports batching multiple queries in a single request, which would reduce network overhead. However, LeetCode's API has quirks documented in CLAUDE.md (allQuestionsCount cannot be combined with matchedUser in `execute<T>`). The current approach is pragmatic and correct given these constraints.

**Dev reply (v2.18.0):** Agreed. The separate fetches are an intentional workaround for LeetCode API constraints. No action needed.

### 9.2 — `execute<T>` uses `JSONSerialization` + re-encode + `JSONDecoder` — double serialization

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`, lines 103–121

**Issue:** The pattern is:
1. Deserialize entire response with `JSONSerialization.jsonObject` to navigate to `data[responseKey]`
2. Re-serialize that value with `JSONSerialization.data(withJSONObject:)` to get `Data`
3. Decode with `JSONDecoder`

This means every successful API response is serialized twice. For the profile response (which includes badges, submit stats arrays), this is non-trivial overhead. A single-pass approach using a custom `JSONDecoder` with a path prefix, or decoding a `[String: AnyDecodable]` wrapper, would be more efficient. However, this was the deliberate fix for the LeetCode API's inconsistent response structure (documented in CLAUDE.md as the v1.5.1 fix). The tradeoff is acceptable for correctness.

**Dev reply (v2.18.0):** Agreed that double serialization is a cost — but pushback on "non-trivial overhead" for a personal tool making a handful of API calls per refresh. The double-serialize approach was the deliberate correctness fix (v1.5.1) for an API that can't be relied upon to return a clean envelope. Replacing it with a more clever approach risks re-introducing the decoding crashes it was designed to prevent. Accepted as-is.

### 9.3 — No handling of LeetCode's GraphQL `errors` field in error reporting

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`, lines 103–114

**Issue:** The `execute<T>` function checks for the presence of `data[responseKey]`, but ignores the `errors` array that GraphQL may return alongside or instead of `data`. The test `testErrorsArrayAlongsideData_stillDecodes` confirms that partial-data-with-errors is handled correctly (data is used, errors ignored). But if LeetCode returns `data: null` AND `errors: [{"message": "Authentication required"}]`, the user sees a generic "Unexpected response" decode error rather than a meaningful "Authentication required" message.

**Severity:** Low. This is an enhancement opportunity for better error messaging.

**Dev reply (v2.18.0):** Agreed. The `errors` field is currently ignored entirely. For a personal tool where the most common auth failure symptom is the DCC streak not loading (which fails silently and preserves the last value), this hasn't caused confusion. Better error surfacing from GraphQL errors is on the backlog but not a priority until the P0 credential issue is resolved.

### 9.4 — `buildRequest` reads `UserDefaults` on every API call

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`, lines 65–66

**Issue:** Every call to `buildRequest` reads `UserDefaults.appGroup.string(forKey: "leetcodeSession")` and `UserDefaults.appGroup.string(forKey: "csrfToken")`. `UserDefaults` reads are fast but not free. For a session that rarely changes, the values could be cached in memory. This is a micro-optimization and acceptable for the current scale.

**Dev reply (v2.18.0):** Accepted as-is. `UserDefaults` reads are sub-microsecond after the first access (the system caches values in memory). In-memory caching in the service would require cache invalidation logic when Settings changes credentials — adding complexity for negligible gain. No action planned.

---

## 10. SWIFT LANGUAGE USAGE

### 10.1 — `RecentSubmission.id` is a computed property concatenating `titleSlug + timestamp`

**File:** `LeetCodeLytics/Models/RecentSubmission.swift`, line 10

**Issue:** `var id: String { titleSlug + timestamp }`. This is a computed `Identifiable.id`. If a user submits the same problem twice at the same timestamp (theoretically possible if timestamps have 1-second resolution), these two submissions would have the same `id` — causing SwiftUI `ForEach` to skip the duplicate. In practice, two submissions at the exact same second for the same problem slug is extremely unlikely, but this is a latent bug. A safer `id` would be `titleSlug + "_" + timestamp` (adding a separator to prevent false collisions like `slug: "a", timestamp: "b-c"` vs `slug: "ab", timestamp: "-c"`).

**Dev reply (v2.18.0):** Agreed — adding a separator is a one-character fix with zero risk. Will change to `titleSlug + "_" + timestamp` in v2.19.0.

**Fixed in v2.19.0:** Changed `var id: String { titleSlug + timestamp }` to `var id: String { titleSlug + "_" + timestamp }` in `RecentSubmission.swift`.

### 10.2 — `UserProfileInfo.realName` is not optional — will fail if API returns null

**File:** `LeetCodeLytics/Models/UserProfile.swift`, line 18

**Issue:** `let realName: String` (non-optional). If LeetCode's API returns `"realName": null` for a user who has not set their real name, the `JSONDecoder` will throw a `DecodingError` and the entire profile fetch will fail with a decoding error. LeetCode users are not required to set a real name — `null` is a realistic value. This should be `let realName: String?` with `if let` in `ProfileHeaderView` (which already guards it with `if !profile.profile.realName.isEmpty` — suggesting the developer knows empty string is possible, but `null` would crash the decode).

**Severity:** Medium-High. If any LeetCode user has `null` for `realName`, the entire Dashboard will fail to load with a decoding error. The `testMatchedUser_fullDecode` test hardcodes a non-null realName, so this is not caught by tests.

**Dev reply (v2.18.0):** Agreed — this is a genuine bug waiting to surface. The app is currently used only by the developer (who has a non-null realName and avatar), so it hasn't manifested yet. Will make both `realName` and `userAvatar` optional in v2.19.0 along with adding decode tests for null values.

**Fixed in v2.19.0:** `UserProfileInfo.realName` changed to `String?`. `ProfileHeaderView` updated: now uses `if let realName = profile.profile.realName, !realName.isEmpty { ... }`. Decode test `testMatchedUser_nullRealNameAndAvatar_doesNotCrash` added to `ModelDecodeTests.swift` verifying null decodes correctly.

### 10.3 — `UserProfileInfo.userAvatar` is not optional

**File:** `LeetCodeLytics/Models/UserProfile.swift`, line 17

**Issue:** Same concern as 10.2. If `userAvatar` is `null` in the API response, decoding fails. `AsyncImage(url: URL(string: ""))` handles empty string gracefully (shows placeholder), but a `null` in the JSON would throw before reaching the view.

**Severity:** Medium. New LeetCode users or users who have not set an avatar may have `null`.

**Dev reply (v2.18.0):** Agreed — same fix as 10.2. Will be made optional in v2.19.0 as part of the same model fix pass. `AsyncImage(url: nil)` shows the placeholder correctly so the view already handles it gracefully once the model is fixed.

**Fixed in v2.19.0:** `UserProfileInfo.userAvatar` changed to `String?`. `ProfileHeaderView` updated: `AsyncImage(url: profile.profile.userAvatar.flatMap(URL.init(string:)))` — uses `flatMap` to handle nil cleanly, passing `nil` to `AsyncImage` when the field is absent (shows the placeholder Circle/person.fill).

### 10.4 — `UserProfileInfo.ranking` is `Int` — can be 0 for unranked users

**File:** `LeetCodeLytics/Models/UserProfile.swift`, line 16

**Issue:** If a user has no global ranking (new account, no accepted submissions), LeetCode returns `0` for ranking. `ProfileHeaderView` would display "Rank 0" which is misleading. This should display "Unranked" when `ranking == 0`. This is a display bug, not a decode bug.

**Dev reply (v2.18.0):** Agreed. Simple display fix — `ranking == 0 ? "Unranked" : ranking.formatted()`. The developer has a non-zero ranking so this hasn't been observed, but it's a valid edge case. Will fix in v2.19.0.

**Fixed in v2.19.0:** `ProfileHeaderView` now renders `profile.profile.ranking == 0 ? "Unranked" : "Rank \(profile.profile.ranking.formatted())"`. No model change required.

### 10.5 — `StreakData` has no `activeYears` field despite GraphQL query requesting it

**Files:**
- `LeetCodeLytics/Models/StreakData.swift`
- `LeetCodeLytics/Services/LeetCodeService.swift`, line 155

**Issue:** The `userProfileCalendar` GraphQL query requests `activeYears streak totalActiveDays submissionCalendar`, but `StreakData` only models `streak`, `totalActiveDays`, and `submissionCalendar`. `activeYears` is fetched from the API but silently discarded. This is not a bug (extra fields are ignored by `JSONDecoder` by default), but it means API bandwidth is wasted fetching data that is never used. If `activeYears` is not needed, remove it from the query.

**Dev reply (v2.18.0):** Agreed. Will remove `activeYears` from the GraphQL query string in v2.19.0. No model change needed — it was never in the model. Reduces unnecessary API response payload.

**Already resolved before v2.19.0:** Inspecting the current `LeetCodeService.fetchCalendar` query, `activeYears` is already absent from the query string (it was removed in a prior cleanup). No change needed in v2.19.0.

### 10.6 — Access control: `LeetCodeService.session` is `let` but `internal` (not `private`)

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`, line 29

**Issue:** `let session: URLSession` has no access modifier, so it defaults to `internal`. This exposes the URLSession outside the module unnecessarily. In tests, `MockURLProtocol.makeSession()` is passed at init — which is fine. But the session property itself should be `private(set)` or `private` since nothing outside the service needs to access it directly.

**Dev reply (v2.18.0):** Agreed. `session` should be `private`. The session is only accessible to `MockURLProtocol` via init injection (not by accessing the property externally), so making it private has zero functional impact. Simple access control fix — will add `private` in v2.19.0.

**Fixed in v2.19.0:** Changed `let session: URLSession` to `private let session: URLSession` in `LeetCodeService`. The `init(session:)` parameter and all internal usages are unaffected. No test accesses the property directly.

### 10.7 — `LeetCodeError` cases `networkError` and `decodingError` wrap `Error` (not typed errors)

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`, lines 6–7

**Issue:** `case networkError(Error)` and `case decodingError(Error)` accept any `Error`. This makes exhaustive pattern matching in tests fragile — a test that catches `.networkError` cannot easily inspect the underlying error type without a cast. A more typed approach would use `case networkError(URLError)` and `case decodingError(DecodingError)`. This is a style preference, but the typed approach enables better error logging and testing.

**Dev reply (v2.18.0):** Partially agreed. Narrowing to `URLError` and `DecodingError` would be more precise, but it would break any existing catch sites that use the broader `Error` type. In practice, the wrapped errors are always `URLError` or `DecodingError` respectively, but enforcing this via type system is a breaking change. Low priority — deferred until there is a concrete test assertion need for the specific error type.

---

## 11. USERDEFAULTS / APPSTORAGE

### 11.1 — `SettingsView` uses `@AppStorage` for `leetcodeSession` and `csrfToken`

**File:** `LeetCodeLytics/Views/Settings/SettingsView.swift`, lines 12–13

**Issue (Security — lower priority than 1.1):** `@AppStorage("leetcodeSession", store: .appGroup)` stores the LEETCODE_SESSION token in App Group UserDefaults. App Group UserDefaults are stored unencrypted on disk in the container shared between the app and widget extension. While this requires physical device access or a compromised device to read, best practice for session tokens is to store them in the iOS Keychain with appropriate access controls (`kSecAttrAccessibleAfterFirstUnlock` or similar). On a jailbroken device, UserDefaults are trivially accessible.

**Severity:** Medium for a personal app. High if ever distributed to others.

**Dev reply (v2.18.0):** Agreed — Keychain is the correct storage for session tokens. For a personal-use app on the developer's own device, unencrypted UserDefaults storage is an accepted risk. Pre-AppStore distribution, Keychain migration will be evaluated alongside the P0 credential fix (1.1). Both security issues will be addressed together before any distribution.

### 11.2 — `UserDefaults.appGroup` fallback to `.standard` in tests

**File:** `LeetCodeLytics/App/AppGroup.swift`, line 6

**Issue:** `UserDefaults(suiteName: "group.com.leetcodelytics.shared") ?? .standard`. In unit tests, the App Group entitlement is not available, so this falls back to `.standard`. Tests that use `UserDefaults.appGroup` are reading/writing to `.standard` — which is the same store used by other `.standard` reads. If tests are run multiple times or in parallel, they may interfere with each other or with the simulator's UserDefaults. The `DashboardViewModelTests.tearDown` calls `UserDefaults.appGroup.removeObject(forKey: "widgetData")` which removes from `.standard` in the test environment.

**Better approach:** `CacheService` correctly uses a configurable `suiteName`. The app's `UserDefaults.appGroup` extension does not have this flexibility. The `DashboardViewModel` directly uses `UserDefaults.appGroup` (line 86 and 116) rather than going through `CacheService`, making it harder to isolate in tests.

**Dev reply (v2.18.0):** Agreed that the `.standard` fallback in tests is a known limitation. The existing `DashboardViewModelTests.tearDown` already cleans up `widgetData` from `.standard`, so test pollution is managed. The deeper fix (making `UserDefaults.appGroup` configurable like `CacheService.suiteName`) is architecturally correct but low priority — the existing cleanup pattern works. Deferred.

### 11.3 — `lastUpdated` stored as `Double` in `@AppStorage` but conceptually a timestamp

**File:** `LeetCodeLytics/Views/Settings/SettingsView.swift`, line 14

**Issue:** `@AppStorage("lastUpdated", store: .appGroup) private var lastUpdated: Double = 0` stores a Unix timestamp as a raw Double. `@AppStorage` does not support `Date` directly. The `DashboardViewModel` also writes directly to `UserDefaults.appGroup` with the same key (line 86). There are two places writing to the same key — `DashboardViewModel` and the `@AppStorage` binding in `SettingsView`. If these get out of sync (e.g., `SettingsView` is showing while a background refresh occurs), the `@AppStorage` property wrapper will automatically pick up the change via KVO, which is correct. No bug here, but the dual-write path (direct `UserDefaults.set` in VM vs `@AppStorage` binding) is worth noting.

**Dev reply (v2.18.0):** Agreed — the dual-write path is a code smell but not a bug. `@AppStorage` KVO automatically syncs the view when the ViewModel writes via `UserDefaults.set`, so the display stays consistent. The `Double` for `Date` storage is the standard workaround for `@AppStorage`'s lack of Date support. Accepted as-is.

---

## 12. SECURITY CONSIDERATIONS

### 12.1 — [CRITICAL] Hardcoded JWT session token — see Section 1.1

**Dev reply (v2.18.0):** See reply at Section 1.1. Deferred until pre-distribution.

### 12.2 — Session tokens in UserDefaults, not Keychain — see Section 11.1

**Dev reply (v2.18.0):** See reply at Section 11.1. Deferred until pre-distribution alongside 12.1.

### 12.3 — No certificate pinning

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`

All network requests to `leetcode.com` use the default `URLSession` with no certificate pinning. A man-in-the-middle attacker on the same network could intercept the session cookie in transit. For a personal app using HTTPS, TLS validation is sufficient — certificate pinning is generally overkill. Flagging for completeness.

**Dev reply (v2.18.0):** Pushback — certificate pinning is engineering overkill for a personal LeetCode stats viewer. Standard TLS validation via the system trust store is sufficient. LeetCode.com uses standard CA-signed certificates. No action planned.

### 12.4 — HTTP Cookie header manually constructed with raw session token

**File:** `LeetCodeLytics/Services/LeetCodeService.swift`, line 77

**Issue:** `request.setValue("LEETCODE_SESSION=\(session); csrftoken=\(effectiveCsrf)", forHTTPHeaderField: "Cookie")` manually constructs the Cookie header. If `session` or `effectiveCsrf` contain special characters (semicolons, spaces), this could malform the header. The proper approach is to use `HTTPCookie` and the cookie jar. However, since LeetCode session tokens are JWTs (base64url-encoded, no special characters), this is safe in practice.

**Dev reply (v2.18.0):** Agreed with the analysis — safe in practice since JWTs are base64url-encoded (no special characters). The manual construction is intentional: the cookie jar approach with `HTTPCookie` would require more complex setup and the current approach has been stable. Accepted as-is.

---

## 13. CODE STYLE AND CONSISTENCY

### 13.1 — Inconsistent use of `foregroundColor` vs `foregroundStyle`

**Multiple files:** Most views use `.foregroundColor(.white)` (UIKit-era API, technically deprecated in SwiftUI for iOS 17+), while widget views use `.foregroundStyle(Color.white)` (SwiftUI 4+ API). The app targets iOS 17+ exclusively. `foregroundColor` still works but `foregroundStyle` is the preferred modern API.

**Dev reply (v2.18.0):** Agreed. Will migrate all `.foregroundColor` usages to `.foregroundStyle` in v2.19.0 as part of the same API modernization pass that fixes `.cornerRadius` (4.6).

**Fixed in v2.19.0:** Replaced all `.foregroundColor(` with `.foregroundStyle(` across `UsernameInputView.swift`, `AcceptanceRateView.swift`, `StreakCard.swift`, `ProblemStatsCard.swift`, `SettingsView.swift`, `ProfileHeaderView.swift`, `SubmissionsView.swift`, `DashboardView.swift`, `HeatmapGridView.swift`, and `SkillsView.swift`. The Widget views already used `.foregroundStyle` — no change needed there.

### 13.2 — `StreakItem` is `internal` but only used in `DashboardView` and `StreakCard`

**File:** `LeetCodeLytics/Views/Dashboard/StreakCard.swift`, line 26

**Issue:** `struct StreakItem: View` has no access modifier — it is `internal`. It is referenced from `DashboardView.swift` (the `Last52WeeksCard` uses it). Since both are in the same module, this works. However, `StreakItem` being `internal` (not `private`) suggests it could be used anywhere in the app — an unintended API surface. It should be `private` if only used within the Dashboard views, but `private` would make it unavailable in `DashboardView.swift`. A better approach is to move `StreakItem` to `DashboardView.swift` where it is also used, or make it `internal` with a comment indicating its intended scope.

**Dev reply (v2.18.0):** Agreed it's a style issue. Since `StreakItem` is used in two files (StreakCard.swift and DashboardView.swift), it cannot be `private`. The cleanest fix is to move it to a shared Dashboard views file. Low priority — it's a style concern with no functional impact. Deferred.

### 13.3 — `ProblemRing` is `internal` but only used in `ProblemStatsCard`

**File:** `LeetCodeLytics/Views/Dashboard/ProblemStatsCard.swift`, line 3

Same issue as 13.2. `ProblemRing` should be `private` since it is only used within the same file. Currently it is `internal`.

**Dev reply (v2.18.0):** Agreed — unlike `StreakItem`, `ProblemRing` is only used within `ProblemStatsCard.swift`, so adding `private` is a simple fix. Will add `private` in v2.19.0.

**Fixed in v2.19.0:** Changed `struct ProblemRing: View` to `private struct ProblemRing: View` in `ProblemStatsCard.swift`.

### 13.4 — Magic number `25 * 7 * 86400` in `DashboardViewModel`

**File:** `LeetCodeLytics/ViewModels/DashboardViewModel.swift`, line 99

**Issue:** `let cutoff = Date().timeIntervalSince1970 - Double(25 * 7 * 86400)` uses inline arithmetic for "25 weeks in seconds". The constant `25` also does not match the `LargeWidgetView`'s `private let weeks = 25` — making it unclear whether these are intentionally in sync. A named constant would be clearer:

```swift
private let widgetCalendarWeeks = 25
let cutoff = Date().timeIntervalSince1970 - Double(widgetCalendarWeeks * 7 * 86400)
```

**Dev reply (v2.18.0):** Agreed. The `25` in `DashboardViewModel` and `LargeWidgetView` must stay in sync — a shared constant would make this explicit and prevent drift. Will add a file-level or `Shared/` constant for the widget heatmap week count in v2.19.0.

**Fixed in v2.19.0:** Added `let widgetHeatmapWeeks = 25` to `Shared/WidgetData.swift` (compiled into both the main app and widget extension targets). `DashboardViewModel` now uses `widgetHeatmapWeeks * 7 * 86400` in the cutoff calculation. `WidgetHeatmapView.weeks` now uses `widgetHeatmapWeeks` instead of the literal `25`. The stale "last 10 weeks" comment in `WidgetData.swift` was also fixed to "last 25 weeks".

### 13.5 — `ColorExtension.swift` imports both `Foundation` and `SwiftUI`

**File:** `Shared/ColorExtension.swift`, lines 1–2

**Issue:** `Color` is a SwiftUI type. This file is in `Shared/` which is compiled into both the main app and the widget extension. Importing `SwiftUI` in a Shared file is correct — both targets use SwiftUI. However, `Foundation` is imported but not explicitly needed for `Color.init(hex:)` (Scanner is Foundation — needed). Both imports are correct.

**Dev reply (v2.18.0):** No issue here — both imports are necessary and correct. No action needed.

### 13.6 — `SubmissionCalendar` uses `JSONDecoder` for a `[String: Int]` dictionary

**File:** `Shared/SubmissionCalendar.swift`, lines 10–11

**Issue:** `try? JSONDecoder().decode([String: Int].self, from: data)` creates a `JSONDecoder` instance on every `SubmissionCalendar.init`. `JSONDecoder` init is cheaper than `DateFormatter` but still not free. For a type that is constructed once per app session, this is acceptable. A file-level static `JSONDecoder` would be slightly more efficient.

**Dev reply (v2.18.0):** Agreed in principle — a file-level static `JSONDecoder` is marginally more efficient. However, `SubmissionCalendar` is constructed once per app refresh (not per render), making this a non-measurable optimization. Accepted as-is; not worth the noise of a PR for this alone.

### 13.7 — Project version shows 2.15.0 in project.yml but CLAUDE.md says "Shipped: v2.6.0"

**File:** `project.yml`, line 37

**Issue:** `MARKETING_VERSION: 2.15.0` in project.yml, but CLAUDE.md's current state section says "Shipped: v2.6.0". CLAUDE.md is out of date. This is a documentation inconsistency, not a code bug.

**Dev reply (v2.18.0):** Confirmed documentation drift. CLAUDE.md's "Current State" section has been updated to reflect v2.18.0 in recent sessions. The audit was generated against v2.15.0 — the version discrepancy it observed no longer applies. CLAUDE.md is maintained but the "Shipped:" line may lag a release or two behind during active development.

---

## 14. FILE-BY-FILE SPECIFIC ISSUES

### `LeetCodeLytics/App/LeetCodeLyticsApp.swift`
- **Line 9:** CRITICAL — real LEETCODE_SESSION JWT hardcoded. See Section 1.1.
- **Line 12:** csrfToken hardcoded. See Section 1.1.
- **Line 14–16:** `widgetDimOpacity` default initialization here is correct.
- **Lines 8, 11:** The `?.isEmpty != false` pattern is unusual. `?.isEmpty == false` is the idiomatic nil-coalescing equivalent but this reads as: "if the string exists AND is empty, this is `true`, negated to `false` — so the guard fires". It works but is harder to read than `defaults.string(forKey: key).map { !$0.isEmpty } != true`.

**Dev reply (v2.18.0):** The `?.isEmpty != false` idiom is unusual but correct. Will replace with the clearer `!(defaults.string(forKey: key)?.isEmpty ?? true)` or equivalent in v2.19.0 as part of readability cleanup.

**Fixed in v2.19.0:** Both conditions now use `!(defaults.string(forKey: key).map { !$0.isEmpty } ?? false)` which reads: "if the string is nil (map returns nil, ?? false → false, negated → true: seed) or is empty (map returns false, negated → true: seed)". Semantically identical to the old code, but the intent is explicit.

### `LeetCodeLytics/App/ContentView.swift`
- **Line 4:** `@AppStorage("username", store: .appGroup)` — correct use of App Group store.
- **Line 37:** `.preferredColorScheme(.dark)` — hardcoded dark mode. See Section 4.7.
- **Line 39:** `onOpenURL` for deep link only handles the "dashboard" scheme root. No path-based routing. Acceptable for current feature set.

### `LeetCodeLytics/App/AppGroup.swift`
- **Line 6:** Fallback to `.standard` in test environment. See Section 11.2.

### `LeetCodeLytics/Models/UserProfile.swift`
- **Lines 14–19:** `UserProfileInfo` — `realName` and `userAvatar` should be optional. See Section 10.2 and 10.3.
- **Line 16:** `ranking: Int` — zero ranking display issue. See Section 10.4.
- `UserBadge` is correctly modeled with `id: String?` and `creationDate: String?`.
- No `Identifiable` conformance on `UserBadge` — causes `ForEach` by `.offset` issue. See Section 2.7.

### `LeetCodeLytics/Models/StreakData.swift`
- **Line 3–7:** `StreakData` correctly models `streak`, `totalActiveDays`, `submissionCalendar`.
- Missing `activeYears` field despite API requesting it. See Section 10.5.

### `LeetCodeLytics/Models/RecentSubmission.swift`
- **Line 10:** `id` concatenation without separator. See Section 10.1.
- **Lines 12–13:** `date` computed property is correct (parses String timestamp to Double).
- **Lines 16–34:** `relativeTime` as computed property that calls `Date()` — acceptable, but see Section 2.4.
- **Note:** `relativeTime` does not use a `RelativeDateTimeFormatter` — it manually formats. This misses localization (e.g., "1m ago" vs locale-appropriate "1 min. ago").

**Dev reply (v2.18.0):** Localization is not a goal for this personal tool (single user, single locale). The manual formatting is intentional simplicity. `RelativeDateTimeFormatter` would be cleaner but is deferred. Cross-references to 10.1 and 2.4 addressed in their respective replies.

### `LeetCodeLytics/Models/LanguageStats.swift`
- No issues. Clean model definitions with Identifiable conformance via computed properties.

### `Shared/SubmissionCalendar.swift`
- Clean implementation. `JSONDecoder` created per init. See Section 13.6.

### `Shared/StreakCalculator.swift`
- Correct UTC Calendar usage. File-level static Calendar is correctly placed.
- No issues.

### `Shared/WidgetData.swift`
- `fetchedAt: Date?` is optional for backwards compatibility — correct.
- The comment says "last 10 weeks" but `DashboardViewModel` filters to 25 weeks. The comment is wrong.
- `static let placeholder` is the correct pattern for WidgetKit placeholder entries.

**Dev reply (v2.18.0):** The stale "last 10 weeks" comment is a documentation bug — will fix to "last 25 weeks" in v2.19.0. This is related to finding 13.4 (the magic number `25` should be a shared named constant). `fetchedAt` optional and `placeholder` pattern are both confirmed correct.

### `Shared/ColorExtension.swift`
- No issues with the implementation itself.
- Missing a `static let leetcodeOrange = Color(hex: "FFA116")` extension to avoid string duplication. See Section 4.5.

### `LeetCodeLytics/Services/LeetCodeService.swift`
- **Line 29:** `let session: URLSession` should be `private`. See Section 10.6.
- **Line 77:** Manual Cookie header construction. See Section 12.4.
- **Lines 103–121:** Double serialization in `execute<T>`. See Section 9.2.
- No handling of GraphQL `errors` field in error messages. See Section 9.3.
- Queries string literals embedded directly — acceptable for this scale, but a QueryBuilder pattern would be more maintainable.

### `LeetCodeLytics/Services/LeetCodeServiceProtocol.swift`
- Protocol extension for default parameters is idiomatic Swift. No issues.

### `LeetCodeLytics/Services/CacheService.swift`
- **Line 5:** `static var suiteName` is mutable static. See Section 3.3.
- Clean implementation otherwise.

### `LeetCodeLytics/ViewModels/DashboardViewModel.swift`
- **Lines 60–123:** `withCheckedContinuation` pattern is correct. See Section 5.1.
- **Lines 97–119:** Widget logic mixed into ViewModel. See Section 3.5.
- **Line 86:** Direct `UserDefaults.appGroup` write — bypasses CacheService. See Section 11.3.
- **Lines 22–28:** Computed stats are fine in a ViewModel — they don't run in view body.
- `DashboardCache` as `private struct` in the same file is good encapsulation.

### `LeetCodeLytics/ViewModels/SubmissionsViewModel.swift`
- **Lines 30–39:** Missing `withCheckedContinuation` pattern. See Section 2.1.
- Otherwise clean.

### `LeetCodeLytics/ViewModels/SkillsViewModel.swift`
- **Lines 38–53:** Missing `withCheckedContinuation` pattern. See Section 2.2.
- Sorted arrays stored as `@Published private(set)` — correct approach.

### `LeetCodeLytics/Views/Dashboard/DashboardView.swift`
- **Lines 4–8:** `dashboardRelativeFormatter` as file-level static — correct.
- **Lines 162–173:** `badgeInputFormatter` and `badgeDisplayFormatter` as file-level statics — correct.
- **Line 191:** `ForEach` by `.offset`. See Section 2.7.
- **Line 23:** `if let error = vm.errorMessage` — shows error banner even during loading after first successful load. This is intentional (inline refresh error) and correct.
- **Line 158:** `Color(UIColor.secondarySystemBackground)` — correct for adaptive dark/light support within forced dark mode.

### `LeetCodeLytics/Views/Dashboard/ProfileHeaderView.swift`
- No issues. Clean view with correct `AsyncImage` usage.
- **Line 38:** `profile.profile.ranking.formatted()` — uses default number formatting which adds commas. This is correct and locale-aware.

### `LeetCodeLytics/Views/Dashboard/StreakCard.swift`
- `StreakItem` is `internal`. See Section 13.2.

### `LeetCodeLytics/Views/Dashboard/ProblemStatsCard.swift`
- `ProblemRing` is `internal`. See Section 13.3.
- `progress` computed property in `ProblemRing` is fine — called from body once per ring, not in a loop.

### `LeetCodeLytics/Views/Dashboard/AcceptanceRateView.swift`
- `Color(hex: "FFA116")` called twice per render. See Section 4.4.

### `LeetCodeLytics/Views/Calendar/HeatmapGridView.swift`
- **Lines 5–23:** All three formatters/calendars are correctly placed as file-level statics.
- **Lines 79–80:** `buildWeeks()` and `buildMonthLabels` computed once via `let` in body — correct.
- **Lines 100:** `solveCount(for: date)` called per cell with redundant `startOfDay`. See Section 2.6.
- **Lines 133–141:** `Color(hex:)` per cell. See Section 4.2.

### `LeetCodeLytics/Views/Submissions/SubmissionsView.swift`
- Clean. `LazyVStack` for performance on long lists. Pull-to-refresh on all states. Good.
- `statusColor` computed property in `SubmissionRow` is fine — called once per row.

### `LeetCodeLytics/Views/Skills/SkillsView.swift`
- **Line 61:** `maxCount` computed property in `TagSection`. See Section 4.1.
- **Line 103:** `maxCount` computed property in `LanguageSection`. Same issue.
- `GeometryReader` in `ForEach` — this is acceptable but can cause layout issues if the geometry is not properly constrained. The `.frame(height: 16)` constraint helps.

**Dev reply (v2.18.0):** `GeometryReader` in `ForEach` is intentional for the proportional bar width. The `.frame(height: 16)` constraint properly bounds it — no layout issues observed in practice. Accepted as-is.

### `LeetCodeLytics/Views/Settings/SettingsView.swift`
- **Lines 4–8:** `settingsRelativeFormatter` as file-level static — correct.
- **Lines 23–27:** `lastUpdatedText` calls `Date()` in computed property — see Section 2.5.
- **Line 182:** Direct use of `LeetCodeService.shared` — see Section 3.4.
- **Lines 220–228:** `SessionCookieSheet` Cancel button uses `dismiss()` correctly — the Cancel button in `UsernameChangeSheet` also correctly uses `dismiss()`. The historical bug (Cancel calling `onSave("")`) is fixed.

**Dev reply (v2.18.0):** Cancel button fix (dismiss pattern) confirmed working correctly. Cross-references to 2.5 and 3.4 addressed in those replies.

### `LeetCodeLytics/Views/Onboarding/UsernameInputView.swift`
- **Line 75:** Direct use of `LeetCodeService.shared`. See Section 3.4.
- `Task {}` in `validate()` — see Section 5.2.

### `LeetCodeLyticsWidget/LeetCodeLyticsWidget.swift`
- **Lines 6–10:** `widgetDimOpacity()` creates new `UserDefaults` instance. See Section 3.7.
- `containerBackground` placement is correct. See Section 7.1.

### `LeetCodeLyticsWidget/Provider.swift`
- No network calls in provider — correct design. See Section 7.2.
- `loadCached()` creates a new `UserDefaults` and `JSONDecoder` on every call. For a widget, this is called at most a few times. Acceptable.
- `Calendar.current.date(byAdding:)` at line 39 — `Calendar.current` is not the UTC calendar, but for computing a 15-minute future date in local time, this is correct.

**Dev reply (v2.18.0):** `Calendar.current` for computing the 15-minute future refresh date is correct — this is a local time offset, not a UTC calendar operation. `loadCached()` cost is acceptable given widget call frequency. No action needed.

### `LeetCodeLyticsWidget/WidgetViews.swift`
- **Lines 145–157:** Static formatters/calendars at file level — correct.
- **Lines 165–170:** `dailyCounts` computed property called per cell. See Section 2.3.
- Widget views do not use `foregroundColor` (deprecated) — they use `foregroundStyle`. This is correct and more modern than the main app views.

**Dev reply (v2.18.0):** `dailyCounts` fix already applied in v2.17.0 (see 2.3 reply). `foregroundStyle` usage in widget views noted as positive — will migrate main app views from `foregroundColor` to `foregroundStyle` in v2.19.0 (see 13.1 reply).

### `LeetCodeLyticsTests/Mocks/MockLeetCodeService.swift`
- Missing call count for `fetchLanguageStats` and `fetchSkillStats`. See Section 8.2.
- Fixture builders are comprehensive and match real API shapes.

### `LeetCodeLyticsTests/ModelDecodeTests.swift`
- Comprehensive. The `testUserBadge_idIsString` regression test is exactly right.
- Missing test for `null` values in `UserProfileInfo.realName` and `userAvatar`. See Section 10.2.

### `LeetCodeLyticsTests/DashboardViewModelTests.swift`
- Dealloc test missing the "after load" variant. See Section 8.3.
- Otherwise thorough — covers success, failure, DCC preservation, widget data writing.

### `LeetCodeLyticsTests/MemoryLeakTests.swift`
- `autoreleasepool` usage is misleading for Swift objects. See Section 6.2.
- Tests work correctly despite the conceptual issue.

### `LeetCodeLyticsTests/StreakCalculatorTests.swift`
- **Line 8:** `var utcCalendar` should be `let`. See Section 8.4.
- Test coverage is excellent — covers empty, zero-count, today, yesterday, consecutive, gaps.

---

## 15. SUMMARY TABLE

| # | File | Issue | Severity |
|---|------|-------|----------|
| 1.1 | LeetCodeLyticsApp.swift L9,12 | Real JWT session token hardcoded | CRITICAL |
| 2.1 | SubmissionsViewModel.swift | Missing withCheckedContinuation pattern | Medium |
| 2.2 | SkillsViewModel.swift | Missing withCheckedContinuation pattern | Medium |
| 2.3 | WidgetViews.swift L165-170 | dailyCounts rebuilt 175x per render | Low-Medium |
| 2.5 | SettingsView.swift L23-27 | Date() in computed view property | Low |
| 2.6 | HeatmapGridView.swift L128 | Redundant startOfDay per cell | Low |
| 2.7 | DashboardView.swift L191 | ForEach by offset for badges | Low |
| 3.3 | CacheService.swift L5 | Mutable static suiteName | Low |
| 3.4 | UsernameInputView, SettingsView | LeetCodeService.shared in Views | Medium |
| 3.5 | DashboardViewModel.swift L97-119 | Widget logic in ViewModel | Low-Medium |
| 3.7 | LeetCodeLyticsWidget.swift L6-10 | UserDefaults created on each call | Low |
| 4.1 | SkillsView.swift L61,103 | maxCount computed in body | Low |
| 4.2 | HeatmapGridView.swift L133-141 | Color(hex:) per cell | Low |
| 4.4 | AcceptanceRateView.swift L14,21 | Color(hex:) per render | Low |
| 4.5 | Multiple files | "FFA116" string duplicated 8+ times | Low |
| 4.6 | Multiple files | .cornerRadius() deprecated in iOS 17+ | Style |
| 4.7 | ContentView.swift L37 | Hardcoded dark mode | Style |
| 8.2 | MockLeetCodeService.swift | Missing call counts for skills/language | Low |
| 8.3 | MemoryLeakTests.swift L12-32 | DashboardVM dealloc-after-load not tested | Low |
| 10.1 | RecentSubmission.swift L10 | id without separator (collision risk) | Low |
| 10.2 | UserProfile.swift L18 | realName not optional (decode crash risk) | Medium-High |
| 10.3 | UserProfile.swift L17 | userAvatar not optional (decode crash risk) | Medium |
| 10.4 | UserProfile.swift L16 | ranking=0 shows "Rank 0" | Low |
| 10.5 | StreakData.swift / LeetCodeService | activeYears fetched but discarded | Low |
| 10.6 | LeetCodeService.swift L29 | session property is internal | Low |
| 11.1 | SettingsView.swift L12-13 | Session tokens in UserDefaults not Keychain | Medium |
| 13.2 | StreakCard.swift L26 | StreakItem is internal | Style |
| 13.3 | ProblemStatsCard.swift L3 | ProblemRing is internal | Style |
| 13.7 | project.yml / CLAUDE.md | Version mismatch in documentation | Style |

**Dev reply (v2.18.0) — Summary table status at v2.18.0:**

| Finding | Status |
|---------|--------|
| 1.1 | Deferred (pre-AppStore blocker) |
| 2.1 | Fix planned v2.19.0 |
| 2.2 | Fix planned v2.19.0 |
| 2.3 | **Already fixed in v2.17.0** |
| 2.5 | Fix planned v2.19.0 |
| 2.6 | Fix planned v2.19.0 |
| 2.7 | Fix planned v2.19.0 |
| 3.3 | Accepted as-is (low risk) |
| 3.4 | Deferred |
| 3.5 | Accepted as-is (design decision) |
| 3.7 | Will delete with slider feature removal |
| 4.1 | Fix planned v2.19.0 |
| 4.2 | Fix planned v2.19.0 (via 4.5) |
| 4.4 | Fix planned v2.19.0 (via 4.5) |
| 4.5 | Fix planned v2.19.0 |
| 4.6 | Fix planned v2.19.0 |
| 4.7 | Accepted as-is (design decision) |
| 8.2 | Fix planned v2.19.0 |
| 8.3 | Fix planned v2.19.0 |
| 10.1 | Fix planned v2.19.0 |
| 10.2 | Fix planned v2.19.0 |
| 10.3 | Fix planned v2.19.0 |
| 10.4 | Fix planned v2.19.0 |
| 10.5 | Fix planned v2.19.0 |
| 10.6 | Fix planned v2.19.0 |
| 11.1 | Deferred (pre-AppStore blocker, with 1.1) |
| 13.2 | Deferred (style) |
| 13.3 | Fix planned v2.19.0 |
| 13.7 | Fixed (CLAUDE.md updated to reflect current version) |

---

## 16. WHAT IS DONE WELL

This section recognizes genuinely correct and well-crafted aspects of the codebase:

1. **Formatter and Calendar placement:** File-level static `let` for all `DateFormatter`, `Calendar`, and `RelativeDateTimeFormatter` instances. This was systematically corrected in v1.6.0 and v2.6.0.

2. **`buildWeeks()` / `buildMonthLabels()` pattern:** Computed once at the top of `body` and shared — the canonical solution to the double-computation problem.

3. **DCC streak preservation:** The `dccStreak` preservation on failure (empty catch block) is correct and well-tested.

4. **Pull-to-refresh on all states:** `ScrollView` wrapping all states ensures `.refreshable` works in loading, error, empty, and data states.

5. **Test isolation via `CacheService.suiteName`:** Configurable suite name in tests prevents pollution of real App Group data.

6. **`LeetCodeServiceProtocol` injection:** All ViewModels accept injected services, enabling proper unit testing.

7. **`withCheckedContinuation` + unstructured Task in DashboardViewModel:** Correctly solves the SwiftUI refreshable cancellation problem.

8. **Widget architecture (no network in extension):** The decision to never make network calls in the widget extension is correct and well-reasoned given the ~30MB memory budget.

9. **`containerBackground` placement:** Correctly placed in the `StaticConfiguration` closure, not inside view body.

10. **`MockURLProtocol`:** Clean, simple, and effective for testing the network layer end-to-end.

11. **`UserBadge.id: String?`:** The model correctly captures the API's string-typed badge ID, with a regression test preventing future regressions.

**Dev reply (v2.18.0):** All 11 positive findings are confirmed still correct at v2.18.0. The `withCheckedContinuation` pattern (item 7) has since been identified as needing to be applied to SubmissionsViewModel and SkillsViewModel as well — the fix in DashboardViewModel remains correct and is the template for those follow-up fixes.

---

*End of Audit — LeetCodeLytics v2.15.0*
*Dev replies added at v2.18.0*
