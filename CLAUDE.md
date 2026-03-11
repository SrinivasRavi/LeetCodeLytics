# LeetCodeLytics – Claude Build Guide

## Mission
Build a complete, working iOS 17+ SwiftUI app called **LeetCodeLytics** that tracks a user's LeetCode stats.
The entire project — Swift source files, entitlements, plists, and the Xcode project file — must be generated
programmatically. The user must be able to open the `.xcodeproj` and hit ⌘R with zero manual setup.

---

## Versioning Plan

### Version 1.0 — Core App (current target)
A fully functioning standalone iOS app. No caching, no widgets, no App Groups, no entitlements, no WidgetKit.
One target, one scheme. Git tag: `v1.0`

**Features:**
- Onboarding: first-launch username input, validates against API
- Dashboard tab: profile header (avatar, username, real name, global ranking), Easy/Medium/Hard progress rings, acceptance rate, DCC streak (🔥) + solve streak (⚡)
- Calendar tab: 52-week GitHub-style heatmap colored by daily solve count, month labels, tap cell for count
- Submissions tab: last 20 submissions with problem title, language, color-coded status, relative timestamp
- Contest tab: rating, global ranking, top percentile, badge, Swift Charts rating history line chart, recent contest list
- Skills tab: top tags by Advanced/Intermediate/Fundamental with bar charts, language breakdown
- Settings tab: change username, enter LEETCODE_SESSION + csrftoken, refresh button, last updated timestamp

**Explicitly excluded from V1.0:** caching, WidgetKit, App Groups, `Shared/` folder, entitlements files, any widget views

**Forward-compatibility requirement:** Include a no-op `CacheService.swift` stub with the correct interface.
ViewModels call `CacheService.load()` / `CacheService.save()` — in V1.0 load returns nil and save is a no-op.
This means V1.1 only touches `CacheService.swift`, not the ViewModels.

### Version 1.1 — Local Caching
Add `UserDefaults`-backed caching to `CacheService`. ViewModels unchanged.
- On launch: show cached data immediately, fetch fresh in background
- Cache keyed by username (switching users shows correct data)
- `CacheService` uses a configurable `suiteName` (nil = standard UserDefaults in V1.1)
- Cache considered stale after 30 min but still shown during refresh
Git tag: `v1.1`

### Version 1.2 — Polish & Refinements
Minor fixes and UX improvements identified from hands-on testing of V1.1.
No major new features. Scope defined after V1.1 is tested.
Git tag: `v1.2`

### Version 2.0 — Widgets
Add widget extension on top of V1.1.
- Migrate `CacheService` suiteName from nil → `group.com.leetcodelytics.shared` (one-line change)
- Add `LeetCodeLytics.entitlements` + `LeetCodeLyticsWidget.entitlements` with App Groups
- Add `Shared/` folder (move `SubmissionCalendar.swift`, `StreakCalculator.swift` there)
- Add `LeetCodeLyticsWidget` target with all widget sizes + lock screen
Git tag: `v2.0`

---

## Forward Compatibility Rules (apply from V1.0 onwards)

These rules ensure future versions are additive, not rewriting:

1. **All models must be `Codable`** — required for V1.1 UserDefaults caching and V2.0 App Groups
2. **ViewModels call `CacheService`, never `UserDefaults` directly** — so caching implementation is swappable
3. **`CacheService` has a configurable suiteName** — nil in V1.0/V1.1, `group.com.leetcodelytics.shared` in V2.0
4. **`SubmissionCalendar` and `StreakCalculator` live in `Services/`** in V1.0; in V2.0 they move to `Shared/` — keep them free of UIKit/SwiftUI imports so the move is painless
5. **No business logic in Views** — all data derivation in ViewModels, so adding an Insights tab in V1.2 is pure addition
6. **Username always read from `@AppStorage("username")`** — single source of truth, consistent across versions
7. **`LeetCodeService` stays a plain class, not protocol-wrapped** — avoid premature abstraction; if testing is needed later, wrap it then

## Build Strategy (to avoid iterating on broken builds)

**Rule: build incrementally in dependency order. Run `xcodebuild` after each layer.**

```
Step 1: project.yml + xcodegen generate    → confirm .xcodeproj is created
Step 2: Models/                            → xcodebuild ✓ (no deps, pure structs)
Step 3: LeetCodeService.swift              → xcodebuild ✓ (uses models)
Step 4: ViewModels/                        → xcodebuild ✓ (uses service + models)
Step 5: Leaf views (no cross-view deps)    → xcodebuild ✓
Step 6: Composite views (Dashboard, etc.) → xcodebuild ✓
Step 7: ContentView + App entry point      → xcodebuild ✓
```

