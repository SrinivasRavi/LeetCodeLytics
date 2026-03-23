# Bug Audit — LeetCodeLytics v1.x

A honest retrospective of bugs that were introduced by Claude, how long they persisted, and what went wrong on my end.

---

## Bug 1: `UserBadge.id` declared as `Int?` instead of `String`

**Versions affected:** v1.0 → v1.5.1 (persisted across 7+ versions)

**Symptom:** "Refresh failed: Failed to decode response. The data couldn't be read because it isn't in the correct format." on every Dashboard pull-to-refresh. Dashboard would never load fresh data — only cached data was ever shown.

**Fix (v1.5.2):** Changed `id: Int?` to `id: String?` in `UserBadge`. One line.

**What went wrong:**
I wrote the `UserBadge` model assuming `id` was a numeric integer (`7588899`) without verifying the actual API response shape. LeetCode returns it as a JSON string (`"7588899"`). JSONDecoder strictly fails when a string is found where an Int is expected. I did not run even a single curl test against the actual API before writing the models. This is inexcusable — I should have verified every model field against real API responses before writing a single line of Swift.

---

## Bug 2: `execute<T>` using overly strict `JSONDecoder` strategy

**Versions affected:** v1.0 → v1.5.0 (persisted across 6+ versions, masked Bug 1)

**Symptom:** Any unexpected field, `errors` array, or null in LeetCode's response caused the entire decode to fail. This made it impossible to distinguish between a model mismatch and a network issue — both produced the same generic error.

**Fix (v1.5.1):** Replaced `JSONDecoder().decode([String: [String: T]].self, from: data)` with a two-step approach: `JSONSerialization` to navigate to `data[responseKey]`, then `JSONDecoder` to decode just that value.

**What went wrong:**
The original `execute<T>` tried to decode the ENTIRE GraphQL response as a rigid nested generic. This fails the moment LeetCode adds an `errors` array, a null field, or any extra key — all of which are normal in GraphQL. A robust GraphQL client always navigates to the specific key it needs before decoding. I did not design for this from the start, and I did not test against a real LeetCode response before shipping v1.0.

---

## Bug 3: Contest tab model mismatch

**Versions affected:** v1.0 → v1.2 (resolved by removing the feature, not fixing it)

**Symptom:** Contest tab showed "Failed to decode response" immediately on load.

**Fix:** Removed the Contest tab entirely at the user's request. The underlying model was never corrected.

**What went wrong:**
Same root cause as Bug 1 — I wrote `ContestRanking` and related models without verifying them against actual API responses. The model didn't match what LeetCode returned. Rather than fixing the model properly, the tab was dropped. This was acceptable given the user didn't need it, but the root failure was the same: no API validation before writing models.

---

## Bug 4: Dashboard pull-to-refresh — wrong fix on first attempt (v1.5.4)

**Versions affected:** v1.5.3 → v1.5.4 (wrong fix lasted 1 version)

**Symptom:** Pull-to-refresh showed "Refresh failed: cancelled" banner and DCC streak reset to 0. Data was not actually refreshing.

**First (wrong) fix (v1.5.4):** Suppressed the error banner for `URLError.cancelled` and stopped resetting DCC to 0 on failure. The banner disappeared but the data still wasn't refreshing. User correctly called this out: "you just removed the banner. Functionally v1.5.3 and v1.5.4 are the same."

**Actual fix (v1.5.5):** Moved network calls into an unstructured `Task {}` inside `withCheckedContinuation`. Since it's unstructured, it can't be cancelled by SwiftUI's refreshable task. The continuation keeps `load()` suspended — and the spinner alive — until data actually arrives.

**What went wrong:**
I treated the symptom (error banner) instead of the cause (task cancellation). The real problem was that SwiftUI's `.refreshable` creates a structured task, and `async let` creates child tasks of it — so when SwiftUI cancels the refreshable task (which it does under various scroll/view-lifecycle conditions), all child network tasks get cancelled too. I knew this was the likely root cause from the first diagnosis but applied a cosmetic fix instead of the structural one. This was a lapse in discipline — I should have fixed the actual architecture in v1.5.4 instead of suppressing the visible symptom.

---

