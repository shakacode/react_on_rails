---
name: discover-abtests
description: Crawl a website and auto-generate .abtest.ts files for shaka-perf visreg visual regression testing. Use this skill whenever the user wants to discover, generate, or scaffold AB tests for a URL — even if they just say "set up tests for localhost:3020", "generate tests for this site", or "create visreg tests".
argument-hint: <url> [depth=2] [output=./ab-tests/] [mode=twin-server|single-server]
---

# discover-abtests

Crawl a target site in Chrome, probe pages interactively to understand their behavior, then generate validated `.abtest.ts` files for `shaka-perf visreg`.

The goal is to produce tests that _actually work_ — not just syntactically valid files. That's why each page is probed in the browser before writing any code: it avoids generating tests for interactions that don't exist, CSS overrides that don't work, or skeleton waits for elements that never appear.

## Bundled resources

The browser-side scripts and report parser ship inside the `shaka-perf` CLI — invoke them via `shaka-perf discover-abtests <subcommand>` rather than reading files from this directory.

| Command                                           | When to use                                                                                                                                   |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `shaka-perf discover-abtests extract-links`       | Prints JS source — capture stdout and pass to `javascript_tool` to collect internal links from any page                                       |
| `shaka-perf discover-abtests probe-lazy-load`     | Prints JS source — capture stdout and pass to `javascript_tool` to test whether scrolling triggers new content                                |
| `shaka-perf discover-abtests probe-sections`      | Prints JS source — capture stdout and pass to `javascript_tool` on tall pages (>2000px) to score candidate CSS selectors                      |
| `shaka-perf discover-abtests parse-report [path]` | Run after `compare` to summarize pass/fail, diff %, whitespace metrics, and engine errors (defaults to `visreg_data/html_report/report.json`) |
| `references/patterns.md`                          | Read when writing `.abtest.ts` files — contains code patterns and selector strategy                                                           |
| `references/api.md`                               | Read when you need the full `abTest()` config API or helpers reference                                                                        |

Read the reference docs as needed rather than trying to keep the full details in mind. The patterns and API reference are too detailed to hold mentally — just load them.

## Inputs

Parse from the user's message:

- **URL** — required (normalize bare domains like `printivity.com` → `http://printivity.com`)
- **depth** — default `2`. Depth 1 = starting page only; depth 2 = starting page + linked pages; depth 3 = one more level out
- **output directory** — default `./ab-tests/`
- **concurrency** — default `4`. Number of browser tabs for parallel link extraction in Phase 1.
- **mode** — default `twin-server`. Controls how tests run:
  - `twin-server` — compares control (e.g. `localhost:3020`) vs experiment (e.g. `localhost:3030`)
  - `single-server` — both `--controlURL` and `--experimentURL` set to the same URL; validates test structure without a real A/B pair

If no URL was provided, ask for it before proceeding.

---

## Phase 1: Crawl (links only)

Load `mcp__claude-in-chrome__tabs_context_mcp` first to get a tab, then navigate to the URL.

This phase ONLY extracts links — no probing, no testing. The goal is to build a list of pages to process.

Maintain throughout:

- `visited`: set of paths already link-extracted
- `queue`: `[{ path, depth }]`, initialized with `[{ path: '/', depth: 1 }]`
- `pageList`: ordered list of unique paths to process in Phase 2

Process the queue in BFS order, **up to `concurrency` pages in parallel**:

1. Dequeue up to `concurrency` entries not yet visited.
2. Open each in its own tab (`tabs_create_mcp` for tabs 2–N; reuse existing for first).
3. For each: navigate, mark visited, capture `shaka-perf discover-abtests extract-links` and pass its stdout to `javascript_tool`. If `depth < crawlDepth`, enqueue new paths as `{ path, depth: depth + 1 }`.
4. Close extra tabs after each batch.

**Hard limits**: max 40 unique paths.

Skip only these:

- External URLs (different hostname)
- Non-page paths: `tel:`, `mailto:`, anchors-only (`#section`)
- Admin panels (e.g. `/admin` — but go to `/login` normally)
- Auth callbacks (`/auth/callback`, `/oauth`)
- API routes (`/api/`, `.json` endpoints)
- Paginated duplicates (`/products?page=2` when `/products` is already queued)
- Pages that require authentication — check by navigating; if it redirects to login, skip

