# LeetCodeLytics — Opus Brief: MVP → App Store Production

This document is written for Claude Opus to execute on. Read it fully before writing a single line of code.
Dev note: I will refer to you as Mr.Opus so you know which part is written by me(Srinivas)
---

## What this app is

A personal LeetCode companion iOS app. It fetches a user's LeetCode stats via LeetCode's private GraphQL API and surfaces them as an app + home screen widgets. No backend. No user accounts. Free forever. The user (Srinivas) built it for himself and wants to ship it to the App Store for other LeetCode users.

**The product philosophy:** Duolingo-like motivation for competitive programming. Streaks, momentum, habit tracking. The north star is a full social + gamification experience, but that requires a backend and comes later. The current scope is the solo-user, no-backend version.

---

## Current state: v2.34.0

The app is functional and working. Key capabilities:
- Dashboard: profile, problem stats, solve streak, DCC streak, 52-week submissions/activity heatmap, badges
- Submissions tab: last 20 submissions
- Skills tab: tag breakdown (Advanced/Intermediate/Fundamental), language breakdown
- Settings: username change, LeetCode login (WebView), background dim slider
- 4 widgets: SolvedStreak (small), DCCStreak (small), Medium (DCC Streak, Solved Streak, Easy/Medium/hard questions solved), Large (all of medium + 25 week submissions heatmap)
- Dynamic widget backgrounds: Rocket1–4 cycling every 6h UTC, Success on solve, Broken on streak break
- Background App Refresh: updates widget without opening app
- 120 tests passing

**Committed and stable.**  Mr. Opus, Maintain exact same UI and functionality. Do not regress any of this. Refer to existing code as much as you want. I cannot stress this enough. DO NOT THROW AWAY CURRENT CODE BLINDLY if and when you rebuild. It exists for you to refer for UI and functionality. 

---

## What needs to be built — in priority order

### Priority 0: Rearchitect, rebuild and simplify (This will be v3)
The current codebase was built with several back and forth, lost context, regressed features, countless recurring bugs. The current state of codebase is likely spaghetti code that barely works, let alone be ready for AppStore release. So retaining the UI and functionality exactly as is, build a production grade app that is ready for AppStore release.

### Priority 1: Topic Suggestions ("Muscle Memory" feature) (This will be in v4)

**What the user wants:** The app should tell them which algorithm topic/category they haven't practiced in the longest time, so they can stay "in shape" across all topics — like exercising different muscle groups.

**Data available from LeetCode API:**
- `tagProblemCounts`: total problems solved per tag (Advanced/Intermediate/Fundamental). No timestamps.
- `recentSubmissionList`: last 20 submissions — title, titleSlug, timestamp (Unix), statusDisplay, lang. These DO have timestamps.
- `languageProblemCount`: problems solved per language.

**The constraint:** The API only returns the last 20 submissions. You cannot get WHEN a user last solved a problem in a specific topic beyond those 20 items. Submissions older than the most recent 20 are invisible to the API.

**The honest design that works within this constraint:** (Mr. Opus, below suggestions is by Sonnet, use your own analysis rather than relying on Sonnet recommendations)
- Cross-reference `recentSubmissionList` with a local tag-slug mapping to infer which topics appear in recent submissions and when
- For topics NOT appearing in the last 20 submissions: they are "overdue" — the user hasn't solved them recently
- Rank topics by: (a) not seen in last 20 submissions = highest priority, (b) last seen timestamp ascending = oldest first
- The feature gets more accurate over time as the app accumulates a local history of submissions (see Priority 2)
- Be honest in the UI: "Based on your last 20 submissions + local history since install"

**LeetCode's tag slugs for topics:** Use the `tagProblemCounts` response to get the canonical list of tags the user has solved. Map recent submission titles to topics by storing a local slug→tag mapping built from the Skills tab data.

**UI placement:** A new card on the Dashboard, or a dedicated "Practice" tab. The card should show:
- Top 3 most overdue topics with a "Solve now" feel
- Each topic: tag name, problems solved count, last seen (relative: "12 days ago" or "Not in recent history")

**Implementation notes:**
- This is purely read-only — no new API calls needed beyond what DashboardViewModel already fetches
- Tag data is already fetched by `SkillsViewModel` via `fetchLanguageStats` / `fetchSkillStats`
- Timestamp cross-reference should be a computed property or a separate `TopicSuggestionService` in `Shared/` if the logic is reusable by widgets later
- No changes to WidgetData needed for v1 of this feature

---

### Priority 2: Unique Problem Tracking (This will be in v4)

**What the user wants:** Track which specific problems the user has solved, so the streak counts unique problems (not re-solves of the same problem daily).

**The constraint:** `recentSubmissionList` returns only 20 items. LeetCode does not expose a full history of all accepted submissions. You cannot retroactively know which of the user's 300+ solved problems were unique.