## Bug 5: DCC streak unconditionally reset to 0 on any failure

**Versions affected:** v1.0 → v1.5.4

**Symptom:** Any failure in the DCC fetch (network error, cancellation, missing auth) would wipe out the previously displayed DCC value and show 0.

**Fix (v1.5.4 partial, v1.5.5 complete):** Removed the `dccStreak = 0` in the catch block. Once pull-to-refresh was actually fixed in v1.5.5, DCC fetched correctly and the preserve-on-failure behaviour became meaningful.

**What went wrong:**
Defensive default value in a catch block — `dccStreak = 0` — that felt safe but was destructive. If a cached value is visible, a failed refresh should not erase it. This should have been "preserve on failure" from day one.

---

## Systemic Failures (patterns across all bugs)

1. **No API validation before writing models.** Every model mismatch (Bugs 1, 2, 3) would have been caught immediately by running one curl command per endpoint before writing any Swift. I did not do this.

2. **Treating symptoms instead of causes.** Bug 4's v1.5.4 fix is the clearest example — the banner was the symptom, task cancellation was the cause. A correct diagnosis requires understanding the runtime behaviour, not just making the visible error go away.

3. **No incremental integration testing.** The bugs persisted across many versions because each version added features without verifying that existing features worked against the real API. A single end-to-end test after v1.0 (even a curl test) would have caught Bugs 1, 2, and 3 immediately.

4. **Overconfidence in model correctness.** I wrote models from the GraphQL schema documentation without cross-referencing actual live responses. Documentation and reality diverge — the `id` field being a string is a perfect example.

---

## Widget Extension OOM — Persistent Across Versions

An out-of-memory (OOM) crash in the widget extension (`com.apple.product-type.app-extension`) was first reported in v2.0/v2.2 and remained unresolved through at least v2.17 across three distinct attempted fixes. This section documents the full timeline.

**Device context (all crashes):**
- Device: iPhone14,2 (iPhone 13 Pro — 3x display scale)
- OS: iOS 26.3
- Product type: `com.apple.product-type.app-extension` (widget extension, not main app)
- Pattern: crashes occur several minutes into runtime, not at startup — suggesting memory accumulation over multiple re-renders rather than a single allocation spike

---

### v2.0 / v2.2 — First OOM Report

**`operation_duration_ms`:** 495,908 (~8.3 minutes)

**Believed root cause at the time:** `WidgetFetcher` made 3 concurrent network calls directly inside `getTimeline()` in the widget extension process. Network fetches in a widget extension are expensive and keep memory elevated for the duration of each URL session task. With multiple concurrent fetches plus response buffering, this pushed the extension past the ~30MB widget memory budget.

**Fix applied:** Removed all network fetching from the widget extension entirely (landed in v2.10). The extension was changed to read data exclusively from App Group `UserDefaults` — data written by the main app. No network calls in the extension process.

**Did this resolve OOM?** No. OOM was reported again in v2.15 and v2.17 after the network calls were gone.

---

### v2.15 — Second OOM Report

**`operation_duration_ms`:** 1,207,022 (~20.1 minutes)

**Believed root cause at the time:** The background image `astroWidget1.png` (original size: 1750×1702px) was being loaded at full resolution inside the widget extension. At 4 bytes per pixel, that image decoded to approximately 12MB. With 4 widget sizes each potentially rendering the image, the cumulative decoded memory could reach ~48MB — well above the ~30MB extension budget. The v2.10 network removal had eliminated one source of memory pressure, but the oversized image was a separate, larger problem.

**Fix applied (v2.15):** Created proper 1x/2x/3x asset catalog variants. The 3x variant was sized at 1000×972px (~4MB decoded). Expected total for 4 widget renders on a 3x device: approximately 15.6MB — within budget.

**Did this resolve OOM?** No. OOM was reported again in v2.17 with a shorter crash time, indicating memory pressure was still present even after the image scaling fix.

---

### v2.17 — Third OOM Report

**`operation_duration_ms`:** 569,024 (~9.5 minutes)

**Context:** Both previous fixes were in place — no network calls in the extension, correctly sized image asset variants.

