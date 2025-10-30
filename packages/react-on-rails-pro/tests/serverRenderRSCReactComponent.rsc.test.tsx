/**
 * @jest-environment node
 */

import * as React from 'react';
import { Suspense } from 'react';
import * as mock from 'mock-fs';
import * as fs from 'fs';
import * as path from 'path';
import { pipeline, finished } from 'stream/promises';
import { text } from 'stream/consumers';
import { buildServerRenderer } from 'react-on-rails-rsc/server.node';
import createReactOutput from 'react-on-rails/createReactOutput';
import ReactOnRails, { RailsContextWithServerStreamingCapabilities } from '../src/ReactOnRailsRSC.ts';

const PromiseWrapper = async ({ promise, name }: { promise: Promise<string>, name: string }) => {
  console.log(`[${name}] Before awaitng`);
  const value = await promise;
  console.log(`[${name}] After awaitng`);
  return (
    <p>Value: {value}</p>
  );
}

const PromiseContainer = ({ name }: { name: string }) => {
  const promise = new Promise<string>((resolve) => {
    let i = 0;
    const intervalId = setInterval(() => {
      console.log(`Interval ${i} at [${name}]`);
      i += 1;
      if (i === 50) {
        clearInterval(intervalId);
        resolve(`Value of name ${name}`);
      }
    }, 1);
  });

  return (
    <div>
      <h1>Initial Header</h1>
      <Suspense fallback={<p>Loading Promise</p>}>
        <PromiseWrapper name={name} promise={promise} />
      </Suspense>
    </div>
  );
}

ReactOnRails.register({ PromiseContainer });

const manifestFileDirectory = path.resolve(__dirname, '../src')
const clientManifestPath = path.join(manifestFileDirectory, 'react-client-manifest.json');

mock({
  [clientManifestPath]: JSON.stringify({
    filePathToModuleMetadata: {},
    moduleLoading: { prefix: '', crossOrigin: null },
  }),
});

afterAll(() => {
  mock.restore();
})

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
    props: { name: "First Unique Name" }
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
    props: { name: "Second Unique Name" }
  });

  const [content1, content2] = await Promise.all([text(readable1), text(readable2)]);

  expect(content1).toContain("First Unique Name");
  expect(content2).toContain("Second Unique Name");
  // expect(content1.match(/First Unique Name/g)).toHaveLength(55)
  // expect(content2.match(/Second Unique Name/g)).toHaveLength(55)
  expect(content1).not.toContain("Second Unique Name");
  expect(content2).not.toContain("First Unique Name");

  // expect(content1.replace(new RegExp("First Unique Name", 'g'), "Second Unique Name")).toEqual(content2);
})
