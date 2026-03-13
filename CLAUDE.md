# LeetCodeLytics – Claude Build Guide

## Mission
Build a complete, working iOS 17+ SwiftUI app called **LeetCodeLytics** that tracks a user's LeetCode stats.
The entire project — Swift source files, entitlements, plists, and the Xcode project file — must be generated
programmatically. The user must be able to open the `.xcodeproj` and hit ⌘R with zero manual setup.

---

## Current State

**Shipped: v2.6.0** (branch: `main`)

Widgets live. App + widget stable. 104 tests pass.

---

## Versioning History

### v1.0 — Core App ✅
Standalone iOS app with all tabs, onboarding, and live API data.

### v1.1 — Local Caching ✅
`UserDefaults`-backed `CacheService`. Cache-first strategy: show cached data immediately, fetch fresh in background. Cache keyed by username, stale after 30 min.

### v1.2–v1.4 — Polish & Refinements ✅
UI fixes from hands-on testing: streak card layout, badge deduplication, pull-to-refresh on all tabs, "Updated X ago" timestamp, tab restructure (Calendar merged into Dashboard, Contest tab removed).

### v1.5.x — Stability & Testing ✅
- v1.5: CSRF bootstrap fix (`bootstrapCSRF()` GET on launch populates cookie jar)
- v1.5.1: Robust `execute<T>` (JSONSerialization-first, then JSONDecoder on specific key)
- v1.5.2: `UserBadge.id` fixed from `Int?` → `String?` (was causing Dashboard decode crash)
- v1.5.3: Default session credentials seeded on first launch
- v1.5.4: Pull-to-refresh cancelled error suppressed (partial fix)
- v1.5.5: Pull-to-refresh fully fixed via unstructured Task + `withCheckedContinuation`; full test suite added (77 tests)

### v1.6.0 — Performance Cleanup & Dead Code Removal ✅
- Added `activeFetch` guard to all three ViewModels (Dashboard, Submissions, Skills) — prevents Task stacking on rapid tab switching (fixes memory growth)
- Deleted dead Contest system: `ContestView.swift`, `ContestViewModel.swift`, `ContestRanking.swift`, `fetchContestRanking/History` from service
- Deleted dead Calendar view/viewmodel: `CalendarView.swift`, `CalendarViewModel.swift` (merged into Dashboard in v1.2)
- Moved tag sorting out of `SkillsView` body into `SkillsViewModel` computed properties (`topAdvanced/Intermediate/Fundamental`)
- `HeatmapGridView`: static `DateFormatter` (was recreated every render); fixed dead closure no-op
- `SettingsView`: version string now reads from `Bundle.main` — no more manual version bump in UI
- Removed dead `statusColor: String` from `RecentSubmission` (duplicate of `SkillsView` color mapping)
- Removed unused `import Charts` from `SkillsView`

### v2.0–v2.6 — Widgets & Stability ✅
- v2.0: WidgetKit extension — 4 widgets (2 small, medium, large), App Groups, `WidgetFetcher`, `WidgetData` in `Shared/`, astroLeet logo, deep link
- v2.1: Test suite expanded to 98 tests (WidgetData, SkillsViewModel, InfoPlist, DashboardViewModel widget tests)
- v2.2: Memory leak tests (104 tests); static analysis clean
- v2.3: Fix "Please adopt containerBackground API" — moved `.containerBackground` to `StaticConfiguration` closure (was incorrectly placed inside view body)
- v2.4: Widget network fetches made sequential to stay within ~30MB extension memory budget
- v2.5: Widget scheme removed from Xcode — prevents accidental widget-only deploy (always use `LeetCodeLytics` scheme)
- v2.6: Audit fixes — Cancel button bug (logged user out), 4 dead model structs removed, static DateFormatter/Calendar in HeatmapGridView and BadgesView, SubmissionsView refreshable on all states

---

## Development Standards

These rules exist because the same classes of bugs kept recurring. Each rule has a root cause.

### Versioning
- **PATCH** (x.y.Z): genuine one-line bug fix only — nothing else
- **MINOR** (x.Y.0): new feature, new file, new tests, significant fix — default for most work
- **MAJOR** (X.0.0): major milestone (e.g. WidgetKit launch)
- Bump version on **every** source code change, no exceptions

