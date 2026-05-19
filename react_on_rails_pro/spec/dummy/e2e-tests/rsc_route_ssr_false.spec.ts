import { test, expect } from '@playwright/test';

const MIXED_ROUTE_PATH = '/server_router/mixed-ssr-and-deferred-server-components';
const DEFAULT_PAYLOAD_KEY = 'MyServerComponent-{}-ServerComponentRouter-react-component-0';
const DEFERRED_PAYLOAD_KEY = 'SimpleComponent-{}-ServerComponentRouter-react-component-0';

test.describe('RSCRoute ssr=false', () => {
  test('server-renders sibling routes while deferring the ssr=false route', async ({ page, request }) => {
    const response = await request.get(MIXED_ROUTE_PATH);
    expect(response.ok()).toBe(true);
    const html = await response.text();

    expect(html).toContain('Mixed RSC route shell before');
    expect(html).toContain('Server Component Title');
    expect(html).toContain('Deferred route loading');
    expect(html).toContain('Mixed RSC route shell after');
    expect(html).toContain(DEFAULT_PAYLOAD_KEY);
    expect(html).not.toContain(DEFERRED_PAYLOAD_KEY);
    expect(html).not.toContain('Post 1');

    const consoleMessages: string[] = [];
    page.on('console', (message) => {
      consoleMessages.push(`${message.type()}: ${message.text()}`);
    });

    const deferredPayloadRequest = page.waitForRequest(/\/rsc_payload\/SimpleComponent/);
    await page.goto(MIXED_ROUTE_PATH);
    await deferredPayloadRequest;

    await expect(page.getByTestId('mixed-rsc-route-page')).toBeVisible();
    await expect(page.getByText('Mixed RSC route shell before')).toBeVisible();
    await expect(page.getByText('Server Component Title')).toBeVisible();
    await expect(page.getByText('Post 1')).toBeVisible();
    await expect(page.getByText('Mixed RSC route shell after')).toBeVisible();
    await expect(page.getByTestId('deferred-rsc-route-fallback')).not.toBeVisible();

    const rscRequests = (await page.requests()).filter((payloadRequest) =>
      payloadRequest.url().includes('/rsc_payload/'),
    );
    expect(
      rscRequests.some((payloadRequest) => payloadRequest.url().includes('/rsc_payload/SimpleComponent')),
    ).toBe(true);
    expect(
      rscRequests.some((payloadRequest) => payloadRequest.url().includes('/rsc_payload/MyServerComponent')),
    ).toBe(false);

    const browserConsole = consoleMessages.join('\n');
    expect(browserConsole).not.toContain('notifySSREnd() called multiple times');
    expect(browserConsole).not.toContain('skipped server rendering because it was rendered with ssr={false}');
  });
});
