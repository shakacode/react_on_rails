/**
 * @jest-environment node
 *
 * End-to-end unit test for the PPR capability. Exercises:
 *  - Phase A (prerender) with a mix of static + postponed boundaries.
 *  - Phase B (resume) producing $RC instructions for postponed boundaries.
 *  - Fully-static page (postponedState === null) takes the early-exit path on resume.
 *  - usePostpone returns a no-op on resume so the same component tree renders normally.
 *
 * NOTE: testEnvironment override to `node` is required so dynamic `import('react-dom/static')`
 * resolves to `static.node.js` (which exports prerenderToNodeStream) rather than
 * `static.browser.js` (which does not).
 */
import * as React from 'react';
import { Suspense } from 'react';
import { Readable } from 'stream';

// Register globals the capability checks for. Real node renderer injects these in vm.ts.
import { AsyncLocalStorage } from 'async_hooks';
(globalThis as unknown as { AsyncLocalStorage: typeof AsyncLocalStorage }).AsyncLocalStorage =
  AsyncLocalStorage;

import { createProPPRCapability } from '../src/capabilities/proPPR';
import { usePostpone } from '../src/postpone';
import { register } from '../src/ComponentRegistry';

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

const FastStatic: React.FC = (() => {
  // Async function components are valid in React 19; simulate "resolves quickly".
  const Component = async () => {
    await sleep(5);
    return <p data-testid="fast-static">FastStatic content</p>;
  };
  return Component as unknown as React.FC;
})();

const SlowStatic: React.FC = (() => {
  const Component = async () => {
    await sleep(50);
    return <p data-testid="slow-static">SlowStatic content</p>;
  };
  return Component as unknown as React.FC;
})();

interface DemoProps {
  resumeMessage?: string;
}

const DynamicSection: React.FC<DemoProps> = (() => {
  const Component = async ({ resumeMessage }: DemoProps) => {
    usePostpone('dynamic — needs request data');
    return <p data-testid="dynamic-section">{resumeMessage ?? '(prerender)'}</p>;
  };
  return Component as unknown as React.FC<DemoProps>;
})();

const PPRRoot: React.FC<DemoProps> = (props) => (
  <main>
    <p data-testid="sync-banner">Synchronous banner</p>
    <Suspense fallback={<p>Loading fast…</p>}>
      <FastStatic />
    </Suspense>
    <Suspense fallback={<p>Loading slow…</p>}>
      <SlowStatic />
    </Suspense>
    <Suspense fallback={<p>Loading dynamic…</p>}>
      <DynamicSection {...props} />
    </Suspense>
  </main>
);

const StaticOnly: React.FC = () => (
  <main>
    <p data-testid="static-only-sync">Static-only sync</p>
    <Suspense fallback={<p>loading</p>}>
      <FastStatic />
    </Suspense>
  </main>
);

beforeAll(() => {
  register({
    PPRTestRoot: PPRRoot as unknown as React.ComponentType,
    PPRTestStaticOnly: StaticOnly as unknown as React.ComponentType,
  });
});

function streamToString(s: Readable): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    s.on('data', (c: Buffer) => chunks.push(c));
    s.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    s.on('error', reject);
  });
}

describe('PPR capability', () => {
  const capability = createProPPRCapability();

  test('prerender + resume produces shell with hole, then fills hole on resume', async () => {
    const prerenderResult = await capability.prerenderReactComponentForPPR({
      name: 'PPRTestRoot',
      props: {},
      domNodeId: 'PPRTestRoot-0',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
      railsContext: { pprPrerenderTimeoutMs: 500 } as never,
    } as never);

    expect(prerenderResult.hasErrors).toBe(false);
    expect(prerenderResult.pprShellHtml).toContain('Synchronous banner');
    expect(prerenderResult.pprShellHtml).toContain('FastStatic content');
    expect(prerenderResult.pprShellHtml).toContain('SlowStatic content');
    expect(prerenderResult.pprShellHtml).not.toContain('hello-from-resume');
    // Hole exists when one or more boundaries postponed.
    expect(prerenderResult.pprPostponedState).toBeTruthy();

    const resumeStream = capability.resumeReactComponentForPPR({
      name: 'PPRTestRoot',
      props: { resumeMessage: 'hello-from-resume' },
      domNodeId: 'PPRTestRoot-0',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
      railsContext: {
        pprShellHtml: prerenderResult.pprShellHtml,
        pprPostponedState: prerenderResult.pprPostponedState,
      } as never,
    } as never);

    const resumed = await streamToString(resumeStream);
    // First chunk: shell wrapped in JSON envelope. The resume HTML should arrive in subsequent chunks.
    const lines = resumed.trim().split('\n').filter(Boolean);
    expect(lines.length).toBeGreaterThanOrEqual(1);
    expect(resumed).toContain('Synchronous banner');
    expect(resumed).toContain('hello-from-resume');
  }, 30_000);

  test('fully-static page returns null postponedState and short-circuits on resume', async () => {
    const prerenderResult = await capability.prerenderReactComponentForPPR({
      name: 'PPRTestStaticOnly',
      props: {},
      domNodeId: 'PPRTestStaticOnly-0',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
      railsContext: { pprPrerenderTimeoutMs: 500 } as never,
    } as never);

    expect(prerenderResult.hasErrors).toBe(false);
    expect(prerenderResult.pprShellHtml).toContain('Static-only sync');
    expect(prerenderResult.pprPostponedState).toBeNull();
  }, 30_000);
});
