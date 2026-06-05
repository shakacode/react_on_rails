# abtest.ts Patterns

Each pattern below corresponds to a scenario you confirmed during probing. Only use a pattern if the corresponding behavior was actually observed.

## Test code rules (non-negotiable)

See [`../../assess-abtest-quality/SKILL.md`](../../assess-abtest-quality/SKILL.md) — the canonical list (no error swallowing, no loops, no `if`-branching on page state, wait for conditions, prefer user-facing locators, deterministic inputs, each test independent). Read it before writing or grading any test.

## Selectors strategy

### How to choose selectors

1. **CSS selectors (preferred)** — `selectors: ['.section-class']` captures the element's bounding box thanks to `useBoundingBoxViewportForSelectors: true` in `visreg.config.ts`. The engine automatically calls `scrollIntoViewIfNeeded()` before capture, so manual scroll calls are only needed to trigger lazy loading, not for positioning.

2. **Viewport + scroll (fallback)** — only use `selectors: ['viewport']` if no CSS selector can target the section. See scroll-to-section pattern below.

3. **Short pages (<2000px)** — a single `'document'` capture is enough.

4. **Tall pages (>2000px)** — run `scripts/probe-sections.js` to find scored candidates, then apply AI visual heuristics to pick the best selectors.

### Finding selectors for tall pages

Use a two-strategy approach:

**Strategy 1 — Algorithmic probe** (`scripts/probe-sections.js`):
Run via `javascript_tool` after the page loads. It walks the DOM, scores elements by size, width, depth, semantic name, heading inclusion, content density, and uniqueness. Elements >1000px tall are penalized so their children get picked. Returns up to 15 non-overlapping candidates.

**Strategy 2 — AI visual analysis**:
Scroll through the page and identify natural visual sections a user would recognize. For each, find the closest DOM element that wraps it. Evaluate: "If I capture just this element, will the screenshot show recognizable, self-contained UI?"

### Good selector characteristics (what to pick)

- Height 100-800px (a meaningful visual chunk)
- Full-width (>90% of page) for main sections; 300-500px for sidebars
- Shallow in DOM (close to layout root)
- Semantic class name (`hero-slider`, `review-list`, not `_a3f2b`)
- Unique — `querySelectorAll` returns exactly 1 element
- Contains real text/images, not just empty wrappers
- **Includes its heading** — if an `<h2>` sits above, try the parent
- **"Tells a story"** — screenshot makes sense on its own

### Bad selector characteristics (what to avoid)

- Height < 50px — too granular, captures a fragment (e.g., a specs strip)
- `whitePixelPercent > 90%` after capture — mostly empty space
- Width = 0 at some viewports — causes `clip.width = 0` engine error
- Content renders in a child, not the selected element (common with `-container` wrappers)
- Height > 1000px — too tall, split into sub-sections
- **"Would a designer draw a box here?"** — if no, it's not a real section

### Two-column layouts (content + sidebar)

- Capture content column and sidebar as **separate tests**
- Sidebar test should have `viewports: [desktop]` (sidebars typically hidden/repositioned on mobile)
- Detect sidebars: elements with `position: absolute/sticky/fixed` narrower than 50% page width

### Post-capture validation

After running each test, check `parse-report.py` output:

- `whitePixelPercent > 90` → selector captures too much empty space. Try child or sibling.
- `isBottomSeventyPercentWhite = true` → content concentrated at top
- `hadEngineError` with `clip.width = 0` → add viewport restrictions
- **Always read the first screenshot** of a new selector — whitespace metrics alone can miss "technically not blank but visually useless" captures

When a locator might match multiple elements, use `.first()`:

```typescript
await page.locator('.section-class').first().scrollIntoViewIfNeeded();
```

## Simple snapshot (most pages)

Use for any page with no meaningful dynamic content.

```typescript
import { abTest } from 'shaka-shared';
import { waitUntilPageSettled } from 'shaka-perf/visreg/helpers';

abTest(
  'Page Name',
  {
    startingPath: '/path',
    options: { visreg: { delay: 50, misMatchThreshold: 0.05 } },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);
```

## With specific selectors

Use when the page has notable named sections worth capturing individually, or when `document` would be too tall (>3000px).

```typescript
abTest(
  'Page Name',
  {
    startingPath: '/path',
    options: { visreg: { selectors: ['[data-cy="hero"]', 'document'], delay: 50, misMatchThreshold: 0.01 } },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);
```

## Interaction test (click confirmed working in probing)

