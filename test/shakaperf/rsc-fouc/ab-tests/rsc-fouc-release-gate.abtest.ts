import { abTest, installRequestBlocking } from 'shaka-shared';

const RSC_CSS_PROBE_SELECTOR = '[data-testid="rsc-css-probe"]';
const RSC_CSS_PROBE_PATH = '/rsc_posts_page_over_http?posts_count=0';
// The Pro RSC renderer emits client-reference stylesheets as
// `<link rel="stylesheet" data-precedence="rsc-css">` (see
// packages/react-on-rails-pro/src/injectRSCPayload.ts). The earlier
// `precedence="ror-rsc"` wrapper this gate originally targeted was reverted in
// #3860; keep this selector in sync with the value the renderer actually emits.
const RSC_STYLESHEET_SELECTOR = 'link[rel="stylesheet"][data-precedence="rsc-css"]';
// A styled probe must have a real CSS-module background, not the default unstyled page background.
// If the intended probe style ever matches one of these defaults, change the Pro dummy probe color first.
// This avoids pinning the gate to cosmetic RGB changes in the dummy component.
const UNSTYLED_BACKGROUNDS = [
  // Default computed background for an unstyled element.
  'rgba(0, 0, 0, 0)',
  // Defensive match for engines or helpers that preserve the CSS keyword.
  'transparent',
  // Default page/reset background if the probe inherits the canvas color.
  'rgb(255, 255, 255)',
];

type FirstVisibleProbeState = {
  hasStylesheet: boolean;
  backgroundColor: string;
  color: string;
  padding: string;
  borderRadius: string;
  width: number;
  height: number;
  text: string | null;
};

type ShakaPerfPage = Parameters<Parameters<typeof abTest>[2]>[0]['page'];

async function waitForFirstVisibleProbeState(page: ShakaPerfPage): Promise<FirstVisibleProbeState> {
  const stateHandle = await page.waitForFunction(
    ({ probeSelector, stylesheetSelector }) => {
      const element = document.querySelector(probeSelector);
      if (!element) return false;

      const box = element.getBoundingClientRect();
      if (box.width <= 0 || box.height <= 0) return false;

      const style = getComputedStyle(element);
      return {
        hasStylesheet: Boolean(document.querySelector(stylesheetSelector)),
        backgroundColor: style.backgroundColor,
        color: style.color,
        padding: style.padding,
        borderRadius: style.borderRadius,
        width: Math.round(box.width),
        height: Math.round(box.height),
        text: element.textContent,
      };
    },
    { probeSelector: RSC_CSS_PROBE_SELECTOR, stylesheetSelector: RSC_STYLESHEET_SELECTOR },
    { timeout: 10_000, polling: 'raf' },
  );

  return (await stateHandle.jsonValue()) as FirstVisibleProbeState;
}

abTest(
  'rsc first paint use-client css emits stylesheet before hydration',
  {
    startingPath: RSC_CSS_PROBE_PATH,
    testTypes: ['visreg'],
    options: {
      beforeNavigate: ({ context }) => installRequestBlocking(context, ['.js']),
      viewports: ['desktop'],
      visreg: {
        selectors: [RSC_CSS_PROBE_SELECTOR],
        readyTimeout: 10_000,
        misMatchThreshold: 0.001,
        maxNumDiffPixels: 10,
      },
    },
  },
  async ({ page, annotate }) => {
    await annotate('capture first visible css probe');
    const state = await waitForFirstVisibleProbeState(page);

    await annotate('assert stylesheet at first visibility');
    if (!state.hasStylesheet) {
      throw new Error(`RSC stylesheet missing at first visible probe: ${JSON.stringify(state)}`);
    }

    await annotate('assert CSS at first visibility');
    if (UNSTYLED_BACKGROUNDS.includes(state.backgroundColor)) {
      throw new Error(`first visible probe is unstyled before hydration: ${JSON.stringify(state)}`);
    }

    await annotate('wait for load');
    await page.waitForLoadState('load');

    await annotate('two frames before capture');
    await page.evaluate(() => {
      return new Promise<void>((resolve) => {
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            resolve();
          });
        });
      });
    });
  },
);

abTest(
  'rsc real first-visible probe is styled',
  {
    startingPath: RSC_CSS_PROBE_PATH,
    testTypes: ['visreg'],
    options: {
      viewports: ['desktop'],
      visreg: {
        selectors: [RSC_CSS_PROBE_SELECTOR],
        readyTimeout: 10_000,
        misMatchThreshold: 0.001,
        maxNumDiffPixels: 10,
      },
    },
  },
  async ({ page, annotate, isControl }) => {
    // Same candidate URL is loaded for both sides; isControl only labels the failing side in reports.
    // JavaScript is intentionally unblocked here for the visual report; the first abtest is the SSR correctness guard.
    await annotate('wait first visible');
    const state = await waitForFirstVisibleProbeState(page);

    await annotate('assert styled');
    if (UNSTYLED_BACKGROUNDS.includes(state.backgroundColor)) {
      throw new Error(
        `${isControl ? 'control' : 'experiment'} first visible probe is unstyled: ${JSON.stringify(state)}`,
      );
    }
  },
);