Do **not** skip pages just because they seem "boring" or static.

---

## Phase 2: Per-page loop

Process pages from `pageList` **one at a time, sequentially**. For each page, complete all five steps (A → B → C → D → E) before moving to the next page.

Maintain across pages:

- `claimedSections`: map of `selector → path` — when a section appears on multiple pages, only the first page to claim it gets a test for it
- `knownLoadingSelectors`: set of CSS selectors for spinners/skeletons/loading indicators discovered on any page so far. Grows as new ones are found.

### Step A — Probe the page

Navigate to the page in Chrome. Complete all probing steps _in sequence_ before writing any code.

**A1. Check for lazy-loaded content** (always, every page):
Capture `shaka-perf discover-abtests probe-lazy-load` and pass its stdout to `javascript_tool`. Wait for `networkidle` first — probing during an in-flight API call gives false results. Then scroll incrementally using **real mouse scroll actions** (not `window.scrollTo` in JS) — IntersectionObserver-based lazy loaders only fire on genuine scroll events. Scroll 10 ticks at a time via `mcp__claude-in-chrome__scroll`, wait 500ms between each, until `window.scrollY + window.innerHeight >= document.body.scrollHeight`. Wait 2 more seconds, compare image count and scroll height to baseline. Record the result.

**A2. Wait for loading indicators to clear** (always, every page):
Check for spinners, skeleton screens, loading indicators. Use `javascript_tool` to look for: `aria-label="Loading"`, `role="progressbar"`, class names containing `skeleton`, `spinner`, `loading`, `placeholder`. Add any found to `knownLoadingSelectors` and wait for them to disappear. Also check all selectors already in `knownLoadingSelectors`. Do not proceed until all loading indicators are gone.

**A3. CSS animation overrides** (if you see moving elements): inject via `javascript_tool` and screenshot to confirm it stopped. Only include in tests if the screenshot shows the element frozen.

**A4. Page sections**: run `document.body.scrollHeight` (after real scrolling in A1). If >~2000px, use both strategies to find the best CSS selectors for section-based testing:

**Strategy 1 — Algorithmic probe**: Capture `shaka-perf discover-abtests probe-sections` and pass its stdout to `javascript_tool`. It walks the DOM from the layout root, scores elements by size (100-800px = best), width, depth, semantic class name, heading inclusion, content density, and uniqueness. Returns up to 15 scored candidates with overlap removed. Elements >1000px tall are deprioritized so their children get picked instead.

**Strategy 2 — AI visual analysis**: Scroll through the page and identify the **natural visual sections** a user would recognize — hero, content blocks, sidebars, forms, navigation, footer. For each, find the closest DOM element that wraps it. Evaluate: "If I capture just this element, will the screenshot show a recognizable, self-contained piece of UI?"

**Merge and evaluate** candidates from both strategies:

- **Default: include.** Every scored candidate should get a test. Only skip a section if it is **structurally empty** — meaning 0 children, 0 textContent, and 0 images (e.g., an empty `<div>` placeholder with no iframe or canvas). Sections showing "empty state" UI (like "Reviews (0)" with a button) are real UI and should be tested.
- A good section passes the **"would a designer draw a box here?"** test — it's a natural visual block
- A good section **includes its heading** — if an `<h2>` sits above the candidate, try the parent instead
- A good section **"tells a story"** — the screenshot makes sense on its own ("Amenities: WiFi, Pool" tells a story; a blank rectangle does not)
- If an element has near-zero textContent but children have content, it's a **wrapper** — go one level deeper
- Aim for sections covering 70%+ of page height — use as many sections as needed
- For sidebar elements (position:absolute/sticky, widthRatio < 0.5), plan desktop-only tests
- For elements hidden on some viewports, add `viewports` override

**A5–A7 are not optional.** Interaction tests (clicking buttons, filling forms, opening modals) are just as important as section snapshots — they catch regressions in dynamic behavior that static screenshots miss. A page with 5 section snapshots and 0 interaction tests has a coverage gap.