**Believed root cause at the time:** `WidgetHeatmapView.dailyCounts` was a computed property. It was called once per heatmap cell during `body` evaluation. With 175 cells in the heatmap grid, each `body` pass rebuilt `dailyCounts` 175 times — filtering and transforming the full submission calendar each time. Over many re-renders (timeline refreshes, system re-evaluations), this accumulated significant transient allocation.

**Fix applied (v2.17):** Converted `dailyCounts` from a computed property to a stored `let` initialized once in `WidgetHeatmapView.init()`. This reduces the work per `body` evaluation from O(175 × calendar_size) to O(1).

**Did this resolve OOM?** No. The user confirmed OOM still occurred after deploying v2.17.

---

### Current Status (as of v2.17)

**OOM is unresolved.** Three fixes have been applied across three versions, each addressing a real problem, and none has stopped the crashes. The extension is accumulating memory during normal operation on a real device and eventually being killed by the OS.

---

### Known Facts

- All OOM crashes are `com.apple.product-type.app-extension` — the widget extension process, not the main app
- All crashes occur on the same device: iPhone14,2 (3x scale), iOS 26.3
- `operation_duration_ms` values: 495,908ms → 1,207,022ms → 569,024ms. The variation in crash time across versions suggests the dominant memory source changes with each fix, but a baseline leak or re-render accumulation remains in every version
- No crash occurs at launch — the extension runs for minutes before dying. This rules out a single large allocation at startup and points to incremental memory growth: either a leak (objects accumulating without release) or repeated re-renders each allocating memory that is freed slowly or not at all
- Widget extensions on iOS are subject to a strict memory cap (~30MB). Exceeding this cap causes an immediate SIGKILL — there is no warning, no graceful shutdown

---

### Hypotheses for Remaining Root Cause (Not Yet Fixed)

The following are suspects that have not been addressed as of v2.17. Each is a potential contributor to memory accumulation across repeated `body` evaluations or timeline refreshes.

1. **`weekDates` computed property in `WidgetHeatmapView`.**
   `weekDates` is a computed property called from `body`. It performs date arithmetic and constructs an array of 175 `Date` objects (52 weeks × up to 7 days per week). If SwiftUI re-evaluates `body` multiple times per timeline entry — which it does on widget re-render, size changes, and dark/light mode transitions — this array is allocated and discarded on each pass. Each allocation is small, but if autorelease pools drain slowly inside the extension's non-main-thread render context, these could accumulate. Fix: convert to a stored `let` in `init`, same as was done for `dailyCounts`.

2. **`monthLabels(from:)` called from `body`.**
   `monthLabels(from:)` is a method called during `body` evaluation that iterates over the weeks array and builds a dictionary or array of month label positions. Like `weekDates`, this is repeated work on every render pass. It should be computed once and stored.

3. **SwiftUI re-rendering the widget multiple times per timeline refresh.**
   WidgetKit can invoke the `TimelineProvider` and re-render views more frequently than the configured refresh interval — for example, when the system updates widget relevance scores, when the user's device rotates, or when the lock screen / home screen layout changes. Each re-render that triggers a new `body` evaluation compounds any per-render allocation. If views are not properly value-typed (i.e., they capture reference-type objects), each render could retain additional memory.

4. **`widgetDimOpacity()` creating `UserDefaults(suiteName:)` on every call.**
   If `widgetDimOpacity()` (or any function called from `body`) constructs a new `UserDefaults` instance with a suite name on every invocation, this creates a small but non-trivial object on each render. `UserDefaults` instances with custom suite names are not free — they hold references to shared file-backed storage coordinators. The correct pattern is a file-level or `init`-time stored constant. This is a minor contributor individually but adds up across many renders.

5. **No memory profiling has been performed on the widget extension process.**
   All hypotheses above are derived from static code analysis. The actual dominant allocation has not been confirmed with Instruments (Allocations or Leaks template targeting the widget extension). Without a memory profile, it is possible that the true source is something entirely different — for example, `Image("astroWidget1")` being re-decoded from disk on every render if the asset catalog cache is evicted under pressure, or a SwiftUI internal retain cycle in the view graph.

---

### What a Fix Attempt Should Look Like

Before the next version ships with another speculative fix:

