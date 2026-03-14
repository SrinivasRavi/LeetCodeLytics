# LeetCodeLytics – Claude Build Guide

## Mission
Build a complete, working iOS 17+ SwiftUI app called **LeetCodeLytics** that tracks a user's LeetCode stats.
The entire project — Swift source files, entitlements, plists, and the Xcode project file — must be generated
programmatically. The user must be able to open the `.xcodeproj` and hit ⌘R with zero manual setup.

---

## Working Philosophy

**These are non-negotiable before writing any code.**

### Read First, Code Second
Before implementing anything that touches an unfamiliar Apple framework or platform API (WidgetKit, App Groups, Background Tasks, StoreKit, etc.):
1. Read Apple's official documentation for that framework
2. Understand the memory model, lifecycle, and data flow constraints
3. Identify the correct architecture — not the fastest one to type

The widget fiasco (v2.0–v2.10) happened because `WidgetFetcher.swift` (network calls in a widget extension) was written immediately without reading WidgetKit's memory documentation. Apple's docs explicitly state widgets should read from a shared container populated by the containing app. 10 versions and hundreds of iterations were wasted because of a wrong initial architectural decision.

**Speed has no value if it produces incorrect code. Correctness is the only metric.**

### Correctness Over Speed
- Never guess at an API's behavior — read the docs or inspect the existing code
- When a bug is inconsistent (some cases work, others don't), find the root cause before shipping a fix
- A fix that treats the symptom and not the root cause will surface again
- If you're unsure whether an approach is correct, say so and research before committing to it

### Tests First, Then Code
Every feature must have tests written alongside the implementation, not as an afterthought:
- **Unit tests**: validate individual functions and model decoding (each function's contract)
- **Integration tests**: validate entire workflows end-to-end (ViewModel → Service → mock network → decoded model → published state)

The distinction matters: a unit test that passes with a mock can hide a real integration failure. See the Tests section for required coverage.

---

## Current State

**Shipped: v2.11.0** (branch: `main`)

Widgets live. App + widget stable. 106 tests pass.

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
- v2.0: WidgetKit extension — 4 widgets (2 small, medium, large), App Groups, `WidgetData` in `Shared/`, deep link
- v2.1: Test suite expanded to 98 tests (WidgetData, SkillsViewModel, InfoPlist, DashboardViewModel widget tests)
- v2.2: Memory leak tests (104 tests); static analysis clean
- v2.3: Fix "Please adopt containerBackground API" — moved `.containerBackground` to `StaticConfiguration` closure (was incorrectly placed inside view body)
- v2.4: Widget network fetches made sequential to stay within ~30MB extension memory budget
- v2.5: Widget scheme removed from Xcode — prevents accidental widget-only deploy (always use `LeetCodeLytics` scheme)
- v2.6: Audit fixes — Cancel button bug (logged user out), 4 dead model structs removed, static DateFormatter/Calendar in HeatmapGridView and BadgesView, SubmissionsView refreshable on all states

### v2.11.0 — Codebase Audit & Cleanup ✅
- `StreakCalculator.computeStreak()`: added `private static let utcCalendar` (was creating Calendar on every call — CLAUDE.md violation)
- `DashboardView.refreshTimestamp()`: added file-level `private let dashboardRelativeFormatter` (was creating RelativeDateTimeFormatter on every call — CLAUDE.md violation)
- `HeatmapGridView.buildMonthLabels`: replaced non-idiomatic `as? Date` double-optional cast with `compactMap({ $0 }).first`
- `SkillsViewModel`: changed `topAdvanced/topIntermediate/topFundamental` from computed properties (re-sorted on every access) to stored `@Published private(set)` arrays, set once in `updateTopTags(from:)` at fetch and cache time
- Removed dead field `UserProfileInfo.reputation` (fetched from API, decoded, never displayed)
- Removed dead field `StreakData.activeYears` (fetched from API, decoded, never displayed)
- Removed both dead fields from GraphQL query strings in `LeetCodeService`
- Updated mock fixtures and `ModelDecodeTests` accordingly

### v2.7–v2.10 — Widget Stability ✅
- v2.7: `WidgetData.fetchedAt`; cache-first `getTimeline`
- v2.8: `widgetURL` moved inside view bodies; `containerBackground` sole modifier in each closure; small widget `.padding(8)`; `foregroundStyle` throughout; AstroLeet 2x/3x image slots filled
- v2.9: Removed `Image("AstroLeet")` from all widget views — text/emoji-only to reduce memory footprint
- v2.10: **Root cause fix** — deleted `WidgetFetcher.swift`; widget extension now NEVER makes network calls. `getTimeline` reads only from App Group UserDefaults. Main app writes data and calls `WidgetCenter.shared.reloadAllTimelines()` on every Dashboard refresh. Eliminates OOM crash (which was the true cause of the "Please adopt containerBackground API" banner and grey placeholder).

---

## Development Standards

These rules exist because the same classes of bugs kept recurring. Each rule has a documented root cause.

### Versioning
- **PATCH** (x.y.Z): genuine one-line bug fix only — nothing else
- **MINOR** (x.Y.0): new feature, new file, new tests, significant fix — default for most work
- **MAJOR** (X.0.0): major milestone (e.g. WidgetKit launch)
- **Bump `MARKETING_VERSION` in `project.yml` on every source code change, no exceptions**
- Both `LeetCodeLytics` and `LeetCodeLyticsWidget` targets in `project.yml` must be updated together
- Forgetting to bump `project.yml` means the version shown in the app (read via `Bundle.main`) will be wrong

### Deploying to Device
- **Always run the `LeetCodeLytics` scheme** — never the widget scheme
- Running the widget scheme installs only the extension; the main app on device stays at whatever version was last installed via the main scheme
- Widget scheme was deliberately removed from the project to prevent this mistake

### WidgetKit — Critical Rules
These rules are derived from the 10-version widget stabilization effort. Read the Widget Post-Mortem section for full context.

- **The widget extension must NEVER make network calls.** Widget extensions have a hard ~30 MB memory budget. Three sequential GraphQL calls (profile + calendar + DCC) reliably exceed it, OOM-killing the extension. The correct architecture: main app fetches → writes `WidgetData` to App Group → calls `WidgetCenter.shared.reloadAllTimelines()`. Widget reads ONLY from App Group.
- **"Please adopt containerBackground API" does NOT always mean your containerBackground is wrong.** It is iOS's generic fallback when the widget extension crashes for ANY reason (most commonly OOM). Before chasing containerBackground API placement, check for OOM crashes in the device console.
- **`containerBackground(for: .widget)` must be the sole modifier** in the `StaticConfiguration` content closure. WidgetKit scans the closure root; any other modifier applied after `containerBackground` in the closure (like `.widgetURL`) is undetected.
- **`widgetURL` must be applied inside the content view's `body`**, not in the `StaticConfiguration` closure.
- **`getTimeline` must call `completion` synchronously** (or as quickly as possible). If it launches a `Task {}` and OOM-kills before calling `completion`, WidgetKit never receives a timeline entry and shows the grey redacted placeholder indefinitely.
- **`TimelineProvider` must be self-contained** — it cannot import types from the main app target. All types used in the provider (including `WidgetData`) must be compiled into the widget target directly (via `Shared/`).
- **Widget `Info.plist` must be explicit** — XcodeGen won't auto-generate for extensions. Provide `INFOPLIST_FILE` pointing to a real file in `project.yml`.
- **Both `.entitlements` files must declare `com.apple.security.application-groups`** with the value `group.com.leetcodelytics.shared`. Empty entitlements (`<dict/>`) silently break widget data sharing with no error message.

### DateFormatter / Calendar / NumberFormatter
- **Never** create `DateFormatter`, `Calendar`, `RelativeDateTimeFormatter`, or `NumberFormatter` inside a computed property, view `body`, or instance `let` property of a SwiftUI View
- All formatters and calendars must be **file-level `private let`** constants (lazily initialized once per process)
- Root cause: SwiftUI recreates view structs on every parent body evaluation. Instance properties are recreated with them. `DateFormatter` init is expensive (~0.5ms); in a 364-cell heatmap that's ~180ms per render.

### SwiftUI View Bodies
- Never put sorting, filtering, or date arithmetic in a `body`. Compute in ViewModel or as a local `let` at the top of `body` (computed once per render, not per-cell)
- `weeks` in `HeatmapGridView` is an example: it must be computed once then shared between the grid and month labels — not via two separate computed property calls
- Use `foregroundStyle` (not deprecated `foregroundColor`) throughout — iOS 17+

### Sheets / Modals — Cancel Buttons
- Cancel buttons **must** use `@Environment(\.dismiss)` — never call the completion/save callback with empty data
- Root cause: calling `onSave("")` from Cancel is indistinguishable from saving an empty username, which clears `@AppStorage("username")` and sends the user to onboarding

### Dead Model Structs
- When a service stops using a response wrapper struct, delete it immediately in the same commit
- Never leave unused `Codable` structs around "in case we need them later" — they're invisible dead weight and confuse future audits
- Rule: if a struct is not referenced by any service, ViewModel, or test, it must be deleted

### Pull-to-Refresh
- **Every scrollable view must support pull-to-refresh in all states** — loading, data, empty, and error
- Use `ScrollView + LazyVStack` (not `List`) so `.refreshable` can be placed on the outer container and applies uniformly
- Root cause: an error state with no pull-to-refresh forces the user to navigate away and back to recover

### Tests — Required Coverage

**Before writing any implementation code, write the tests first (or at minimum, write them in the same commit).**

#### Unit Tests (one feature in isolation)
- Every new model → `ModelDecodeTests` fixture test with a real API response sample
- Every new ViewModel method → ViewModel test covering success, failure, loading state transitions
- Every new widget data path → encode/decode round-trip test in `WidgetDataTests`
- Every bug fix → regression test that would have caught it (named for the bug, e.g., `testDCCStreak_preservedOnAuthFailure`)

#### Integration Tests (entire workflow, end-to-end)
Integration tests wire `ViewModel → LeetCodeService (with MockURLProtocol) → decoded model → published state`. They catch failures that unit tests miss because the full decode path is exercised.

Required integration tests:
- **ViewModel load flow**: `MockURLProtocol` returns a real-shaped JSON fixture → ViewModel calls `load()` → assert `isLoading` starts true → assert final published state matches fixture data
- **Error propagation**: `MockURLProtocol` returns 403/429/malformed JSON → ViewModel calls `load()` → assert `errorMessage` is set → assert data is not cleared if cache existed
- **Cache-then-network flow**: `CacheService` has stale data → ViewModel loads → assert cached data appears immediately → assert fresh data replaces it after network resolves
- **Widget data write**: `DashboardViewModel.load()` completes → assert `UserDefaults(suiteName: "group.com.leetcodelytics.shared")` contains valid `WidgetData`

`DashboardViewModelTests` already covers the ViewModel load flow. Expand it if new data paths are added.

---

## Widget Post-Mortem (v2.0 → v2.10)

It took 10 versions to get widgets working. This section documents exactly what went wrong and why, so future widget work starts correctly.

### What Happened, Version by Version

| Version | Change | Why it didn't work |
|---------|--------|-------------------|
| v2.0 | Added `WidgetFetcher` making 3 network calls in `getTimeline` | Network calls OOM-killed the extension on every cold start |
| v2.3 | Moved `.containerBackground` to `StaticConfiguration` closure | Correct API placement, but the banner was caused by OOM crash, not API placement |
| v2.4 | Made network calls sequential instead of concurrent | Reduced peak memory slightly, still reliably exceeded 30 MB |
| v2.7 | Cache-first `getTimeline` — skip network if cache < 30 min old | Only helped after main app had run; fresh widget add with no cache still OOM'd |
| v2.8 | Moved `widgetURL` inside views; fixed foreground colors; padded small views | Unrelated to the actual crash |
| v2.9 | Removed images from all widget views | Reduced memory slightly; did not fix the crash |
| **v2.10** | **Deleted `WidgetFetcher`; widget never makes network calls** | **Correct fix** |

### The Actual Root Cause

Widget extensions have a hard **30 MB memory ceiling**. Three sequential GraphQL responses — especially the LeetCode submission calendar, which encodes a full year of daily counts as a large JSON string — reliably pushed the extension over this limit. When the extension is killed by the OS, iOS cannot get a rendered result from `getTimeline` or `getSnapshot`, and displays a generic failure state: the "Please adopt containerBackground API" banner.

**The banner is NOT a containerBackground API error.** It is iOS's fallback render when the widget extension crashes for any reason. This was the core misdiagnosis that drove 7 wasted versions.

### Why the Diagnosis Took So Long

1. **Took the error message at face value.** "Please adopt containerBackground API" is an OS-level overlay whose text describes one specific cause. It also appears on crash. There are no other visual signals to distinguish the two.

2. **The large widget working was a misleading clue.** It worked only because its timeline happened to run after the main app had written fresh App Group cache. Small/medium timelines ran when no cache existed (network call path, OOM crash). This looked like a rendering difference, not a timing/memory difference.

3. **Incremental memory fixes (sequential calls, image removal) showed partial progress.** Each change moved the problem slightly but didn't eliminate it. This created false confidence that the approach was correct.

4. **No upfront architecture research.** Apple's WidgetKit documentation explicitly states that widget extensions should read from a shared container populated by the containing app. `WidgetFetcher` was the wrong design from line 1 of v2.0.

### The Correct Architecture (should have been v2.0)

```
Main app opens
  → DashboardViewModel.load() fetches all data
  → Writes WidgetData to App Group UserDefaults (key: "widgetData", suite: "group.com.leetcodelytics.shared")
  → Calls WidgetCenter.shared.reloadAllTimelines()

Widget extension
  → getTimeline: reads UserDefaults(suiteName:) → calls completion immediately (synchronous)
  → No network, no async, no Task, no OOM possible
```

`Provider.getTimeline` in its final correct form is 4 lines. `WidgetFetcher.swift` was 130 lines that should never have existed.

### Rules Derived From This Post-Mortem

- **Never make network calls in a widget extension.** The memory budget (~30 MB) is too small for LeetCode's calendar response.
- **"Please adopt containerBackground API" does not always mean your containerBackground is wrong.** Check for extension crashes first (device console, `EXC_RESOURCE RESOURCE_TYPE_MEMORY`).
- **When a widget error is inconsistent** (some widget sizes work, others don't), suspect timing/memory, not rendering code.
- **Read the documentation before writing new platform APIs.** The architecture was wrong from v2.0 because the memory limit and App Group data-flow pattern weren't checked first.

---

## Commit Rule — Tests Must Pass

**Run the full test suite before every commit. No exceptions.**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme LeetCodeLyticsTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' test \
  2>&1 | grep -E '(error:|passed|failed|BUILD)'
```

All 106 tests must pass. If any fail, fix before committing.

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
| Widget bundle ID | `com.leetcodelytics.app.widget` |
| App Group ID | `group.com.leetcodelytics.shared` |
| Deployment target | iOS 17.0 |
| Swift version | 5.9 |
| Username (AppStorage key) | `"username"` (default value: `"spacewanderer"`) |

---

## Directory Layout — Current (v2.10.0)

```
LeetCodeLytics/                                  ← repo root
  project.yml                                    ← XcodeGen spec (app + widget + test targets)
  LeetCodeLytics/                                ← main app sources
    App/
      LeetCodeLyticsApp.swift                    ← bootstrapCSRF(); seeds default session credentials
      ContentView.swift                          ← tab bar: Dashboard, Submissions, Skills, Settings
    Models/
      UserProfile.swift                          ← MatchedUser, SubmissionCount, SubmitStats,
                                                    UserProfileInfo, UserBadge (id: String?), ProblemCount
      StreakData.swift                            ← StreakData, UserCalendarWrapper, StreakCounterResponse
      RecentSubmission.swift                     ← title, lang, timestamp (String), statusDisplay
      LanguageStats.swift                        ← LanguageStat, TagStat, TagProblemCounts
    Services/
      LeetCodeService.swift                      ← GraphQL calls; injectable URLSession for testing
      LeetCodeServiceProtocol.swift              ← protocol enabling ViewModel mock injection
      CacheService.swift                         ← UserDefaults-backed, suiteName = nil
    ViewModels/
      DashboardViewModel.swift                   ← activeFetch guard; unstructured Task +
                                                    withCheckedContinuation; writes WidgetData to App Group
      SubmissionsViewModel.swift                 ← activeFetch guard
      SkillsViewModel.swift                      ← activeFetch guard; topAdvanced/Intermediate/Fundamental
    Views/
      Onboarding/UsernameInputView.swift
      Dashboard/DashboardView.swift
      Dashboard/ProfileHeaderView.swift
      Dashboard/StreakCard.swift
      Dashboard/ProblemStatsCard.swift
      Dashboard/AcceptanceRateView.swift
      Calendar/HeatmapGridView.swift             ← file-level static DateFormatter and Calendar
      Submissions/SubmissionsView.swift          ← refreshable on all states (loading/data/empty/error)
      Skills/SkillsView.swift
      Settings/SettingsView.swift                ← version from Bundle.main; Cancel uses @Environment(\.dismiss)
    LeetCodeLytics.entitlements                  ← App Group: group.com.leetcodelytics.shared
  LeetCodeLyticsWidget/                          ← widget extension
    Provider.swift                               ← reads App Group only; NO network calls; synchronous completion
    LeetCodeLyticsWidget.swift                   ← WidgetBundle; containerBackground = sole modifier per closure
    WidgetViews.swift                            ← 4 views (text/emoji only); widgetURL inside each body
    Info.plist
    LeetCodeLyticsWidget.entitlements            ← App Group: group.com.leetcodelytics.shared
  Shared/                                        ← compiled into BOTH app and widget targets
    WidgetData.swift                             ← Codable; fetchedAt: Date?; written by app, read by widget
    SubmissionCalendar.swift                     ← double-decode helper (JSON string → [Int: Int])
    StreakCalculator.swift                       ← any-solve streak from UTC timestamps
    ColorExtension.swift
    SharedAssets.xcassets/                       ← AstroLeet image (1x/2x/3x slots all filled)
  LeetCodeLyticsTests/
    Mocks/
      MockLeetCodeService.swift                  ← configurable mock + fixture builders
      MockURLProtocol.swift                      ← intercepts URLSession for network-layer tests
    ModelDecodeTests.swift
    StreakCalculatorTests.swift
    SubmissionCalendarTests.swift
    CacheServiceTests.swift
    LeetCodeServiceExecuteTests.swift
    DashboardViewModelTests.swift
    SubmissionsViewModelTests.swift
    WidgetDataTests.swift
    SkillsViewModelTests.swift
    InfoPlistTests.swift
    MemoryLeakTests.swift
  PersonalNotes/                                 ← never commit credentials here
    PersonalNotes.md
    BugAudit.md
    LeetCodeLytics.postman_collection.json
```

---

## Architecture

### Data Flow — Main App
```
App launch
  → bootstrapCSRF() — GET leetcode.com to seed csrftoken in cookie jar
  → ViewModel.load() — check activeFetch guard; apply cache immediately, then fetch fresh
  → LeetCodeService.execute<T>() — JSONSerialization nav to key, then JSONDecoder on that subtree
  → CacheService.save() — UserDefaults(suiteName: nil)
  → DashboardViewModel writes WidgetData to UserDefaults(suiteName: "group.com.leetcodelytics.shared")
  → WidgetCenter.shared.reloadAllTimelines()
```

### Data Flow — Widget Extension
```
WidgetKit calls getTimeline
  → Provider.loadCached() — UserDefaults(suiteName: "group.com.leetcodelytics.shared")
  → Decode WidgetData (or use .placeholder if nil)
  → Call completion(Timeline(...)) synchronously
  → Schedule next reload 15 min out (fallback; real refresh is triggered by main app via reloadAllTimelines)
```

### Key Design Decisions
- `@MainActor` on all ViewModels; `async/await` throughout
- `LeetCodeService` is a concrete class; `LeetCodeServiceProtocol` enables testing without subclassing
- `LeetCodeService` accepts injectable `URLSession` (default `.shared`); `MockURLProtocol` intercepts in tests
- All ViewModels accept injected `LeetCodeServiceProtocol` (default `LeetCodeService.shared`)
- `DashboardViewModel.load()` wraps network calls in unstructured `Task {}` + `withCheckedContinuation` to survive SwiftUI `.refreshable` task cancellation
- `StreakCalculator` works in UTC to match LeetCode's calendar timestamps
- No third-party dependencies — pure Apple SDK only

### `execute<T>` — How GraphQL Responses Are Decoded
LeetCode's GraphQL endpoint returns responses with extra keys (`errors`, `extensions`) alongside `data`. Direct `JSONDecoder` on the full response would fail if any unexpected key appears.

The pattern used:
1. `JSONSerialization.jsonObject()` on the raw `Data` → navigate to `response["data"][responseKey]`
2. `JSONSerialization.data(withJSONObject:)` to re-serialize just that subtree
3. `JSONDecoder().decode(T.self, from: subtreeData)` — decode only the relevant value

This isolates the decode from whatever extra keys LeetCode decides to include.

### Two Streak Types
- **DCC Streak** (`dccStreak`): from `streakCounter` GraphQL — counts Daily Coding Challenge solves only; requires auth cookies; fails silently (preserves previous value on any failure)
- **Solve Streak** (`anysolveStreak`): computed locally from `submissionCalendar` via `StreakCalculator` — counts any day with ≥1 solve; no auth required

### Session Credentials
Default credentials are seeded in `LeetCodeLyticsApp.init()` via `UserDefaults` if not already set. User can override via Settings → Update Session Cookies. Required for the DCC streak (`streakCounter` query). The `bootstrapCSRF()` call on launch fetches `https://leetcode.com` to populate the `csrftoken` cookie before any GraphQL requests fire.

### `activeFetch` Guard (All ViewModels)
All three ViewModels (`DashboardViewModel`, `SubmissionsViewModel`, `SkillsViewModel`) have:
```swift
private var activeFetch = false

func load(...) async {
    guard !activeFetch else { return }
    activeFetch = true
    defer { activeFetch = false }
    // ... network calls ...
}
```
Without this, rapid tab switching stacks multiple unstructured Tasks, each holding a strong reference to the ViewModel. Memory grows linearly with tab switches.

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

**All questions count** (fetched separately — sibling of `matchedUser` at GraphQL root, cannot be combined):
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
`submissionCalendar` is a JSON string: `"{\"1609459200\": 3, ...}"` — double-decode required. Keys are Unix timestamps (UTC, midnight), values are submission counts.

**DCC streak (auth required):**
```graphql
query getStreakCounter {
  streakCounter { streakCount currentDayCompleted }
}
```
Returns `null` for `streakCounter` if not authenticated. The decoded field is `streakCount`, **not** `streakCounter`.

**Recent submissions:**
```graphql
query recentSubmissions($username: String!, $limit: Int) {
  recentSubmissionList(username: $username, limit: $limit) {
    title titleSlug timestamp statusDisplay lang
  }
}
```
⚠️ `timestamp` is a **String** in the response (e.g. `"1715000000"`), not an Int.

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
- Pull-to-refresh on all states (loading, data, empty, error)

### 3. Skills Tab
- Horizontal bar chart of top 10 solved tags: Advanced / Intermediate / Fundamental
- Language breakdown

### 4. Settings Tab
- Username display + change (validates against API before saving)
- LEETCODE_SESSION + csrftoken input (shown as ●●●●●●●● when set)
- Cancel button uses `@Environment(\.dismiss)` only — never calls `onSave`
- Last updated timestamp, app version (read from `Bundle.main`)

### Onboarding
- First launch only (no username in UserDefaults)
- Validates username against API before saving

### Widgets (4 kinds)
- **SolvedStreak** (small): ⚡ icon + anysolveStreak count + "days solved"
- **DCCStreak** (small): 🔥 icon + dccStreak count + "daily streak"
- **LeetCodeMedium** (medium): both streaks + E/M/H solved counts
- **LeetCodeLarge** (large): both streaks + E/M/H counts + 10-week activity heatmap
- All widgets deep-link to `leetcodelytics://dashboard` on tap
- Widget data refreshes whenever main app Dashboard loads (via `WidgetCenter.shared.reloadAllTimelines()`)
- Fallback: WidgetKit polls every 15 minutes independently

---

## Test Suite (106 tests)

| File | Coverage |
|------|----------|
| `ModelDecodeTests` | All models vs real API fixtures; `UserBadge.id` String regression; `timestamp` String regression |
| `LeetCodeServiceExecuteTests` | extra fields, errors array, null, 403, 429, malformed JSON |
| `StreakCalculatorTests` | empty, old solves, today/yesterday, gaps, consecutive runs |
| `SubmissionCalendarTests` | valid JSON, empty, invalid, non-numeric keys, large calendar |
| `CacheServiceTests` | save/load, timestamps, stale logic, clear, key isolation |
| `DashboardViewModelTests` | load, errors, DCC preservation regression, isLoading, widget data write (integration) |
| `SubmissionsViewModelTests` | load, errors, empty state, multiple calls |
| `WidgetDataTests` | Codable round-trip, fetchedAt, legacy decode (nil fetchedAt), placeholder |
| `SkillsViewModelTests` | load, top-10 cap, sort order, empty state, multiple calls |
| `InfoPlistTests` | version ≠ "1.0" placeholder, non-empty, bundle ID prefix |
| `MemoryLeakTests` | All three ViewModels deallocate with and without load |

**Adding a new model or API call requires:**
1. A fixture decode test in `ModelDecodeTests` using a real API response sample (copy from a live API call, not invented)
2. A `fetchXxx` test in `LeetCodeServiceExecuteTests` (success + error cases)
3. A ViewModel test covering the full load → state transition (integration test)

---

## Common Pitfalls

1. **`UserBadge.id` is a String** — LeetCode returns `"7588899"` (quoted), not `7588899`. Model must be `id: String?`. Caused a Dashboard decode crash in v1.5.2.

2. **`execute<T>` must use JSONSerialization first** — Never decode the full GraphQL response as `[String: [String: T]]`. Use JSONSerialization to navigate to `data[responseKey]`, then JSONDecoder on just that value. LeetCode often includes `errors`, `extensions`, or extra keys alongside `data`.

3. **`submissionCalendar` requires double-decode** — It's a JSON string inside JSON. Decode outer as `String`, then parse that string as `[String: Int]`. The keys are Unix timestamps as strings; cast to `Int` before lookup.

4. **`allQuestionsCount` must be fetched separately** — It's a sibling of `matchedUser` at the GraphQL root. Cannot be decoded in the same `execute<T>` call as `matchedUser`. Fetch independently with `responseKey: "allQuestionsCount"`.

5. **`streakCounter` does not accept username** — Returns data for the authenticated user only. Never pass a username variable to this query.

6. **SwiftUI `.refreshable` cancels structured tasks** — `async let` inside a `.refreshable` callback creates child tasks that get cancelled when SwiftUI cancels the refresh task (scroll events, view lifecycle). Fix: wrap network calls in an unstructured `Task {}` inside `withCheckedContinuation` so they are immune to caller cancellation.

7. **DCC streak must preserve value on failure** — Never reset `dccStreak = 0` in a catch block. If the fetch fails (auth error, network error, cancellation), the previously displayed value must remain.

8. **`StreakCounterResponse.streakCount`** — The decoded field is `streakCount`, not `streakCounter`.

9. **Widget extension OOM kills look like containerBackground errors** — The "Please adopt containerBackground API" overlay appears whenever the widget extension crashes (including OOM). Before fixing API placement, check the device console for `EXC_RESOURCE RESOURCE_TYPE_MEMORY`.

10. **Widget `getTimeline` must call `completion` synchronously** — If `getTimeline` launches a `Task {}` that crashes before calling `completion`, WidgetKit never gets a timeline entry. The widget stays in the grey redacted/placeholder state indefinitely (even after 10+ minutes).

11. **Both entitlements files required for App Groups** — `LeetCodeLytics/LeetCodeLytics.entitlements` and `LeetCodeLyticsWidget/LeetCodeLyticsWidget.entitlements` must both declare `com.apple.security.application-groups = ["group.com.leetcodelytics.shared"]`. Missing one silently prevents data sharing.

12. **Widget scheme removed intentionally** — The widget scheme was deleted from `project.yml` to prevent accidentally deploying only the widget extension to device. Always use the `LeetCodeLytics` scheme.

13. **`project.yml` has two `MARKETING_VERSION` entries** — one for `LeetCodeLytics` target, one for `LeetCodeLyticsWidget`. Both must be bumped together on every version change.

14. **Never create formatters inside view bodies or computed properties** — `DateFormatter`, `Calendar`, `NumberFormatter` must be file-level `private let` constants. SwiftUI recreates view structs on every parent render; expensive inits inside views cause measurable latency.

---

## Architecture Invariants

These must hold at all times. Violating them requires explicit user approval.

1. **All models must be `Codable`** — required for `CacheService` (UserDefaults) and App Group widget sharing
2. **ViewModels call `CacheService`, never `UserDefaults` directly** — caching implementation is swappable
3. **`SubmissionCalendar` and `StreakCalculator` have no UIKit/SwiftUI imports** — they live in `Shared/` and must be usable by both targets
4. **No business logic in Views** — all derivation and computation in ViewModels
5. **Username always read from `@AppStorage("username")`** — single source of truth; never store a copy in a ViewModel
6. **All ViewModels accept injected `LeetCodeServiceProtocol`** — default = `LeetCodeService.shared`; required for unit and integration testing
7. **Widget extension reads App Group only** — zero network calls, zero async work that could OOM

---

## Backlog (deferred — do not implement until explicitly requested)

- **Unique Solved Streak:** Split "Solved Streak" into two:
  - "Any Solved Streak" — consecutive days with ≥1 successful submission
  - "Unique Solved Streak" — consecutive days where a previously-unsolved problem was accepted
- **DCC Streak end-to-end test:** Verify 🔥 Daily Question Streak works correctly end-to-end with session cookies