**The design that works:**
- Persist a local store of accepted problem slugs seen since app install — `Set<String>` serialised to UserDefaults (or a simple JSON file in app support directory)
- On each `DashboardViewModel.load()`, iterate `recentSubmissionList` where `statusDisplay == "Accepted"`, extract `titleSlug`, add to the persistent set
- Expose a `uniqueSolvedCount: Int` (count of the set) and `recentUnique: [String]` (last N unique slugs)
- Update `StreakCard` to show both: "Solved Streak" (existing, any solve per day) and optionally "Unique" count
- Be honest in the UI: "Unique problems tracked since [install date]"

**Data model:**
```swift
// In a new Shared/UniqueProblemsStore.swift
// Reads/writes to UserDefaults.appGroup so widget can access count if needed
struct UniqueProblemsStore {
    static func add(slugs: [String])
    static func count() -> Int
    static func contains(slug: String) -> Bool
    static func installDate() -> Date  // first write date
}
```

**What NOT to do:** Do not change `StreakCalculator` or `anysolveStreak`. The existing streak is "any solve per day" which is correct. Unique tracking is additive, not a replacement.

---

### Priority 3: App Store Submission Prep (this is in v4)

These are non-negotiable for App Store submission: (Mr. Opus, again use your judgement, do not listen to Sonnet below blindly)

**1. Privacy Policy**
Apple requires a privacy policy URL. Create a simple `privacy-policy.md` in the repo (or a GitHub Gist). Content:
- LeetCode username stored locally on device
- Session credentials stored in iOS Keychain, never transmitted to any third party
- No analytics, no tracking, no data sold
- App contacts leetcode.com and assets.leetcode.com solely for app functionality

**2. App Store metadata (not code — just content to prepare):**
- App name: "LeetCodeLytics" (check if taken on App Store)
- Subtitle (30 chars): "Streaks, Stats & Habit Tracker"
- Description: focus on habit building, streak widgets, topic insights
- Keywords: leetcode, coding streak, dsa tracker, widget, algorithm practice
- Screenshots: 5 × iPhone 6.7" minimum (can generate from Simulator)
- Category: Productivity or Education

**3. Code quality gates before submission:**
- All 120 tests pass (add tests for Priority 1 and 2 features)
- No crashes on: fresh install (empty cache), no internet, sign-out flow, bad username
- Empty states handled: no submissions, no tags, no badges
- Error states visible and recoverable (pull-to-refresh on all error states)
- Version shown in Settings must match `MARKETING_VERSION` in project.yml

**4. Sign in with Apple:** NOT required. LeetCode login is for data access, not account creation in the app. Apple's requirement only applies when third-party login creates the user's primary app account.

---

## Architecture rules — do not violate these (Mr. Opus, This is just for your reference, you know better than Sonnet so use your own discretion)

These are derived from hard-won lessons in v1.0–v2.34. Every one of these rules has a corresponding incident in BugAudit.md.

**Widget extension:**
- NEVER make network calls in the widget extension. Hard 30MB memory budget. Three GraphQL calls = OOM.
- Widget reads ONLY from App Group UserDefaults (`group.com.leetcodelytics.shared`)
- `getTimeline` must call `completion` synchronously. Async work that crashes before calling completion = grey widget forever.
- All widget types use `containerBackground(for: .widget)` as the sole modifier in the `StaticConfiguration` closure
- Widget background images must be sRGB color space (NOT Display P3, NOT Color LCD). Wrong ICC profile = float32 decode = OOM. Verify: `sips --getProperty profile image.png` must return `sRGB`.

**Credentials:**
- ALL credential reads go through `KeychainService` — never `UserDefaults.appGroup` directly for session/csrf
- `LeetCodeService.buildRequest` constructs Cookie header manually with `httpShouldHandleCookies = false`
- Default credentials are migrated from old UserDefaults keys on first launch (see `LeetCodeLyticsApp.init()`)

**Models:**
- All models must be `Codable` — required for CacheService and App Group sharing
- `UserBadge.id` is a `String` (LeetCode returns `"7588899"`, not `7588899`)
- `RecentSubmission.timestamp` is a `String` (LeetCode returns `"1715000000"`, not an Int)
- `submissionCalendar` requires double-decode: it is a JSON string inside JSON

**ViewModels:**
- All three ViewModels have `activeFetch` guard — prevents task stacking on rapid tab switches
- `DashboardViewModel.load()` uses unstructured `Task {}` + `withCheckedContinuation` to survive `.refreshable` cancellation
- DCC streak must NEVER be reset to 0 on failure — preserve previous value

**Formatters:**
- `DateFormatter`, `Calendar`, `RelativeDateTimeFormatter` must be file-level `private let` constants — NEVER inside view bodies or computed properties. SwiftUI recreates view structs on every parent render. Formatter init costs ~0.5ms each.

**Tests:**
- Every new model → fixture decode test in `ModelDecodeTests`
- Every new service call → test in `LeetCodeServiceExecuteTests`
- Every new ViewModel method → test in the corresponding ViewModel test file
- Every bug fix → regression test named for the bug
- Run the full suite before every commit: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme LeetCodeLyticsTests -destination 'platform=iOS Simulator,name=iPhone 16' test 2>&1 | grep -E '(error:|passed|failed|BUILD)'`

**Versioning:**
- Bump `MARKETING_VERSION` in `project.yml` on EVERY commit that changes source code — both targets together
- MINOR (x.Y.0) for new features. PATCH (x.y.Z) for genuine one-line bug fixes only.
- After any `project.yml` change: run `xcodegen generate`

---

## LeetCode GraphQL API — verified queries

**Endpoint:** `POST https://leetcode.com/graphql`