1. Profile the extension with Instruments → Allocations, attached to the widget extension process (not the main app). Identify the top allocation sites across multiple timeline refreshes.
2. Convert all computed properties called from `body` in `WidgetHeatmapView` to stored properties initialized in `init`: `weekDates`, `monthLabels`, and any other derived collections.
3. Audit every function called from any widget view `body` for object allocations. Move them to `init` or file-level constants.
4. Verify the image asset is being loaded from the asset catalog cache and not decoded from disk on every render (add a log or breakpoint in the image load path).
5. After each change, deploy and allow the widget to run for at least 30 minutes before declaring the fix successful — the v2.17 crash occurred at ~9.5 minutes and the v2.15 crash at ~20 minutes.

---

## v2.31.0 OOM + AstroWidget_Broken Not Showing

**Date:** 2026-03-20
**Version:** v2.31.0 — first version with dynamic widget backgrounds (AstroWidget_Success / Rocket1–4 / Broken)

---

### Bug A: OOM returns at exactly 30MB

**Symptom:** Widget extension killed immediately with `EXC_RESOURCE (RESOURCE_TYPE_MEMORY: high watermark memory limit exceeded) (limit=30 MB)`.

**Crash stack from screenshot:**
```
Thread 1: EXC_RESOURCE (RESOURCE_TYPE_MEMORY: high watermark memory limit exceeded) (limit=30 MB)
  Frame 0: vConvert_PlanarFtoPlanar16F_vec  ← vImage float32→float16 pixel conversion
  Frame 1: ConvertFloatToHalf               ← same pipeline
```
Both frames are inside `vImage`, specifically the wide color compositing path that converts float32 pixel planes to float16 for the GPU. This is **not** a code logic bug — it is a memory cost of decoding and compositing PNG images that carry a wide color ICC profile.

**Root cause (confirmed):**

All six new PNG images were saved from a Mac with an embedded `Color LCD` ICC profile. "Color LCD" is Apple's display ICC profile — a wide color space (effectively Display P3-like). When iOS encounters an image with a non-sRGB ICC profile, it decodes the entire image through the wide color rendering pipeline which uses float32 internally (4 channels × 4 bytes = **16 bytes per pixel**) rather than the standard sRGB 8-bit path (4 bytes per pixel).

Measured with `sips --getProperty profile` and `--getProperty pixelWidth/pixelHeight` on every embedded `@3x` file:

| Image | Dimensions | float32 per render | sRGB per render |
|-------|------------|-------------------|-----------------|
| AstroWidget_Success | 1000×972 | 14.83 MB | 3.70 MB |
| AstroWidget_Broken | 1000×986 | 15.04 MB | 3.76 MB |
| AstroWidget_Rocket1 | 1000×987 | 15.06 MB | 3.76 MB |
| AstroWidget_Rocket2 | 1000×989 | 15.09 MB | 3.77 MB |
| AstroWidget_Rocket3 | 1000×991 | 15.12 MB | 3.78 MB |
| AstroWidget_Rocket4 | 1000×997 | 15.21 MB | 3.80 MB |

The widget extension renders all 4 widget sizes (SmallSolved, SmallDCC, Medium, Large) simultaneously in the same process. All 4 call `widgetBackgroundName` which returns the same image name. At float32: **4 renders × ~15MB = ~60MB >> 30MB limit**. Even a single render (~15MB) plus the extension's own baseline memory (~5–10MB) puts the process right at or over the limit.

In the previous v2.15 fix, the original `astroWidget1.png` was also scaled to 1000×972px, and the OOM was considered resolved. The difference: that image was in **sRGB** (4 bytes/pixel), giving ~3.7MB per render and ~15MB total — within budget. The new images are in a wide color space, giving ~15MB per render and ~60MB total.

**The pixel dimension is the same. The color profile is what changed.**

**Fix:** Strip the ICC profile from all 6 images and convert them to sRGB before embedding in the asset catalog. Using `sips`:
```bash
sips --matchTo "/System/Library/ColorSync/Profiles/sRGB Profile.icc" image.png
```
Or equivalently:
```bash
sips --setProperty space sRGB image.png
```
This converts the embedded color data to sRGB and removes the wide color profile, forcing iOS to use the 4 bytes/pixel decode path. At sRGB: 4 renders × ~3.7MB = ~14.8MB — safely within the 30MB budget.

