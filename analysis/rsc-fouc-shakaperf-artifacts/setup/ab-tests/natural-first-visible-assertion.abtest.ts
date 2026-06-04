import { abTest } from 'shaka-shared';

const RSC_CSS_PROBE_SELECTOR = '[data-testid="rsc-css-probe"]';
const EXPECTED_BACKGROUND = 'rgb(212, 250, 236)';

abTest(
  'diagnostic real first visible probe is styled',
  {
    startingPath: '/rsc_posts_page_over_http',
    testTypes: ['visreg'],
    options: {
      viewports: ['desktop'],
      visreg: {
        selectors: [RSC_CSS_PROBE_SELECTOR],
        readyTimeout: 5_000,
        misMatchThreshold: 0.001,
        maxNumDiffPixels: 10,
      },
    },
  },
  async ({ page, annotate, isControl }) => {
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