Only use if you clicked the element during probing and saw a visible effect.

```typescript
import { abTest, TestType } from 'shaka-shared';
import { waitUntilPageSettled } from 'shaka-perf/visreg/helpers';

abTest(
  'Click [Button] on [Page]',
  {
    startingPath: '/start',
    options: { visreg: { misMatchThreshold: 0.05, maxNumDiffPixels: 5 } },
  },
  async ({ page, testType, annotate }) => {
    annotate('waiting for element to appear');
    await page.waitForSelector('[data-cy="element"]');
    annotate('clicking button');
    await page.click('text=Button Text');
    annotate('waiting for navigation to expected path');
    await page.waitForURL('**/expected-path');
    annotate('waiting for page to settle after navigation');
    await waitUntilPageSettled(page);
  },
);
```

## Page with lazy-loaded content (scroll confirmed in probing)

Only use if `scripts/probe-lazy-load.js` (or manual scroll probing) confirmed new content appeared after scrolling.

**NEVER use `while (!atBottom)` scroll loops with `page.mouse.wheel()`** — they go infinite in shaka-perf visreg because `window.scrollY` doesn't update in the Playwright context. Instead, use `scrollIntoViewIfNeeded()` on a known bottom element (footer, last section) to trigger lazy loading.

```typescript
abTest(
  'Page Name',
  {
    startingPath: '/path',
    options: { visreg: { delay: 50, misMatchThreshold: 0.05 } },
  },
  async ({ page, annotate }) => {
    annotate('scrolling to bottom to trigger lazy load');
    await page.locator('footer').scrollIntoViewIfNeeded();
    annotate('waiting for lazy-loaded content to finish loading');
    await page.waitForLoadState('networkidle');
    annotate('scrolling back to top');
    await page.evaluate(() => window.scrollTo(0, 0));
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);
```

If there's no footer, use the last visible section or `page.locator('body > *:last-child')`. The key is to avoid scroll loops entirely.

## Viewport-conditional selectors (element hidden on some viewports)

Use when a selector only exists on certain viewports (e.g. `display: none` on mobile). The `viewport` labels come from `visreg.config.ts` (e.g. `'mobile'`, `'tablet'`, `'desktop'`).

### Split into separate tests with `viewports` override

Write separate `abTest()` calls scoped to specific viewports via the `viewports` option, so each test only runs where its selector exists. No branching logic, clear test names, failures easy to trace.

```typescript
import { abTest } from 'shaka-shared';
import { waitUntilPageSettled } from 'shaka-perf/visreg/helpers';

// Desktop/tablet only — .map-container is display:none on mobile
abTest(
  'Homepage Map Section',
  {
    startingPath: '/',
    options: {
      visreg: {
        selectors: ['.map-container'],
        misMatchThreshold: 0.05,
        viewports: [
          { label: 'tablet', width: 768, height: 1024 },
          { label: 'desktop', width: 1280, height: 800 },
        ],
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);

// mobile only — .mobile-featured-grid replaces the desktop grid
abTest(
  'Homepage Mobile Featured',
  {
    startingPath: '/',
    options: {
      visreg: {
        selectors: ['.mobile-featured-grid'],
        misMatchThreshold: 0.05,
        viewports: [{ label: 'mobile', width: 375, height: 667 }],
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);
```

### Different _logic_ per viewport? Still split — don't branch

When the viewport difference is test logic (different waits, clicks, or scroll behaviour), not just which selector to capture, it's tempting to branch on `viewport.label` inside one callback. Don't — that violates the "no `if`" rule and hides which path actually ran. Write one test per viewport, each with its own linear body and a `viewports` override:

```typescript
// mobile — results render as a list
abTest(
  'Search Results (mobile)',
  {
    startingPath: '/search',
    options: {
      visreg: {
        misMatchThreshold: 0.05,
        delay: 100,
        viewports: [{ label: 'mobile', width: 375, height: 667 }],
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for mobile results list');
    await page.waitForSelector('.mobile-results', { state: 'visible' });
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);

// desktop/tablet — results render in a split panel
abTest(
  'Search Results (desktop)',
  {
    startingPath: '/search',
    options: {
      visreg: {
        misMatchThreshold: 0.05,
        delay: 100,
        viewports: [{ label: 'desktop', width: 1280, height: 800 }],
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for split-panel search layout');
    await page.waitForSelector('.search-split-panel', { state: 'visible' });
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);
```

## Carousel / animation (CSS override confirmed in probing)

