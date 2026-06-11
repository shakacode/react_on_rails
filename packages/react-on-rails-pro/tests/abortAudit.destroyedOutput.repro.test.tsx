/**
 * @jest-environment node
 */

/*
 * THROWAWAY REPRO for issue #3885 abort-path audit (report-only; not meant to be merged).
 *
 * Question under test: when the output Readable returned by
 * streamServerRenderedReactComponent is destroyed mid-render (this is what
 * Fastify does to the response payload stream when the HTTP client
 * disconnects), does the in-flight React render (renderToPipeableStream)
 * get aborted, or does it keep rendering?
 *
 * Evidence is a timestamped render log: each Suspense level of the test
 * component records when its body executes. Levels deeper than the point of
 * destruction can only execute if React kept driving the render afterwards.
 */

import * as React from 'react';
import streamServerRenderedReactComponent from '../src/streamServerRenderedReactComponent.ts';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';

const LEVEL_DELAY_MS = 300;
const TOP_LEVEL = 5;

type LogEntry = { t: number; msg: string };
const renderLog: LogEntry[] = [];
const logEvent = (msg: string) => renderLog.push({ t: Date.now(), msg });

const testingRailsContext = {
  serverSideRSCPayloadParameters: {},
  reactClientManifestFileName: 'clientManifest.json',
  reactServerClientManifestFileName: 'serverClientManifest.json',
  componentSpecificMetadata: {
    renderRequestId: 'abort-audit',
  },
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
} as any;

// Mirrors AsyncComponentsTreeForTesting in the Pro dummy app: each level is a
// component that returns a Promise resolving (after a delay) to JSX containing
// a Suspense boundary around the next level. React only executes level N-1's
// body after level N's promise resolves AND React re-renders the boundary —
// so log entries are proof of React render progress, not just timers firing.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const AsyncBranch = ({ level }: { level: number }): any => {
  return new Promise((resolve) => {
    setTimeout(() => {
      logEvent(`level ${level} body executed`);
      if (level === 0) {
        resolve(React.createElement('div', null, 'leaf reached'));
        return;
      }
      resolve(
        React.createElement(
          'div',
          null,
          React.createElement('p', null, `level ${level}`),
          React.createElement(
            React.Suspense,
            { fallback: React.createElement('div', null, `loading ${level - 1}`) },
            React.createElement(AsyncBranch, { level: level - 1 }),
          ),
        ),
      );
    }, LEVEL_DELAY_MS);
  });
};

const TreeRoot = () =>
  React.createElement(
    'div',
    null,
    React.createElement('p', null, 'shell header'),
    React.createElement(
      React.Suspense,
      { fallback: React.createElement('div', null, 'loading top') },
      React.createElement(AsyncBranch, { level: TOP_LEVEL }),
    ),
  );

const sleep = (ms: number) =>
  new Promise<void>((resolve) => {
    setTimeout(resolve, ms);
  });

describe('abort audit: destroying the output stream mid-render', () => {
  beforeEach(() => {
    ComponentRegistry.clear();
    renderLog.length = 0;
  });

  it('shows whether React render continues after the consumer destroys the stream', async () => {
    ComponentRegistry.register({ TreeRoot });

    const stream = streamServerRenderedReactComponent({
      name: 'TreeRoot',
      domNodeId: 'tree-root-node',
      trace: false,
      props: {},
      throwJsErrors: false,
      railsContext: testingRailsContext,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any);

    let destroyedAt = 0;
    const receivedChunks: LogEntry[] = [];

    await new Promise<void>((resolve) => {
      stream.on('data', (chunk: Buffer) => {
        receivedChunks.push({ t: Date.now(), msg: `chunk len=${chunk.length}` });
        if (!destroyedAt) {
          // Simulate what Fastify does on client disconnect: destroy the
          // response payload stream after the first (shell) chunk arrives.
          destroyedAt = Date.now();
          logEvent('>>> output stream destroyed (simulated client disconnect)');
          stream.destroy();
          resolve();
        }
      });
      stream.on('error', () => {});
      stream.on('close', () => resolve());
    });

    // Give the (potentially still running) render plenty of time to finish.
    await sleep((TOP_LEVEL + 2) * LEVEL_DELAY_MS + 500);

    const entriesAfterDestroy = renderLog.filter(
      (entry) => entry.t > destroyedAt && entry.msg.includes('body executed'),
    );
    const leafReached = renderLog.some((entry) => entry.msg.includes('level 0 body executed'));

    // Human-readable timeline for the audit report (console is disabled in
    // jest.setup.js, so write straight to stdout).
    const base = renderLog[0]?.t ?? destroyedAt;
    process.stdout.write(
      ['--- abort audit timeline (ms after first log) ---']
        .concat(renderLog.map((entry) => `+${entry.t - base}ms ${entry.msg}`))
        .concat([
          `chunks received: ${receivedChunks.length}`,
          `render levels executed AFTER destroy: ${entriesAfterDestroy.length}`,
          `leaf (level 0) reached: ${leafReached}`,
        ])
        .join('\n')
        .concat('\n'),
    );

    // The audit's factual finding: if these pass, the render LEAKS (keeps
    // running to completion after the consumer is gone).
    expect(entriesAfterDestroy.length).toBeGreaterThan(0);
    expect(leafReached).toBe(true);
  }, 15000);
});