**Rules:**
- Never write a file that references a type not yet written
- Never skip a `xcodebuild` verification step
- Fix any error before moving to the next layer
- V1.0 has no capabilities/entitlements — eliminates all signing complexity
- Use `xcodebuild -scheme LeetCodeLytics -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E '(error:|Build succeeded)'` for fast feedback

---

## Build System
- Use **XcodeGen** (`xcodegen generate`) to produce the `.xcodeproj` from `project.yml`
- XcodeGen is installed at `/opt/homebrew/bin/xcodegen`
- After writing all source files and `project.yml`, always run `xcodegen generate` to verify it works
- Never ask the user to do anything in Xcode manually

## Project Identity
| Key | Value |
|-----|-------|
| App name | LeetCodeLytics |
| Main bundle ID | `com.leetcodelytics.app` |
| Widget bundle ID | `com.leetcodelytics.app.widget` |
| App Group ID | `group.com.leetcodelytics.shared` |
| Deployment target | iOS 17.0 |
| Swift version | 5.9 |
| Language | Swift / SwiftUI |

## Directory Layout — V1.0
```
LeetCodeLytics/                          ← repo root
  project.yml                            ← XcodeGen spec (single target, no entitlements)
  LeetCodeLytics/                        ← all app sources
    App/
      LeetCodeLyticsApp.swift
      ContentView.swift
    Models/
      UserProfile.swift                  ← SubmissionCount, SubmitStats, UserProfileResponse, UserBadge, ProblemCount
      StreakData.swift                    ← StreakData, StreakCounterResponse
      RecentSubmission.swift
      ContestRanking.swift               ← ContestRanking, ContestHistory, ContestInfo, ContestBadge
      LanguageStats.swift                ← LanguageStat, TagStat, SkillStats
      SubmissionCalendar.swift           ← SubmissionCalendar (double-decode helper)
    Services/
      LeetCodeService.swift              ← all GraphQL API calls + response types
      StreakCalculator.swift             ← any-solve streak from calendar timestamps
    ViewModels/
      DashboardViewModel.swift
      CalendarViewModel.swift
      SubmissionsViewModel.swift
      ContestViewModel.swift
      SkillsViewModel.swift
    Views/
      Onboarding/UsernameInputView.swift
      Dashboard/DashboardView.swift
      Dashboard/ProfileHeaderView.swift
      Dashboard/StreakCard.swift
      Dashboard/ProblemStatsCard.swift
      Dashboard/AcceptanceRateView.swift
      Calendar/CalendarView.swift
      Calendar/HeatmapGridView.swift
      Submissions/SubmissionsView.swift
      Contest/ContestView.swift
      Skills/SkillsView.swift
      Settings/SettingsView.swift
```

**V2.0 will add:** `LeetCodeLytics.entitlements`, `LeetCodeLyticsWidget.entitlements`, `LeetCodeLyticsWidget/` target, `Shared/` folder, `CacheService.swift`

## project.yml — V1.0 (single target, no entitlements)
```yaml
name: LeetCodeLytics
options:
  bundleIdPrefix: com.leetcodelytics
  createIntermediateGroups: true
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
targets:
  LeetCodeLytics:
    type: application
    platform: iOS
    sources:
      - LeetCodeLytics
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.leetcodelytics.app
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0.0
```

**Note:** No `CODE_SIGN_ENTITLEMENTS`, no `dependencies`, no second target. Maximum simplicity.

## Architecture

### Data Flow
```
App launch
  → LeetCodeService (GraphQL over HTTPS)
  → DashboardViewModel (holds all fetched data)
  → CacheService writes WidgetData to App Groups UserDefaults
  → WidgetCenter.reloadAllTimelines()
  → LeetCodeLyticsWidget TimelineProvider reads from App Groups
```

### Key Design Decisions
- `@MainActor` on all ViewModels; `async/await` throughout
- Single `LeetCodeService.shared` singleton with generic `execute<T>` GraphQL dispatcher
- `CacheService` wraps `UserDefaults(suiteName: AppGroupKeys.suiteName)` — same suite for app and widget
- Widget uses **cache-first** strategy: reads local cache, then fetches fresh if stale (>30 min)
- `StreakCalculator` works in UTC to match LeetCode's calendar timestamps
- No third-party dependencies — pure Apple SDK only