Only use if injecting the CSS override during probing visually froze the animation.

```typescript
import { abTest } from 'shaka-shared';
import { waitUntilPageSettled, overrideCSS } from 'shaka-perf/visreg/helpers';

const PAUSE_CSS = `
  [data-cy="carousel-track"] { animation: none !important; transform: translateX(0) !important; }
`;

abTest(
  'Carousel on [Page]',
  {
    startingPath: '/path',
    options: { visreg: { delay: 50, misMatchThreshold: 0.05 } },
  },
  async ({ page, annotate }) => {
    annotate('waiting for carousel to appear');
    await page.waitForSelector('[data-cy="carousel-track"]', { state: 'visible' });
    annotate('overriding CSS to freeze carousel animation');
    await overrideCSS(page);
    await page.addStyleTag({ content: PAUSE_CSS });
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
  },
);
```

## Scroll to section (fallback — CSS selector not available)

Only use when a CSS selector can't target the section you need AND the test screenshot shows mostly whitespace in the bottom 60% of the page. Read the test images to verify before switching to this pattern. The preferred approach is always a CSS selector (see "Selectors strategy" above).

```typescript
abTest(
  'Below-fold Section on [Page]',
  {
    startingPath: '/path',
    options: {
      visreg: {
        selectors: ['viewport'],
        misMatchThreshold: 0.05,
        delay: 50,
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    annotate('scrolling target section into view');
    await page.locator('.target-section').first().scrollIntoViewIfNeeded();
  },
);
```

## Modal / expandable interaction (confirmed in probing)

Click a button to open a modal, drawer, or expanded panel, then capture the result. Also probe and test interactions INSIDE the modal — if the modal contains forms, buttons, or links, write separate tests for those (see form filling and chained interaction patterns below).

```typescript
abTest(
  'Open [Modal Name] on [Page]',
  {
    startingPath: '/path',
    options: {
      visreg: {
        selectors: ['viewport'],
        misMatchThreshold: 0.05,
        viewports: [{ label: 'desktop', width: 1280, height: 800 }],
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    annotate('clicking button to open modal');
    await page.locator('[data-cy="open-modal"]').click();
    annotate('waiting for modal to appear');
    await page.waitForTimeout(500);
  },
);
```

## Form filling (confirmed in probing)

Fill form inputs and capture the filled state. Use `page.fill()` for text inputs and textareas. For `type="number"` inputs, use numeric-only strings (no dashes or special characters). Use `page.getByLabel()` when inputs have associated labels.

```typescript
abTest(
  'Fill [Form Name] on [Page]',
  {
    startingPath: '/path',
    options: {
      visreg: {
        selectors: ['.form-container'],
        misMatchThreshold: 0.05,
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    annotate('filling name field');
    await page.fill('input[name="name"]', 'Jane Smith');
    annotate('filling email field');
    await page.fill('input[name="email"]', 'jane@example.com');
    // For type="number" inputs, use numeric-only strings:
    annotate('filling phone field');
    await page.fill('input[name="phone"]', '5551234567');
    // For textareas:
    annotate('filling message field');
    await page.fill('textarea[name="message"]', 'Test message text');
  },
);
```

## Date picker / calendar inputs (confirmed in probing)

Date pickers vary widely — probe the specific implementation during A6 to determine the right approach. Common patterns:

```typescript
// Pattern 1: Native date input
await page.fill('input[type="date"]', '2026-06-15');

// Pattern 2: Click-to-open calendar widget (e.g., DayPicker, react-dates)
// Click the input/button to open the calendar, then click a specific date
annotate('clicking Check In to open calendar');
await page.locator('.check-in-input').click();
await page.waitForTimeout(300);
annotate('selecting a date');
await page.locator('td[aria-label="June 15, 2026"]').click(); // or similar
await page.waitForTimeout(300);

// Pattern 3: Calendar already visible on page (inline calendar)
// Just click dates directly
annotate('selecting start date on calendar');
await page.locator('.CalendarDay:has-text("15")').first().click();
await page.waitForTimeout(200);
annotate('selecting end date on calendar');
await page.locator('.CalendarDay:has-text("20")').first().click();
```

When probing calendars, check: does clicking a date input open a popup? What are the day cell selectors? Are dates clickable `<td>` elements or `<button>` elements? Use `aria-label` attributes when available — they're the most reliable selectors for specific dates.

## Number increment inputs (confirmed in probing)

For inputs with +/- buttons (guest counters, quantity selectors), click the increment button rather than trying to type into the field. The display value is often read-only.

