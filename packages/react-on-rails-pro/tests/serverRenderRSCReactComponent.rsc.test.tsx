/**
 * @jest-environment node
 */
/// <reference types="react/experimental" />

import * as React from 'react';
import { Suspense } from 'react';
import * as mock from 'mock-fs';
import * as path from 'path';
import { finished } from 'stream/promises';
import { text } from 'stream/consumers';
import ReactOnRails, { RailsContextWithServerStreamingCapabilities } from '../src/ReactOnRailsRSC.ts';

const PromiseWrapper = async ({ promise, name, onResolved }: { promise: Promise<string>; name: string, onResolved?: () => {} }) => {
  console.log(`[${name}] Before awaitng`);
  const value = await promise;
  if (onResolved) {
    onResolved();
  }
  console.log(`[${name}] After awaitng`);
  return <p>Value: {value}</p>;
};

const PromiseContainer = ({ name, onResolved, tick }: { name: string, onResolved?: () => {}, tick?: () => {} }) => {
  const promise = new Promise<string>((resolve) => {
    let i = 0;
    setTimeout(() => {
      const intervalId = setInterval(() => {
        console.log(`Interval ${i} at [${name}]`);
        i += 1;
        tick?.();
        if (i === 50) {
          clearInterval(intervalId);
          resolve(`Value of name ${name}`);
        }
      }, 20);
    }, 0);
  });

  return (
    <div>
      <h1>Initial Header</h1>
      <Suspense fallback={<p>Loading Promise</p>}>
        <PromiseWrapper name={name} promise={promise} onResolved={onResolved} />
      </Suspense>
    </div>
  );
};

ReactOnRails.register({ PromiseContainer });

const manifestFileDirectory = path.resolve(__dirname, '../src');
const clientManifestPath = path.join(manifestFileDirectory, 'react-client-manifest.json');

beforeEach(() => {
  mock({
    [clientManifestPath]: JSON.stringify({
      filePathToModuleMetadata: {},
      moduleLoading: { prefix: '', crossOrigin: null },
    }),
  });
});

afterEach(() => {
  mock.restore();
});

test('no logs leakage between concurrent rendering components', async () => {
  const readable1 = ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {
      reactClientManifestFileName: 'react-client-manifest.json',
      reactServerClientManifestFileName: 'react-server-client-manifest.json',
    } as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'PromiseContainer',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
    props: { name: 'First Unique Name' },
  });
  const readable2 = ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {
      reactClientManifestFileName: 'react-client-manifest.json',
      reactServerClientManifestFileName: 'react-server-client-manifest.json',
    } as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'PromiseContainer',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
    props: { name: 'Second Unique Name' },
  });

  const [content1, content2] = await Promise.all([text(readable1), text(readable2)]);

  expect(content1).toContain('First Unique Name');
  expect(content2).toContain('Second Unique Name');
  expect(content1).not.toContain('Second Unique Name');
  expect(content2).not.toContain('First Unique Name');
});

test('no logs lekage from outside the component', async () => {
  const readable1 = ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {
      reactClientManifestFileName: 'react-client-manifest.json',
      reactServerClientManifestFileName: 'react-server-client-manifest.json',
    } as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'PromiseContainer',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
    props: { name: 'First Unique Name' },
  });

  const promise = new Promise<void>((resolve) => {
    let i = 0;
    const intervalId = setInterval(() => {
      console.log(`Interval ${i} at [Outside The Component]`);
      i += 1;
      if (i === 50) {
        clearInterval(intervalId);
        resolve();
      }
    }, 1);
  });

  const [content1] = await Promise.all([text(readable1), promise]);

  expect(content1).toContain('First Unique Name');
  expect(content1).not.toContain('Outside The Component');
});

test('[bug] catches logs outside the component during reading the stream', async () => {
  let resolved = false;
  let executedIntervals = 0;
  const readable1 = ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {
      reactClientManifestFileName: 'react-client-manifest.json',
      reactServerClientManifestFileName: 'react-server-client-manifest.json',
    } as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'PromiseContainer',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
    props: { name: 'Bug Investigation Name', onResolved: () => { resolved = true; }, tick: () => { executedIntervals += 1 } },
  });

  let content1 = '';
  let i = 0;
  let j = 0;
  readable1.on('data', (chunk: Buffer) => {
    i += 1;
    if (i === 1) {
      expect(resolved).toBe(false);
    }
    // To avoid infinite loop
    if (executedIntervals > 0 && j < 5) {
      j += 1;
      console.log('Outside The Component');
      console.log(`Interval Count: ${executedIntervals}`);
    }
    content1 += chunk.toString();
  });

  // However, any logs from outside the stream 'data' event callback is not catched
  const intervalId = setInterval(() => {
    console.log('From Interval');
  }, 2);
  await finished(readable1);
  clearInterval(intervalId);
  expect(resolved).toBe(true);

  expect(content1).toContain('Bug Investigation Name');
  expect(content1).not.toContain('From Interval');
  // Here's the bug
  expect(content1).toContain('Outside The Component');
}, 10000);