**A5. Catalog interactive elements**: use `javascript_tool` to find all clickable/interactive elements on the page. Query for `button`, `a[href]` (non-navigation), `input`, `select`, `textarea`, `[role="tab"]`, `[aria-expanded]`, `[data-toggle]`, `.btn`, etc. Record each with its selector, visible text, and location on the page.

**A6. Test interactions**: click each interactive element in Chrome and document what happens:

- Button opens a modal or drawer? → record the modal's content and selectors
- Checkbox changes visible state? → record
- Button scrolls? → record
- Button does something visible? → record
- Tab reveals content or scrolls? → record
- Anything produces validation errors? → record
- Link navigates to another page? → record the destination (but don't write a navigation test — the destination page gets its own tests)
- **Form inputs found?** → this is important. For every form on the page (whether inline or inside a modal), record ALL input fields with their selectors, types, labels, and what values to fill them with. This includes:
  - Text inputs (`input[type="text"]`, `input[name="..."]`)
  - Date/calendar inputs (date pickers, `input[type="date"]`, calendar widgets)
  - Number inputs (`input[type="number"]`, guest counters with +/- buttons)
  - Dropdowns (`select`, custom dropdowns)
  - Textareas
  - Checkboxes and radio buttons

  **Try filling them during probing** — actually type values into inputs, select dates on calendars, increment number fields, check checkboxes. This confirms what works and what doesn't before you write test code.

  **Fill before clicking action buttons.** When a form has both inputs and a submit/action button (like "Book Now", "Search", "Apply"), the right test sequence is: fill all inputs first → capture the filled state → then click the button. A test that clicks "Book Now" without filling in dates and guests misses the most interesting UI state (the populated form) and may also miss validation behavior.

**A7. Probe inside modals/expanded UI**: when clicking reveals new UI (modal, drawer, expanded panel), probe THAT UI for its own interactive elements — buttons, forms, links within the modal. Keep going as long as new testable UI appears. For each form inside a modal, record all fields so you can write a form-fill test in Step B.

For every confirmed interaction, plan a test. For every form found, plan **three** tests:

1. A "click to open" test (snapshot of the modal/panel appearing)
2. A "fill the form" test (populate all fields, capture the filled state)
3. A "submit" test if there's a submit button (fill fields → click submit → capture the result)

This applies to inline forms too (forms that are already visible on the page without clicking anything). A booking form with date pickers and guest selectors, a search form with filters, a contact form — these all need fill tests. The filled state of a form is valuable test coverage because it exercises input rendering, validation UI, and date/number formatting.

**A8. Check responsive behavior** — this step is **mandatory**, not optional. Without it you'll write tests that fail on mobile (selector doesn't exist) or miss mobile-only UI entirely. Every page gets A8, no exceptions.

After completing desktop probing (A1-A7), resize the browser to mobile width and re-probe:

1. Resize to 375×667 via `mcp__claude-in-chrome__resize_window`
2. Take a screenshot and scroll through the mobile layout — visually note what's different from desktop (stacked columns, hidden sidebars, hamburger menus, mobile-specific UI)
3. Re-run `shaka-perf discover-abtests probe-sections` (via `javascript_tool`) at this width
4. Check each desktop selector from A4 — does it exist on mobile? Use `javascript_tool` to query visibility:
   ```js
   const el = document.querySelector('.rate-form-wrapper');
   el ? { display: getComputedStyle(el).display, height: el.getBoundingClientRect().height } : 'NOT FOUND';
   ```
5. Compare desktop vs mobile sections:
   - **Desktop selector hidden/absent on mobile** → restrict that test to `viewports: [tablet, desktop]` or `[desktop]`. Check if there's a mobile-specific replacement (e.g., `.mobile-nav` replaces `.nav-tabs`). If a replacement exists, plan a mobile-only test for it.
   - **New element on mobile not seen on desktop** → plan a mobile-only test for it
   - **Same selector, different dimensions** → note for threshold adjustment
6. Check interactive elements at mobile width — buttons/menus that appear only on mobile (hamburger menu, mobile filters, etc.)
7. Resize back to desktop width when done

**Gate**: before proceeding to A9, write down what you found — even if the answer is "mobile layout is identical, no differences found." If you can't describe what the mobile layout looks like, you haven't done A8.

**A9. Record findings** for this page:

- Path, human-readable name
- `data-cy` attributes, `id`s, and stable structural landmarks
- Skeleton/spinner CSS selectors to wait for
- Which interactions were confirmed working vs. tried and failed
- What new UI appeared from interactions (modals, drawers, expanded sections) and what's inside them
- Whether lazy load was confirmed (from A1), loading indicators found (from A2), any animations
- **A8 mobile findings** (required): list of desktop-only selectors, mobile-only selectors, mobile replacement elements, and a one-line summary of what the mobile layout looks like. If A8 found no differences, state that explicitly.
- **Shared section deduplication**: for each selector, check `claimedSections`:
  - Not claimed → add to this page's plan, register it
  - Already claimed → exclude, record `{ selector, skippedOn, alreadyCoveredBy }`
- **Product/detail pages**: only claim the unique top section (configurator, carousel). Don't claim shared lower sections (reviews, FAQ, footer).

### Step B — Write TODO comments with all probing findings

Read `references/patterns.md` (per-scenario code patterns) **and** `../assess-abtest-quality/SKILL.md` (the non-negotiable test code rules) before writing any test code. The rules in one line: tests must **fail loudly and run linearly** — no `try/catch` swallowing, no loops, no `if`-branching on page state (assert with `waitForSelector`/`waitForURL` instead), wait for conditions not the clock, deterministic inputs, each test independent.

Create/open the `.abtest.ts` file for this page (e.g., `homepage.abtest.ts`). Write `abTest()` stubs with `// TODO:` comments describing each planned test. Document ALL findings from probing so nothing is lost:

```typescript
import { abTest, TestType } from 'shaka-shared';
import { waitUntilPageSettled } from 'shaka-perf/visreg/helpers';

// TODO: Hero section snapshot
// - selector: [data-cy="hero"] or .hero-section
// - wait for: .skeleton (found in A2) to disappear
// - threshold: 0.05 (dynamic hero image)
abTest('Homepage Hero', { startingPath: '/', options: { visreg: {} } }, async () => {});

// TODO: Click "Contact Us" button → modal opens
// - confirmed in A6: clicking button.contact-cta opens modal .contact-modal
// - inside modal (A7): form with name, email, message fields
// - .contact-cta is display:none on mobile viewport (A8)
// - need desktop-only viewports
abTest('Homepage Contact Modal', { startingPath: '/', options: { visreg: {} } }, async () => {});

// TODO: Fill contact form inside modal
// - fields: input[name="name"], input[name="email"], textarea[name="message"]
// - depends on: opening the modal first (chained interaction)
abTest('Homepage Contact Form Fill', { startingPath: '/', options: { visreg: {} } }, async () => {});
```

Before moving to Step C, verify every category below has at least one TODO stub (or an explicit "none found" note). This is a gate — do not proceed until you've checked each one:

1. **Section snapshots** — hero, key content sections, footer (from A4)
2. **Click interactions** — every button/tab confirmed working in A6 gets a test
3. **Modals/drawers** — every modal opened in A6-A7 gets a "click to open" snapshot test
4. **Form fills** — every form on the page (inline or inside modals) gets a test that fills ALL its inputs and captures the populated state. This means: text fields get filled, dates get selected, number fields get incremented, dropdowns get opened and a value selected, checkboxes get checked. If a form has a submit button, there should also be a test that fills the form and then clicks submit. A booking form without a "fill dates and guests" test is a coverage gap.
5. **Viewport-specific from A8** — any desktop-only selectors must have `viewports` restricting them away from mobile. Any mobile-only elements found in A8 get a mobile-only test. If A8 found no mobile-specific elements, write "A8: no mobile-specific elements found" as a comment in the file.

### Threshold guidance

- `0.01` — static content (legal pages, about text, documentation)
- `0.05` — standard pages (hero images, structured layouts)
- `0.1` — highly dynamic content (listing cards, deal cards, pages with varying image counts)

Never raise a threshold to hide a real failure — fix the root cause.

### Annotation

Always call `annotate('description')` immediately before each action. When a test fails, the report shows **"Failed while \<description\>"** — without annotations the error is a raw stack trace.

Annotate waits, clicks, scrolls, fills, and state changes. Don't annotate every trivial `await`.

### Step C — Implement and validate tests one at a time