### Deploying to Device
- **Always run the `LeetCodeLytics` scheme** — never the widget scheme
- Running the widget scheme installs only the extension; the main app on device stays at whatever version was last installed via the main scheme
- Widget scheme was deliberately removed from the project to prevent this mistake

### WidgetKit
- `.containerBackground(for: .widget)` **must** be applied in the `StaticConfiguration` content closure — NOT inside a view's `body`. WidgetKit scans the closure root; placement inside `body` is undetected and causes the "Please adopt containerBackground API" system overlay.

### DateFormatter / Calendar / NumberFormatter
- **Never** create `DateFormatter`, `Calendar`, `RelativeDateTimeFormatter`, or `NumberFormatter` inside a computed property, view `body`, or instance `let` property of a SwiftUI View
- All formatters and calendars must be **file-level `private let`** constants (lazily initialized once per process)
- Reason: SwiftUI recreates view structs on every parent body evaluation. Instance properties are recreated with them. `DateFormatter` init is expensive (~0.5ms); in a 364-cell heatmap that's ~180ms per render.

### SwiftUI view bodies
- Never put sorting, filtering, or date arithmetic in a `body`. Compute in ViewModel or as a local `let` at the top of `body` (computed once per render, not per-cell)
- `weeks` in `HeatmapGridView` is an example: it must be computed once then shared between the grid and month labels — not via two separate computed property calls

### Sheets / Modals — Cancel buttons
- Cancel buttons **must** use `@Environment(\.dismiss)` — never call the completion/save callback with empty data
- Calling `onSave("")` from Cancel is indistinguishable from saving an empty username, which clears `@AppStorage("username")` and sends the user to onboarding

### Dead model structs
- When a service stops using a response wrapper struct, delete it immediately in the same commit
- Never leave unused `Codable` structs around "in case we need them later" — they're invisible dead weight and confuse future audits
- Rule: if a struct is not referenced by any service, ViewModel, or test, it must be deleted

### Pull-to-refresh
- **Every scrollable view must support pull-to-refresh in all states** — loading, data, empty, and error
- If you use `List`, move to `ScrollView + LazyVStack` so `.refreshable` can be placed on the outer container and applies uniformly
- An error state with no pull-to-refresh forces the user to navigate away and back

### Tests required for
- Every new model → `ModelDecodeTests` fixture test
- Every new ViewModel method → ViewModel test covering success, failure, loading state
- Every new widget data path → encode/decode round-trip test
- Every bug fix → regression test that would have caught it

---

## Commit Rule — Tests Must Pass

**Run the full test suite before every commit.** No exceptions.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme LeetCodeLyticsTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' test \
  2>&1 | grep -E '(error:|passed|failed|BUILD)'
```

All 77 tests must pass. If any fail, fix before committing.

---

## Build System
- Use **XcodeGen** (`/opt/homebrew/bin/xcodegen generate`) to produce the `.xcodeproj` from `project.yml`
- After any `project.yml` change, run `xcodegen generate` before building
- Never ask the user to do anything in Xcode manually
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` prefix required on all `xcodebuild` calls

**Fast build check:**
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme LeetCodeLytics \
  -destination 'platform=iOS Simulator,name=iPhone 16' build \
  2>&1 | grep -E '(error:|BUILD SUCCEEDED)'
