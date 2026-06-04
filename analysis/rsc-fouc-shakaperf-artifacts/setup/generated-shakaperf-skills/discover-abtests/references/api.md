# abTest API Reference

## `abTest(name, config, testFn)`

```typescript
import { abTest, TestType } from 'shaka-shared';

abTest(name: string, {
  startingPath: string,
  options?: {
    visreg?: {
      // What to capture
      selectors?: string[];          // CSS selectors to screenshot. Default: ['document']
                                     // Special values: 'document' (full page), 'viewport', 'body'
      hideSelectors?: string[];      // Hide elements (display:none) before capture
      removeSelectors?: string[];    // Remove elements from DOM before capture

      // Thresholds
      misMatchThreshold?: number;    // 0.0–1.0. Default: 0.1. Use 0.01 for static pages
      maxNumDiffPixels?: number;     // Max differing pixels allowed. Default: 50

      // Timing / readiness
      delay?: number;                // Fixed ms delay after navigation
      readySelector?: string;        // Wait for this selector to appear before capturing
      readyEvent?: string;           // Wait for this custom DOM event before capturing

      // Built-in interactions (use when you don't need testFn logic)
      clickSelector?: string;        // Click a single element
      clickSelectors?: string[];     // Click multiple elements in sequence
      hoverSelector?: string;        // Hover a single element
      hoverSelectors?: string[];     // Hover multiple elements
      scrollToSelector?: string;     // Scroll element into view before capture
      postInteractionWait?: number | string; // ms or selector to wait after interactions

      // Lifecycle hook
      onBefore?: (context) => Promise<void>; // Runs before navigation — use for
                                              // cookies, localStorage, feature flags

      // Viewport override
      viewports?: { label: string, width: number, height: number }[];
                                     // Override global viewports for this test only

      // Auth
      cookiePath?: string;           // Path to JSON cookie file to load before test
    }
  }
}, async ({ page, testType, isReference, viewport, browserContext, annotate }) => {
  // testType: TestType.VisualRegression | TestType.Performance
  // isReference: true for control server, false for experiment
  // viewport: { label, width, height } — current viewport being tested
})
```

## Helpers (`shaka-perf/visreg/helpers`)

| Helper                       | What it does                                                                                                                  |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `waitUntilPageSettled(page)` | Waits for DOM mutations, network idle, fonts, images, and spinners to settle (30s timeout). Use instead of arbitrary `delay`. |
| `overrideCSS(page)`          | Injects CSS to strip background images — reduces noise in visual diffs.                                                       |
| `interceptImages(page)`      | Replaces all image requests with a stub — call before `page.goto()` for fully deterministic renders.                          |

## `onBefore` pattern

Use `onBefore` when you need to set up state _before_ the page navigates — e.g. injecting cookies, setting localStorage, or enabling a feature flag. It receives the same context as `testFn`.

```typescript
abTest(
  'Feature flag test',
  {
    startingPath: '/checkout',
    options: {
      visreg: {
        onBefore: async ({ browserContext }) => {
          await browserContext.addCookies([
            { name: 'flag_new_checkout', value: '1', domain: 'localhost', path: '/' },
          ]);
        },
      },
    },
  },
  async ({ page }) => {
    await waitUntilPageSettled(page);
  },
);
```
