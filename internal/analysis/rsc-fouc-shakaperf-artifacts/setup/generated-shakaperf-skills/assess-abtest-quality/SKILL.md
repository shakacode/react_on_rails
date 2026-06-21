---
name: assess-abtest-quality
description: Audit existing .abtest.ts files plus the latest `shaka-perf audit` results for anti-patterns, false-positive PASSes (blank/high-whitespace screenshots), and coverage gaps. Use whenever the user wants to review, audit, improve, or "assess quality" of AB tests — phrasings like "are my visreg tests any good?", "check the ab tests", "why is this test passing?", or "make these tests more reliable".
argument-hint: '[testFile-or-glob] [--no-run]'
---

# assess-abtest-quality

Canonical list of test code rules. Both `discover-abtests` (when writing new tests) and this skill (when grading existing tests) read from this file.

A visreg test exists to **fail loudly** when the UI changes. Control flow that hides "the element wasn't there" or "the action didn't happen" defeats the whole point — a green test that silently did nothing is worse than no test. So:

1. **No error swallowing.** Never wrap an action in `try/catch` to keep going, and never `.catch(() => {})` a promise. A failed click, fill, or wait _is_ the finding — let it throw so the report shows "Failed while \<annotation\>". "It might not be there" is a reason to assert it (rule 3), not to guard it.

2. **No loops.** No `for` / `while` / `forEach` / `for await` in a test body. Steps stay explicit and linear, so a failure points at one action and the run is reproducible.
   - Don't loop to "click through" N items — that's N separate tests, or one snapshot of the container. Split it.
   - Never write a `while (!atBottom)` scroll loop — it hangs in this harness (`window.scrollY` doesn't update in the Playwright context). Use `scrollIntoViewIfNeeded()` on a known bottom element (see the lazy-load pattern in `discover-abtests/references/patterns.md`).

3. **No `if` — assert the expectation instead.** Don't branch on page state (`if (await locator.isVisible())`, `if (await locator.count())`, `if (el) …`). A branch means the test quietly takes the "do nothing" path _exactly when_ the thing you're testing has regressed. State what you expect and let Playwright's auto-waiting throw when it's wrong — these are your assertions:
   - `await page.waitForSelector(sel, { state: 'visible' })` — the element must appear.
   - `await page.waitForURL('**/path')` — navigation must happen.
   - Need different behaviour per viewport? Don't branch on `viewport.label` — write a separate `abTest` scoped to that viewport via `viewports` (see "Viewport-conditional selectors" in `patterns.md`). Each test stays linear.

4. **Wait for conditions, not the clock.** Use `waitUntilPageSettled(page)` and `waitForSelector(sel, { state })` to wait. `page.waitForTimeout(ms)` is a guess — flaky when short, slow when long. A short fixed delay (≤500ms) is acceptable _only_ to let a confirmed animation/transition finish where there's no event to wait on, never to "hope" content loads.

5. **Prefer user-facing locators.** `getByRole`, `getByLabel`, `getByText` express intent and survive refactors better than brittle CSS/XPath; fall back to a stable selector (`[data-cy=…]`, a semantic class) when there's no accessible handle. (Section _captures_ still use CSS selectors — see Selectors strategy in `patterns.md`.)

6. **Deterministic inputs _and_ content.** Fill fixed values — a fixed date, name, count — never `Date.now()`, randomness, or "today". When the _page itself_ renders nondeterministic content (timestamps, "2 minutes ago", live counters, randomized ordering, today's date, ads), **alter the page to force it deterministic** rather than raising `misMatchThreshold` to hide it — a raised threshold isn't determinism, it just blinds the test to real diffs. In order of preference:
   - **Freeze it at the source** in `onBefore`, before the page loads, so it renders identically every run and on both sides:
     ```typescript
     onBefore: async ({ page }) => {
       await page.addInitScript(() => {
         const FIXED = new Date('2026-01-01T00:00:00Z').getTime();
         Date.now = () => FIXED;            // also stub the Date constructor if the app uses `new Date()`
         Math.random = () => 0.42;          // pin shuffles / randomized order
       });
     },
     ```
   - **Overwrite the rendered text** in `testFn` before capture (it runs before the screenshot). Annotate it, and don't guard it — if the element is gone, let it throw:
     ```typescript
     annotate('pinning the relative timestamp');
     await page.locator('.posted-at').evaluate((el) => {
       el.textContent = 'Jan 1, 2026';
     });
     ```
   - **Drop it from the capture** with `removeSelectors` / `hideSelectors` when the dynamic element isn't what this test is about (e.g. an ad slot inside a section you're snapshotting).
   - **Stub images** with `interceptImages(page)` (call before `page.goto`) and freeze animations/background images with `overrideCSS(page)`.

7. **Each test stands alone.** It starts from its `startingPath` and assumes nothing from any other test — no shared state, no ordering. One behaviour (one section, one interaction) per `abTest`, so a failure pinpoints what broke.

And keep annotating: an `annotate(...)` immediately before each non-trivial step is what turns a thrown assertion into a readable "Failed while \<doing X\>".
