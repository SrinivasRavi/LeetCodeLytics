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
