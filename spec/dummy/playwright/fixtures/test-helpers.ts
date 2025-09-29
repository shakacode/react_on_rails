import { test as base, expect } from '@playwright/test';

// Custom fixtures for React on Rails testing
type ReactOnRailsFixtures = {
  waitForReactOnRails: () => Promise<void>;
  getComponentRegistry: () => Promise<any>;
};

export const test = base.extend<ReactOnRailsFixtures>({
  waitForReactOnRails: async ({ page }, use) => {
    const waitFn = async () => {
      await page.waitForFunction(
        () => {
          return (
            typeof (window as any).ReactOnRails !== 'undefined' &&
            (window as any).ReactOnRails.mountedComponents
          );
        },
        { timeout: 10000 },
      );
    };
    await use(waitFn);
  },

  getComponentRegistry: async ({ page }, use) => {
    const getFn = async () => {
      return await page.evaluate(() => {
        const ReactOnRails = (window as any).ReactOnRails;
        if (!ReactOnRails) return null;

        return {
          mountedComponents: ReactOnRails.mountedComponents,
          registeredComponents: Object.keys(ReactOnRails.getComponent ? {} : ReactOnRails),
        };
      });
    };
    await use(getFn);
  },
});

export { expect };

// Helper functions for common React on Rails testing patterns
export async function waitForHydration(page: any) {
  // Wait for React on Rails to complete hydration
  await page.waitForFunction(() => {
    const ReactOnRails = (window as any).ReactOnRails;
    return ReactOnRails && ReactOnRails.mountedComponents;
  });
}

export async function getServerRenderedData(page: any, componentId: string) {
  return await page.evaluate((id) => {
    const element = document.getElementById(id);
    if (!element) return null;

    const scriptTag = element.previousElementSibling;
    if (scriptTag && scriptTag.tagName === 'SCRIPT') {
      try {
        return JSON.parse(scriptTag.textContent || '{}');
      } catch (e) {
        return null;
      }
    }
    return null;
  }, componentId);
}

export async function expectNoConsoleErrors(page: any) {
  const errors: string[] = [];

  page.on('console', (message: any) => {
    if (message.type() === 'error') {
      const text = message.text();
      // Filter out known non-issues
      if (
        !text.includes('Download the React DevTools') &&
        !text.includes('SharedArrayBuffer') &&
        !text.includes('immediate_hydration')
      ) {
        errors.push(text);
      }
    }
  });

  return () => {
    expect(errors).toHaveLength(0);
  };
}