### Two Streak Types
- **DCC Streak** (`dccStreak`): from `streakCounter` GraphQL query — only counts Daily Coding Challenge solves; requires auth cookie
- **Solve Streak** (`anysolveStreak`): computed locally from `submissionCalendar` timestamps via `StreakCalculator` — counts any day with ≥1 solve

## LeetCode GraphQL API

**Endpoint:** `POST https://leetcode.com/graphql`

**Required headers:**
```
Content-Type: application/json
Referer: https://leetcode.com
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)
Cookie: LEETCODE_SESSION=<token>; csrftoken=<token>   ← optional, for private data
x-csrftoken: <token>                                   ← optional, for private data
```

### GraphQL Queries (all verified working)

**User profile + solve counts:**
```graphql
query getUserProfile($username: String!) {
  matchedUser(username: $username) {
    username
    profile { ranking userAvatar realName reputation }
    submitStats: submitStatsGlobal {
      acSubmissionNum { difficulty count submissions }
      totalSubmissionNum { difficulty count submissions }
    }
    badges { name icon }
  }
  allQuestionsCount { difficulty count }
}
```

**Submission calendar (heatmap + any-solve streak):**
```graphql
query userProfileCalendar($username: String!, $year: Int) {
  matchedUser(username: $username) {
    userCalendar(year: $year) {
      activeYears streak totalActiveDays submissionCalendar
    }
  }
}
```
`submissionCalendar` is a JSON string: `"{\"1609459200\": 3, ...}"` — Unix timestamps → solve count.

**DCC streak (auth required):**
```graphql
query getStreakCounter {
  streakCounter { streakCount currentDayCompleted }
}
```

**Recent submissions:**
```graphql
query recentSubmissions($username: String!, $limit: Int) {
  recentSubmissionList(username: $username, limit: $limit) {
    title titleSlug timestamp statusDisplay lang
  }
}
```

**Contest ranking:**
```graphql
query userContestRanking($username: String!) {
  userContestRankingInfo(username: $username) {
    rating globalRanking localRanking topPercentage
    badge { name icon }
  }
}
```

**Contest history:**
```graphql
query userContestHistory($username: String!) {
  userContestRankingInfo(username: $username) {
    contestHistory {
      attended trendDirection problemsSolved totalProblems
      finishTimeInSeconds rating ranking
      contest { title startTime }
    }
  }
}
```

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

## App Features (all tabs)

### 1. Dashboard Tab
- Profile header: avatar (AsyncImage), username, real name, global ranking
- Problem stats card: Easy / Medium / Hard solved vs total, with colored progress rings
- Acceptance rate view
- Streak card: DCC streak (🔥) + Solve streak (⚡), total active days
- 52-week GitHub-style heatmap (mini version, tappable to go to Calendar tab)

### 2. Calendar Tab
- Full-year heatmap grid (HeatmapGridView): 52 columns × 7 rows, colored by daily solve count
- Month labels above columns
- Tap a cell to see solve count for that day

### 3. Submissions Tab
- List of recent 20 submissions
- Shows: problem title, language, status (color-coded: green=Accepted, red=Wrong Answer, etc.), relative timestamp

### 4. Contest Tab
- Rating display with badge (if any)
- Global ranking, top percentile
- Line chart of contest rating history (using Swift Charts)
- List of recent contests with result (trend arrow, problems solved, rank)

### 5. Skills Tab
- Horizontal bar chart of top solved tags grouped by: Advanced / Intermediate / Fundamental
- Language pie/bar chart

### 6. Settings Tab
- Show current username with option to change
- Session cookie input (LEETCODE_SESSION + csrftoken) for private data
- "Refresh Data" button
- Last updated timestamp
- App version

### Onboarding
- Shown on first launch (no username stored yet)
- Single text field for LeetCode username
- Validates by attempting a profile fetch; shows error if user not found

## Widgets — V2.0 ONLY (do not build in V1.0)

### Widget Bundle — Two Separate Widgets
`LeetCodeLyticsWidget.swift` defines two `Widget` structs registered in `LeetCodeLyticsWidgetBundle`:

**LeetCodeLyticsHomeWidget** — home screen:
- `.systemSmall` → `SmallWidgetView`: username, total solved, both streaks
- `.systemMedium` → `MediumWidgetView`: username, Easy/Medium/Hard counts, both streaks
- `.systemLarge` → `LargeWidgetView`: all of medium + mini heatmap (last 10 weeks)

