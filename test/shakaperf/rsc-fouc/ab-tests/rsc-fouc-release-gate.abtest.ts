import { abTest, installRequestBlocking } from 'shaka-shared';

const RSC_CSS_PROBE_SELECTOR = '[data-testid="rsc-css-probe"]';
const RSC_STYLESHEET_SELECTOR = 'link[rel="stylesheet"][data-precedence="ror-rsc"]';
// Matches .probe background-color in react_on_rails_pro/spec/dummy/client/app/components/RSCPostsPage/UseClientCssProbe.module.scss.
const EXPECTED_BACKGROUND = 'rgb(212, 250, 236)';

abTest(
  'rsc first paint use-client css emits stylesheet before hydration',
  {
    startingPath: '/rsc_posts_page_over_http',
    testTypes: ['visreg'],
    options: {
      beforeNavigate: ({ context }) => installRequestBlocking(context, ['/webpack/test/js/']),
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
    await annotate('wait for css probe');
    await page.waitForSelector(RSC_CSS_PROBE_SELECTOR, { state: 'visible', timeout: 10_000 });

    await annotate('assert RSC stylesheet link is server-rendered');
    await page.waitForSelector(RSC_STYLESHEET_SELECTOR, { state: 'attached', timeout: 5_000 });

    await annotate('assert probe CSS is applied before hydration');
    await page.waitForFunction(
      ({ expectedBackground, selector }) => {
        const element = document.querySelector(selector);
        if (!element) return false;

        return getComputedStyle(element).backgroundColor === expectedBackground;
      },
      { expectedBackground: EXPECTED_BACKGROUND, selector: RSC_CSS_PROBE_SELECTOR },
      { timeout: 5_000, polling: 'raf' },
    );

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
    startingPath: '/rsc_posts_page_over_http',
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
    await annotate('wait first visible');
    const stateHandle = await page.waitForFunction(
      (selector) => {
        const element = document.querySelector(selector);
        if (!element) return false;

        const box = element.getBoundingClientRect();
        if (box.width <= 0 || box.height <= 0) return false;

        const style = getComputedStyle(element);
        return {
          backgroundColor: style.backgroundColor,
          color: style.color,
          padding: style.padding,
          borderRadius: style.borderRadius,
          width: Math.round(box.width),
          height: Math.round(box.height),
          text: element.textContent,
        };
      },
      RSC_CSS_PROBE_SELECTOR,
      { timeout: 5_000, polling: 'raf' },
    );
    const state = (await stateHandle.jsonValue()) as {
      backgroundColor: string;
      color: string;
      padding: string;
      borderRadius: string;
      width: number;
      height: number;
      text: string | null;
    };

    await annotate('assert styled');
    if (state.backgroundColor !== EXPECTED_BACKGROUND) {
      throw new Error(
        `${isControl ? 'control' : 'experiment'} first visible probe is unstyled: ${JSON.stringify(state)}`,
      );
    }
  },
);