```typescript
annotate('incrementing adult count');
// Click the "+" button next to Adults — find it by proximity to the label
await page.locator('.adult-counter .increment-btn').click(); // or:
await page.locator('button:has-text("+")').first().click();
await page.waitForTimeout(200);
// Repeat for desired count
await page.locator('button:has-text("+")').first().click();
await page.waitForTimeout(200);
```

When probing +/- inputs, note: what selector targets the + button? Does clicking it update a visible number? Is there a max limit? Record all of this so the test can be written without guessing.

## Populating a full form before submit (chained interaction)

When a form has multiple inputs AND a submit button, the test should fill everything first, then submit. This captures both the filled-form state and any validation/error UI that appears after submission.

```typescript
abTest(
  'Fill and Submit Booking on [Page]',
  {
    startingPath: '/path',
    options: {
      visreg: {
        selectors: ['viewport'],
        misMatchThreshold: 0.05,
        viewports: [{ label: 'desktop', width: 1280, height: 800 }],
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    // Fill all inputs first
    annotate('selecting check-in date');
    await page.locator('.check-in-input').click();
    await page.waitForTimeout(300);
    await page.locator('td[aria-label="June 15, 2026"]').click();
    await page.waitForTimeout(300);
    annotate('selecting check-out date');
    await page.locator('td[aria-label="June 20, 2026"]').click();
    await page.waitForTimeout(300);
    annotate('opening guests dropdown');
    await page.locator('.guest-input-btn').click();
    await page.waitForTimeout(300);
    annotate('incrementing adult count');
    await page.locator('.increment-btn').first().click();
    await page.waitForTimeout(200);
    // Now click the submit button with all fields populated
    annotate('clicking Book Now');
    await page.locator('button:has-text("Book Now")').click();
    await page.waitForTimeout(500);
  },
);
```

## Checkbox / filter interaction (confirmed in probing)

Use `page.getByLabel()` for checkboxes and radio buttons. Add `{ exact: true }` when the label text could partially match other labels.

```typescript
abTest(
  'Apply Filters on [Page]',
  {
    startingPath: '/path',
    options: {
      visreg: {
        selectors: ['.results-container'],
        misMatchThreshold: 0.1,
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    annotate('checking first filter option');
    await page.getByLabel('Option A').check();
    await page.waitForTimeout(200);
    annotate('checking second filter option');
    await page.getByLabel('Option B', { exact: true }).check();
    await page.waitForTimeout(300);
  },
);
```

## Chained interaction (confirmed in probing)

Click something → new UI appears → interact with the new UI. Each link in the chain should have been confirmed during probing. If the new UI itself reveals more interactions (e.g., a filter panel with checkboxes), chain further.

```typescript
abTest(
  'Open Filters and Apply on [Page]',
  {
    startingPath: '/path',
    options: {
      visreg: {
        selectors: ['.results-container'],
        misMatchThreshold: 0.1,
      },
    },
  },
  async ({ page, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    annotate('clicking to open filter panel');
    await page.locator('[aria-expanded]').first().click();
    await page.waitForTimeout(300);
    annotate('checking filter option');
    await page.getByLabel('Category A').check();
    await page.waitForTimeout(200);
    annotate('clicking apply button');
    await page.locator('button:has-text("Apply")').click();
    await page.waitForTimeout(500);
  },
);
```

## Navigation click (confirmed in probing)

Click a CTA or link that navigates to another page, then capture the destination. Use `{ waitUntil: 'commit' }` for pages with slow server responses (>30s).

```typescript
import { abTest, TestType } from 'shaka-shared';
import { waitUntilPageSettled } from 'shaka-perf/visreg/helpers';

abTest(
  'Click [CTA] on [Page]',
  {
    startingPath: '/start-page',
    options: {
      visreg: {
        selectors: ['viewport'],
        misMatchThreshold: 0.05,
        viewports: [{ label: 'desktop', width: 1280, height: 800 }],
      },
    },
  },
  async ({ page, testType, annotate }) => {
    annotate('waiting for page to settle');
    await waitUntilPageSettled(page);
    annotate('clicking CTA link');
    await page.locator('a[href="/destination"]').click();
    annotate('waiting for navigation');
    await page.waitForURL('**/destination');
    // For slow pages: await page.waitForURL('**/destination', { waitUntil: 'commit' });
    annotate('waiting for destination page to settle');
    await waitUntilPageSettled(page);
  },
);
```