```

---

## Project Identity
| Key | Value |
|-----|-------|
| App name | LeetCodeLytics |
| Main bundle ID | `com.leetcodelytics.app` |
| Test bundle ID | `com.leetcodelytics.app.tests` |
| Widget bundle ID | `com.leetcodelytics.app.widget` (V2.0) |
| App Group ID | `group.com.leetcodelytics.shared` (V2.0) |
| Deployment target | iOS 17.0 |
| Swift version | 5.9 |
| Username (AppStorage) | `spacewanderer` |

---

## Directory Layout — Current (v1.6.0)

```
LeetCodeLytics/                          ← repo root
  project.yml                            ← XcodeGen spec (app + test targets)
  LeetCodeLytics/                        ← app sources
    App/
      LeetCodeLyticsApp.swift            ← seeds default session credentials on first launch
      ContentView.swift
    Models/
      UserProfile.swift                  ← MatchedUser, SubmissionCount, SubmitStats,
                                            UserProfileInfo, UserBadge (id: String?), ProblemCount
      StreakData.swift                    ← StreakData, UserCalendarWrapper, StreakCounterResponse
      RecentSubmission.swift
      LanguageStats.swift                ← LanguageStat, TagStat, TagProblemCounts
      SubmissionCalendar.swift           ← double-decode helper (JSON string → [Int: Int])
    Services/
      LeetCodeService.swift              ← GraphQL calls; injectable URLSession for testing
      LeetCodeServiceProtocol.swift      ← protocol enabling ViewModel mock injection
      StreakCalculator.swift             ← any-solve streak from calendar timestamps (UTC)
      CacheService.swift                 ← UserDefaults-backed, suiteName = nil (→ App Groups in V2.0)
    ViewModels/
      DashboardViewModel.swift           ← activeFetch guard + unstructured Task + withCheckedContinuation
      SubmissionsViewModel.swift         ← activeFetch guard
      SkillsViewModel.swift              ← activeFetch guard; exposes topAdvanced/Intermediate/Fundamental
    Views/
      Onboarding/UsernameInputView.swift
      Dashboard/DashboardView.swift
      Dashboard/ProfileHeaderView.swift
      Dashboard/StreakCard.swift
      Dashboard/ProblemStatsCard.swift
      Dashboard/AcceptanceRateView.swift
      Calendar/HeatmapGridView.swift     ← static DateFormatter (file-level)
      Submissions/SubmissionsView.swift
      Skills/SkillsView.swift
      Settings/SettingsView.swift        ← version read from Bundle.main
  LeetCodeLyticsTests/
    Mocks/
      MockLeetCodeService.swift          ← configurable mock + fixture builders
      MockURLProtocol.swift              ← intercepts URLSession for network tests
    ModelDecodeTests.swift
    StreakCalculatorTests.swift
    SubmissionCalendarTests.swift
    CacheServiceTests.swift
    LeetCodeServiceExecuteTests.swift
    DashboardViewModelTests.swift
    SubmissionsViewModelTests.swift
  PersonalNotes/                         ← never commit credentials here (gitignore if needed)
    PersonalNotes.md
    BugAudit.md
    LeetCodeLytics.postman_collection.json
```

**V2.0 will add:** `LeetCodeLytics.entitlements`, `LeetCodeLyticsWidget.entitlements`, `LeetCodeLyticsWidget/` target, `Shared/` folder

---

## Architecture

### Data Flow
```
App launch
  → bootstrapCSRF() — GET leetcode.com to seed csrftoken in cookie jar
  → ViewModel.load() — apply cache immediately, then fetch fresh
  → LeetCodeService.execute<T>() — JSONSerialization nav to key, then JSONDecoder
  → CacheService.save() — UserDefaults (nil suite in V1.x, App Groups in V2.0)
```

### Key Design Decisions
- `@MainActor` on all ViewModels; `async/await` throughout
- `LeetCodeService` is a concrete class; `LeetCodeServiceProtocol` enables testing
- `LeetCodeService` accepts injectable `URLSession` (default `.shared`); `MockURLProtocol` intercepts in tests
- All ViewModels accept injected `LeetCodeServiceProtocol` (default `LeetCodeService.shared`)
- `DashboardViewModel.load()` wraps network calls in unstructured `Task {}` + `withCheckedContinuation` to survive SwiftUI `.refreshable` task cancellation
- `CacheService.suiteName` = nil in V1.x; change to `group.com.leetcodelytics.shared` in V2.0
- `StreakCalculator` works in UTC to match LeetCode's calendar timestamps
- No third-party dependencies — pure Apple SDK only

### Two Streak Types
- **DCC Streak** (`dccStreak`): from `streakCounter` GraphQL — counts Daily Coding Challenge solves only; requires auth cookies; fails silently (preserves previous value)
- **Solve Streak** (`anysolveStreak`): computed locally from `submissionCalendar` via `StreakCalculator` — counts any day with ≥1 solve

### Session Credentials
Default credentials are seeded in `LeetCodeLyticsApp.init()` via `UserDefaults` if not already set. User can override via Settings → Update Session Cookies. These are required for the DCC streak (`streakCounter` query).

---

## LeetCode GraphQL API

**Endpoint:** `POST https://leetcode.com/graphql`