**LeetCodeLyticsLockScreenWidget** — lock screen:
- `.accessoryCircular` → gauge showing DCC streak
- `.accessoryRectangular` → username + both streaks + total solved
- `.accessoryInline` → single line: "🔥N ⚡N · N solved"

### Widget Data Sharing
`CacheService` writes a `WidgetData` struct (JSON-encoded) to:
```swift
UserDefaults(suiteName: "group.com.leetcodelytics.shared")
```
The widget's `TimelineProvider` reads from the same suite. If cache is missing or >30 min old,
`TimelineProvider` does its own self-contained GraphQL fetch (it does NOT import or call
`LeetCodeService` from the main app — it uses private local decode types to stay isolated).

## Shared Models — V2.0 ONLY (compiled into both targets)

### WidgetData
```swift
public struct WidgetData: Codable {
    public var username: String
    public var ranking: Int
    public var totalSolved: Int
    public var easySolved: Int, mediumSolved: Int, hardSolved: Int
    public var totalEasy: Int, totalMedium: Int, totalHard: Int
    public var acceptanceRate: Double
    public var dccStreak: Int
    public var anysolveStreak: Int
    public var totalActiveDays: Int
    public var lastFetched: Date
}
```

### AppGroupKeys
```swift
public enum AppGroupKeys {
    public static let suiteName = "group.com.leetcodelytics.shared"
    public static let widgetData = "widgetData"
    public static let lastUpdated = "lastUpdated"
    public static let username = "username"
}
```

### StreakCalculator
Computes consecutive-day streak from `[Int: Int]` (Unix timestamp → solve count).
Works in UTC. Allows streak to be live if today not yet solved (falls back to yesterday).

## Error Handling
```swift
enum LeetCodeError: LocalizedError {
    case invalidUsername    // matchedUser is null
    case networkError(Error)
    case decodingError(Error)
    case unauthorized       // HTTP 403
    case rateLimited        // HTTP 429
}
```
ViewModels expose `@Published var errorMessage: String?` shown as alerts in views.

## UI Style
- Dark mode first (LeetCode brand feel)
- Accent color: `#FFA116` (LeetCode orange)
- Use SF Symbols throughout
- Difficulty colors: Easy = `.green`, Medium = `.orange`, Hard = `.red`
- Cards with rounded corners, subtle background using `.secondarySystemBackground`

## Common Pitfalls (from previous iteration)
1. **App Groups not in entitlements** — the widget can't read data. Fix: both `.entitlements` files must declare `com.apple.security.application-groups` with `group.com.leetcodelytics.shared`. The old project had EMPTY entitlements (`<dict/>`), which silently broke widget data sharing.
2. **`streakCounter` query ignores username** — it returns data for the authenticated user only; don't pass username variable
3. **`submissionCalendar` is a JSON string inside JSON** — requires double-decode: first as `String`, then parse that string as `[String: Int]`
4. **Widget `Info.plist` must be explicit** — XcodeGen won't auto-generate it for extensions; must provide `INFOPLIST_FILE` setting pointing to a real file
5. **Shared files target membership** — in `project.yml`, list `Shared` as a source path in BOTH targets so XcodeGen compiles them into both
6. **`allQuestionsCount` cannot be decoded by the generic execute method** — the `execute<T>(responseKey:)` method extracts one key from `data{}`. Since `allQuestionsCount` is a sibling of `matchedUser` at the GraphQL root, it can't be decoded in the same call. Fetch it separately or hardcode totals. Do NOT try to decode both in one call.
7. **`TimelineProvider` must be self-contained** — it cannot import types from the main app target. Use private local structs for decoding widget fetch responses.
8. **Two response types for profile** — `LeetCodeService` returns `UserProfileResponse` (API response struct). There is also a `UserProfile` domain model with computed properties (totalSolved, acceptanceRate, etc.). ViewModels hold `UserProfileResponse`, views use it directly.
9. **`StreakCounterResponse.streakCount`** (not `streakCounter`) is the field name returned by the `streakCounter` GraphQL query.

## Build Verification Checklist — V1.0
After generating all files and running `xcodegen generate`:
- [ ] `LeetCodeLytics.xcodeproj` exists
- [ ] No entitlements files exist (not needed in V1.0)
- [ ] No widget sources exist (not needed in V1.0)
- [ ] Every file referenced in `project.yml` sources path exists on disk
- [ ] `xcode-select` points to Xcode: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- [ ] Build succeeds: `xcodebuild -project LeetCodeLytics.xcodeproj -scheme LeetCodeLytics -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E '(error:|Build succeeded)'`
- [ ] Git commit tagged `v1.0`
