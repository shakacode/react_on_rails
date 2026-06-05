import { abTest, installRequestBlocking } from 'shaka-shared';

const RSC_CSS_PROBE_SELECTOR = '[data-testid="rsc-css-probe"]';

abTest(
  'rsc first paint use-client css is styled before hydration',
  {
    startingPath: '/rsc_posts_page_over_http',
    testTypes: ['visreg'],
    options: {
      // Block the webpack app bundle so the capture stays at server-rendered
      // first paint before React hydration can repair missing styles.
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

    await annotate('wait for css/network idle');
    await page.waitForLoadState('networkidle');

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