**Required headers for all requests:**
```
Content-Type: application/json
Referer: https://leetcode.com
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1
```

**Additional headers for authenticated requests (DCC streak):**
```
Cookie: LEETCODE_SESSION=<token>; csrftoken=<token>
x-csrftoken: <token>
```

### GraphQL Queries (all verified working against real API)

**User profile:**
```graphql
query getUserProfile($username: String!) {
  matchedUser(username: $username) {
    username
    profile { ranking userAvatar realName reputation }
    submitStats: submitStatsGlobal {
      acSubmissionNum { difficulty count submissions }
      totalSubmissionNum { difficulty count submissions }
    }
    badges { id name icon creationDate }
  }
}
```
⚠️ `badges.id` is a **String** in the API response (e.g. `"7588899"`), not an Int.

**All questions count** (fetched separately — cannot be combined with matchedUser in execute<T>):
```graphql
query allQuestionsCount {
  allQuestionsCount { difficulty count }
}
```

**Submission calendar:**
```graphql
query userProfileCalendar($username: String!, $year: Int) {
  matchedUser(username: $username) {
    userCalendar(year: $year) {
      activeYears streak totalActiveDays submissionCalendar
    }
  }
}
```
`submissionCalendar` is a JSON string: `"{\"1609459200\": 3, ...}"` — double-decode required.

**DCC streak (auth required):**
```graphql
query getStreakCounter {
  streakCounter { streakCount currentDayCompleted }
}
```
Returns `null` for `streakCounter` if not authenticated.

**Recent submissions:**
```graphql
query recentSubmissions($username: String!, $limit: Int) {
  recentSubmissionList(username: $username, limit: $limit) {
    title titleSlug timestamp statusDisplay lang
  }
}
```
⚠️ `timestamp` is a **String** in the response, not an Int.

**Language stats:**
```graphql
query languageStats($username: String!) {
  matchedUser(username: $username) {
    languageProblemCount { languageName problemsSolved }
  }
}
```

**Skill/tag stats:**
```graphql
query skillStats($username: String!) {
  matchedUser(username: $username) {
    tagProblemCounts {
      advanced { tagName tagSlug problemsSolved }
      intermediate { tagName tagSlug problemsSolved }
      fundamental { tagName tagSlug problemsSolved }
    }
  }
}
```

---

## App Features (current tabs)

### 1. Dashboard Tab
- Profile header: avatar (AsyncImage), username, real name, global ranking
- Problem stats card: Easy / Medium / Hard solved vs total with progress rings
- Acceptance rate card
- Streak card: DCC streak (🔥 Daily Question Streak) + Solve streak (⚡ Solved Streak)
- Last 52 weeks card: Max Streak, Active for count, submission activity heatmap, badges
- Pull-to-refresh; "Updated X ago" in toolbar; orange error banner on failure

### 2. Submissions Tab
- List of recent 20 submissions
- Problem title, language, color-coded status, relative timestamp
- Pull-to-refresh

### 3. Skills Tab
- Horizontal bar chart of top solved tags: Advanced / Intermediate / Fundamental
- Language breakdown

### 4. Settings Tab
- Username display + change (validates against API)
- LEETCODE_SESSION + csrftoken input (shown as ●●●●●●●● when set)
- Last updated timestamp, app version

### Onboarding
- First launch only (no username in UserDefaults)
- Validates username against API before saving

---

## Test Suite (77 tests)

| File | Coverage |
|------|----------|
| `ModelDecodeTests` | All models vs real API fixtures; `UserBadge.id` String regression |
| `LeetCodeServiceExecuteTests` | extra fields, errors array, null, 403, 429, malformed JSON |
| `StreakCalculatorTests` | empty, old solves, today/yesterday, gaps, consecutive runs |
| `SubmissionCalendarTests` | valid JSON, empty, invalid, non-numeric keys, large calendar |
| `CacheServiceTests` | save/load, timestamps, stale logic, clear, key isolation |
| `DashboardViewModelTests` | load, errors, DCC preservation regression, isLoading transitions |
| `SubmissionsViewModelTests` | load, errors, empty state, multiple calls |