Implement each TODO stub directly in the real `.abtest.ts` file, then validate it using `--filter` to run only that test by name:

1. **Implement** the TODO stub — replace the empty `async () => {}` with the real test body
2. **Run** with `--filter` to execute only this test (the filter is a regex matched against the test name):

   _Twin-server mode_:

   ```bash
   cd <app-directory> && yarn shaka-perf visreg-compare --testFile ab-tests/<page>.abtest.ts --filter "Homepage Hero"
   ```

   _Single-server mode_:

   ```bash
   cd <app-directory> && yarn shaka-perf visreg-compare --testFile ab-tests/<page>.abtest.ts --filter "Homepage Hero" --controlURL <url> --experimentURL <url>
   ```

3. **Quick check**: read the screenshot to verify real content was captured (not blank)
4. **If pass** → move on to the next TODO stub
5. **If fail** → debug and fix (up to 3 attempts). If still failing, **comment out** the `abTest()` call (don't delete it) and add a `// TODO:` comment explaining what's broken and what was tried. This preserves the test code so it's easy to revisit later.

**Important**: `shaka-perf visreg` must be run from the directory containing `visreg.config.ts`. If the user specified an app directory, `cd` there first.

**After every test run**, execute these checks:

**1. Parse report.json** (includes whitespace and error detection):

```bash
shaka-perf discover-abtests parse-report
```

This prints status, diff%, whitespace%, and engine errors per test. Act on these flags:

- `HIGH-WHITE` (whitePixelPercent > 90%) → selector likely captures empty space. Re-evaluate: try a child element, a sibling, or a different section entirely. **Always read the screenshot** to confirm — a 30px property-specs strip can be 94% white yet "pass" since both servers captured the same tiny fragment.
- `ENGINE-ERR` → check `engineErrorMsg`. Common: `clip.width = 0` means element has no width at this viewport — add `viewports` override to exclude that breakpoint.
- `BOT70W = true` → content concentrated at top of element; bottom is empty. Consider a tighter selector.

A test that passes (0 diff) can still be broken if both control and experiment captured blank/useless content. The `whitePixelPercent` field catches this — high whitespace on a passing test means the selector is wrong.

**2. Inspect screenshots visually** — use the Read tool on `.png` files:

- `visreg_data/html_report/experiment_screenshot/`
- `visreg_data/html_report/reference_screenshot/`
- `visreg_data/html_report/experiment_screenshot/failed_diff_*.png`

Always look at screenshots before deciding on a fix. Do not rely on diff percentage alone.

### Step D — Full-file validation

After all TODO stubs are implemented:

1. Run `shaka-perf visreg-compare --testFile ab-tests/<page>.abtest.ts` with ALL tests in the file
2. Run `parse-report.py` and check for HIGH-WHITE / ENGINE-ERR flags
3. If tests that passed individually now fail in combination → debug and fix (timing issues, shared state, etc.)

### Step E — Coverage comparison (loop until covered)

1. Open the visreg HTML report (`visreg_data/html_report/index.html`) in Chrome
2. Open the live page in another Chrome tab
3. Go through the report images and compare with the live page to find:
   - Missing page sections (important content not captured by any test)
   - Missing interactions (buttons, forms, modals that should be tested but aren't)
   - Blank or mostly-white screenshots (missing lazy content)
4. **If gaps found** → go back to Step B: add new TODO stubs for the missing coverage, then implement them through Steps C-D, and repeat Step E
5. **If coverage is satisfactory** → move to the next page

### Acceptance criteria

A test only counts as PASS when **all** of the following are met:

| #   | Criterion                                                                          | Fix if failing                                                                                                                    |
| --- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1   | No loading indicators (spinners, skeletons) visible                                | Add `waitForLoadState('networkidle')` and/or `waitUntilPageSettled`                                                               |
| 2   | No mid-animation carousels — frames frozen at deterministic position               | Add CSS override confirmed in probing                                                                                             |
| 3   | No missing lazy-loaded content                                                     | Add scroll + networkidle + scroll-to-top. Blank screenshot check is ground truth — add scrolling even if probing didn't detect it |
| 4   | Thresholds appropriate — `0.01` static, `0.05` dynamic, `0.1` very dynamic         | Fix root cause                                                                                                                    |
| 5   | All selectors resolve without timeout                                              | Inspect DOM in Chrome, use a more reliable selector                                                                               |
| 6   | Every non-trivial action is annotated                                              | Add missing `annotate(...)` calls                                                                                                 |
| 7   | No auth-gated content (login page/access denied in screenshot)                     | Remove the test                                                                                                                   |
| 8   | No unconfirmed interactions — every click/scroll/CSS override validated in probing | Remove unconfirmed action                                                                                                         |
| 9   | No high-whitespace screenshots (`whitePixelPercent < 90` in report.json)           | Re-evaluate selector: try child element, parent, or different section. Read screenshot to verify.                                 |

**Before attempting any fix, look at the diff screenshot.** Two failure types:

1. **Test infrastructure failure** — broken test. Fix it.
2. **Real A/B difference** — test is working correctly. Don't fix — mark PASS (A/B diff).

### Common fixes

| Symptom                                    | Fix                                                                                                      |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| UI change on one server only               | Real A/B diff — mark PASS (A/B diff), do not raise threshold                                             |
| Skeleton/spinner visible                   | `waitForLoadState('networkidle')`                                                                        |
| Content missing (lazy)                     | scroll + networkidle + scroll-to-top                                                                     |
| Carousel moving                            | CSS override from probing                                                                                |
| Selector timeout                           | Inspect DOM in Chrome, use more reliable selector                                                        |
| High diff on dynamic content               | `hideSelectors`/`removeSelectors` or wait for settle — do not raise threshold                            |
| Selector not found on some viewports       | Element is `display:none` at that breakpoint — split into viewport-scoped tests (see patterns.md)        |
| High whitespace (whitePixelPercent > 90%)  | Wrong selector — try child, parent, or different section. Read screenshot to verify.                     |
| `Cannot type text into input[type=number]` | Use numeric-only strings: `'5551234567'` not `'555-123-4567'`                                            |
| `button:has-text("X")` matches multiple    | Use `page.getByLabel()`, `page.getByRole()`, or more specific CSS selector                               |
| `Timeout 60000ms on page.goto`             | Server too slow — page takes too long to respond                                                         |
| `size: isDifferent`                        | Dynamic content changes height between renders; often unfixable in single-server mode, mark NEEDS REVIEW |
| `strict mode violation`                    | Multiple elements match — use `.first()` or more specific selector                                       |

---

## Final summary

After all files are validated, print the report below **and** write it to `{output}/DISCOVERY_REPORT.md`.

The "Coverage decisions" section is important — it makes deduplication reasoning transparent so the user can verify nothing was accidentally omitted.

```markdown
## Discovered AB Tests

| File               | Tests | Status          | Notes                               |
| ------------------ | ----- | --------------- | ----------------------------------- |
| homepage.abtest.ts | 2     | PASS            |                                     |
| cart.abtest.ts     | 1     | PASS (A/B diff) | Experiment has new checkout button  |
| products.abtest.ts | 1     | NEEDS REVIEW    | Selector timeout on mobile viewport |

Statuses:

- **PASS** — no diff, both servers identical
- **PASS (A/B diff)** — test ran correctly and detected a real difference
- **NEEDS REVIEW** — test infrastructure issue (flaky, timeout, broken selector)

Total: N files, M tests (X passing, Y A/B diffs detected, Z needs review)
Output: ./ab-tests/

## Coverage decisions

### Shared sections (tested once)

| Section                    | Tested on            | Skipped on                |
| -------------------------- | -------------------- | ------------------------- |
| `[data-cy="testimonials"]` | `homepage.abtest.ts` | product pages, about page |
| `footer`                   | `homepage.abtest.ts` | all other pages           |

### Pages scoped to unique content only

| Page               | Selector used                      | Reason                                                |
| ------------------ | ---------------------------------- | ----------------------------------------------------- |
| `/products/widget` | `[data-cy="product-configurator"]` | Lower sections covered by representative product page |

### Skipped pages

| Path        | Reason               |
| ----------- | -------------------- |
| `/admin`    | Auth required        |
| `/checkout` | Multi-step auth flow |
```

Then ask: "Would you like me to dig into any failing tests or adjust any of the coverage decisions?"