**Required headers:**
```
Content-Type: application/json
Referer: https://leetcode.com
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) ...
```

**Queries in use (do not change without testing):**

```graphql
# User profile (public, no auth needed)
query getUserProfile($username: String!) {
  matchedUser(username: $username) {
    username
    profile { ranking userAvatar realName }
    submitStats: submitStatsGlobal {
      acSubmissionNum { difficulty count submissions }
      totalSubmissionNum { difficulty count submissions }
    }
    badges { id name icon creationDate }
  }
}

# Submission calendar (public)
query userProfileCalendar($username: String!, $year: Int) {
  matchedUser(username: $username) {
    userCalendar(year: $year) {
      streak totalActiveDays submissionCalendar
    }
  }
}

# DCC streak (requires LEETCODE_SESSION)
query getStreakCounter {
  streakCounter { streakCount currentDayCompleted }
}

# Recent submissions (public)
query recentSubmissions($username: String!, $limit: Int) {
  recentSubmissionList(username: $username, limit: $limit) {
    title titleSlug timestamp statusDisplay lang
  }
}

# Skill stats (public)
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

**API response quirks that have caused bugs:**
- `badges[].id` is a String, not Int
- `recentSubmissionList[].timestamp` is a String, not Int
- `submissionCalendar` is a JSON string inside JSON — requires double-decode
- `streakCounter` returns null if unauthenticated — handle gracefully
- `allQuestionsCount` is a sibling of `matchedUser` at GraphQL root — cannot be combined in one execute call

---

## File structure (as of v2.34.0)

```
LeetCodeLytics/
  project.yml                         ← XcodeGen spec
  LeetCodeLytics/
    App/
      LeetCodeLyticsApp.swift         ← BGTask registration, credential migration
      ContentView.swift               ← Tab bar
      AppGroup.swift                  ← UserDefaults.appGroup extension
    Models/
      UserProfile.swift
      StreakData.swift
      RecentSubmission.swift
      LanguageStats.swift
    Services/
      LeetCodeService.swift           ← All GraphQL calls; httpShouldHandleCookies=false
      LeetCodeServiceProtocol.swift
      CacheService.swift
      KeychainService.swift
    ViewModels/
      DashboardViewModel.swift        ← Writes WidgetData to App Group
      SubmissionsViewModel.swift
      SkillsViewModel.swift
    Views/
      Dashboard/DashboardView.swift
      Dashboard/ProfileHeaderView.swift
      Dashboard/StreakCard.swift
      Dashboard/ProblemStatsCard.swift
      Dashboard/AcceptanceRateView.swift
      Calendar/HeatmapGridView.swift
      Submissions/SubmissionsView.swift
      Skills/SkillsView.swift
      Settings/SettingsView.swift
      Login/LeetCodeLoginView.swift
      Onboarding/UsernameInputView.swift
  LeetCodeLyticsWidget/
    Provider.swift                    ← Timeline: [now, 06:00, 12:00, 18:00, 00:00] + policy midnight+5
    LeetCodeLyticsWidget.swift        ← WidgetBundle; 4 widget types
    WidgetViews.swift                 ← View implementations
    WidgetBackground.swift            ← widgetBackgroundName(); live streak recompute
  Shared/                             ← Compiled into BOTH app and widget targets
    WidgetData.swift                  ← Codable; didSolveToday() free function
    SubmissionCalendar.swift          ← Double-decode helper; init(dailyCounts:) added
    StreakCalculator.swift            ← UTC streak from timestamps
    ColorExtension.swift
    SharedAssets.xcassets/
  LeetCodeLyticsTests/
    (120 tests — all passing)
  PersonalNotes/
    OpusBrief.md                      ← this file
    PersonalNotes.md                  ← user notes and testing feedback
    BugAudit.md                       ← incident history
```

---

## What good execution looks like

1. **Design before code.** For each priority feature, write out the data flow (API → service → model → cache → view → widget if applicable) and get Srinivas to approve it before implementation.

2. **One feature at a time.** Complete Priority 0, test it on device, commit. Then Priority 1. Then App Store prep. Do not interleave.

3. **Tests alongside code.** Not after. For every new service method: fixture test. For every new ViewModel method: state transition test. (Honestly it should be Tests BEFORE code for true TDD)

4. **No regressions.** The 120 existing tests must continue to pass throughout. Run them before every commit.

5. **Honest UI.** Where API limitations constrain accuracy (topic suggestions based on last 20 submissions, unique tracking since install), reflect this clearly in the UI with a subtitle or info tooltip. Do not overclaim.

6. **Build system.** After any `project.yml` change: `xcodegen generate`. Always use `LeetCodeLytics` scheme, never the widget scheme.


Dev note: Mr. Opus, please build this. you are expert ios developer with experience in publishing different ios apps recently. So you are well versed with the dos and don'ts.