**Adding a new model or API call requires:**
1. A fixture decode test in `ModelDecodeTests` using a real API response sample
2. A `fetchXxx` test in `LeetCodeServiceExecuteTests`
3. A ViewModel test if a new ViewModel method is added

---

## Common Pitfalls

1. **`UserBadge.id` is a String** — LeetCode returns `"7588899"` (quoted), not `7588899`. Model must be `id: String?`.

2. **`execute<T>` must use JSONSerialization first** — Never decode the full GraphQL response as `[String: [String: T]]`. Use JSONSerialization to navigate to `data[responseKey]`, then JSONDecoder on just that value. LeetCode often includes `errors`, `extensions`, or extra keys alongside `data`.

3. **`submissionCalendar` requires double-decode** — It's a JSON string inside JSON. Decode outer as `String`, then parse that string as `[String: Int]`.

4. **`allQuestionsCount` must be fetched separately** — It's a sibling of `matchedUser` at the GraphQL root. Cannot be decoded in the same `execute<T>` call as `matchedUser`. Fetch independently with `responseKey: "allQuestionsCount"`.

5. **`streakCounter` does not accept username** — Returns data for the authenticated user only. Never pass a username variable to this query.

6. **SwiftUI `.refreshable` cancels structured tasks** — `async let` inside a `.refreshable` callback creates child tasks that get cancelled when SwiftUI cancels the refresh task (scroll events, view lifecycle). Fix: wrap network calls in an unstructured `Task {}` inside `withCheckedContinuation` so they are immune to caller cancellation.

7. **DCC streak must preserve value on failure** — Never reset `dccStreak = 0` in a catch block. If the fetch fails (auth error, network error, cancellation), the previously displayed value should remain.

8. **`StreakCounterResponse.streakCount`** — The decoded field is `streakCount`, not `streakCounter`.

9. **App Groups not in entitlements (V2.0 reminder)** — Both `.entitlements` files must declare `com.apple.security.application-groups`. Empty entitlements (`<dict/>`) silently break widget data sharing.

10. **Widget `Info.plist` must be explicit (V2.0)** — XcodeGen won't auto-generate for extensions. Provide `INFOPLIST_FILE` pointing to a real file.

11. **`TimelineProvider` must be self-contained (V2.0)** — Cannot import types from the main app target. Use private local decode structs.

---

## Forward Compatibility Rules

1. **All models must be `Codable`** — required for UserDefaults caching and V2.0 App Groups
2. **ViewModels call `CacheService`, never `UserDefaults` directly** — caching implementation is swappable
3. **`CacheService.suiteName` = nil in V1.x** — change to `group.com.leetcodelytics.shared` in V2.0
4. **`SubmissionCalendar` and `StreakCalculator` stay free of UIKit/SwiftUI** — so they can move to `Shared/` in V2.0 without changes
5. **No business logic in Views** — all derivation in ViewModels
6. **Username always read from `@AppStorage("username")`** — single source of truth
7. **All ViewModels accept injected `LeetCodeServiceProtocol`** — default = `LeetCodeService.shared`; required for testing

---

## V2.0 Preparation Checklist

Before starting V2.0:
- [x] All 77 tests pass (v1.6.0)
- [ ] App verified working on device (v1.6.0)
- [x] `CacheService.suiteName` is nil (ready for one-line change to App Groups)
- [x] `SubmissionCalendar` and `StreakCalculator` have no UIKit/SwiftUI imports
- [x] Dead code removed (Contest system, Calendar VM/View)

---

## Backlog (deferred — do not implement until explicitly requested)

- **Unique Solved Streak:** Split "Solved Streak" into two:
  - "Any Solved Streak" — consecutive days with ≥1 successful submission
  - "Unique Solved Streak" — consecutive days where a previously-unsolved problem was accepted
- **DCC Streak end-to-end test:** Verify 🔥 Daily Question Streak works correctly end-to-end with session cookies