**What I missed:**
When I ran `sips --getProperty space` on the source images, I saw `space: RGB` and treated it as confirmation the images were fine. `RGB` only means the colorant model (red/green/blue). It does not tell you whether the profile is standard sRGB or a wide gamut variant. The `profile` field (`Color LCD`) is what matters. I checked `space` but not `profile`. I should have checked the embedded ICC profile name on every image before embedding them.

The v2.15 fix for the original `astroWidget1.png` worked because that image happened to be in sRGB. I assumed the new images would be in the same color space without verifying. This is the same class of error as "no API validation before writing models" — assuming conformance without checking.

---

### Bug B: AstroWidget_Broken never displayed despite broken streak

**Symptom:** Widget shows `AstroWidget_Success` even when `anysolveStreak == 0`.

**Root cause:** This is a direct consequence of Bug A (OOM). When the widget extension crashes mid-render, iOS discards the crashed render and displays the **last successfully cached render frame** from disk. The last successful render was from before v2.31.0 was deployed — at that point, all widgets used `AstroWidget1` (now renamed `AstroWidget_Success`). The extension has been crashing on every render attempt since v2.31.0 deployed, so the cached Success frame is all iOS can show. The `widgetBackgroundName` logic returning `"AstroWidget_Broken"` is correct, but that render never completes due to OOM.

**Evidence for this:** The same OOM crash was present in v2.14 for the small/medium widgets (not large). In that case, the large widget showed the background image correctly (its render completed before OOM killed the process), while the small/medium widgets showed the old placeholder. Identical failure mode.

**Secondary consideration (after OOM is fixed):** Even with OOM resolved, the widget will only show `AstroWidget_Broken` once the App Group WidgetData is updated to reflect `anysolveStreak == 0`. If the user has not opened the Dashboard tab and the background refresh has not fired, the widget reads stale WidgetData with the old streak value. In this stale-data scenario, `widgetBackgroundName` would return `AstroWidget_Rocket{N}` (streak intact, not solved), not Success. If Success is showing despite a broken streak from stale data, it means `didSolveToday` is returning true — which would be a separate data staleness issue (calendar still shows a solve from a previous UTC day). This is normal behavior — the widget can only be as current as the last App Group write.

**Console message observed in screenshot:**
```
Couldn't read values in CFPrefsListSource (Domain: group.com.leetcodelytics.shared,
User: kCFPreferencesAnyUser, ByHost: Yes, Container: (null), Contents Need Refresh: Yes):
Using kCFPreferencesAnyUser with a container is only allowed for System Containers,
detaching from cfprefsd
```
This is a known iOS diagnostic log for App Group `UserDefaults` in extensions. The `kCFPreferencesAnyUser` with `ByHost: Yes` mode is rejected by `cfprefsd` in sandboxed extension contexts, but the system falls back to direct file-based access and the read typically succeeds. This log does not indicate that the App Group read fails — it is spurious and precedes the actual OOM kill. It is not a contributing factor to Bug B.

**Fix:** Fix Bug A (strip ICC profiles → resolve OOM). Bug B resolves automatically once renders complete. No logic changes needed to `widgetBackgroundName` or `didSolveToday`.

---

### What I Should Have Done

1. **Checked the embedded ICC profile of every source image before embedding.** `sips --getProperty profile` on each file takes seconds and would have caught "Color LCD" immediately.

2. **Computed float32 memory costs as part of the review**, not just the sRGB baseline. Any image with a non-sRGB ICC profile decodes at 4× the naive memory estimate. The CLAUDE.md pixel dimension limits (3x ≤ 1000px) were derived for sRGB images. They need an explicit note that the images must also be in sRGB, not just correctly sized.

3. **The CLAUDE.md OOM rules are incomplete.** They say "3x ≤ 1000px max dimension". They should say "3x ≤ 1000px AND images must be embedded in sRGB color space — any other ICC profile (Display P3, Color LCD, etc.) causes iOS to decode at float32 (16 bytes/px instead of 4), invalidating the memory budget calculation entirely."
