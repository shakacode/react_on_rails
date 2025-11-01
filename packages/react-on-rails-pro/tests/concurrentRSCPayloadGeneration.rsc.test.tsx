/**
 * @jest-environment node
 */
/// <reference types="react/experimental" />

import * as React from 'react';
import { Suspense, PropsWithChildren } from 'react';

import * as path from 'path';
import * as mock from 'mock-fs';

import ReactOnRails, { RailsContextWithServerStreamingCapabilities } from '../src/ReactOnRailsRSC.ts';
import AsyncQueue from './AsyncQueue.ts';
import StreamReader from './StreamReader.ts';
import removeRSCChunkStack from './utils/removeRSCChunkStack.ts';

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

afterEach(() => mock.restore());

const AsyncQueueItem = async ({
  asyncQueue,
  children,
}: PropsWithChildren<{ asyncQueue: AsyncQueue<string> }>) => {
  const value = await asyncQueue.dequeue();

  return (
    <>
      <p>Data: {value}</p>
      {children}
    </>
  );
};

const AsyncQueueContainer = ({ asyncQueue }: { asyncQueue: AsyncQueue<string> }) => {
  return (
    <div>
      <h1>Async Queue</h1>
      <Suspense fallback={<p>Loading Item1</p>}>
        <AsyncQueueItem asyncQueue={asyncQueue}>
          <Suspense fallback={<p>Loading Item2</p>}>
            <AsyncQueueItem asyncQueue={asyncQueue}>
              <Suspense fallback={<p>Loading Item3</p>}>
                <AsyncQueueItem asyncQueue={asyncQueue} />
              </Suspense>
            </AsyncQueueItem>
          </Suspense>
        </AsyncQueueItem>
      </Suspense>
    </div>
  );
};

ReactOnRails.register({ AsyncQueueContainer });

const renderComponent = (props: Record<string, unknown>) => {
  return ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {
      reactClientManifestFileName: 'react-client-manifest.json',
      reactServerClientManifestFileName: 'react-server-client-manifest.json',
    } as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'AsyncQueueContainer',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
    props,
  });
};

const createParallelRenders = (size: number) => {
  const asyncQueues = new Array(size).fill(null).map(() => new AsyncQueue<string>());
  const streams = asyncQueues.map((asyncQueue) => {
    return renderComponent({ asyncQueue });
  });
  const readers = streams.map((stream) => new StreamReader(stream));

  const enqueue = (value: string) => asyncQueues.forEach((asyncQueue) => asyncQueue.enqueue(value));

  const expectNextChunk = (nextChunk: string) =>
    Promise.all(
      readers.map(async (reader) => {
        const chunk = await reader.nextChunk();
        expect(removeRSCChunkStack(chunk)).toEqual(removeRSCChunkStack(nextChunk));
      }),
    );

  const expectEndOfStream = () =>
    Promise.all(readers.map((reader) => expect(reader.nextChunk()).rejects.toThrow(/Queue Ended/)));

  return { enqueue, expectNextChunk, expectEndOfStream };
};

test('Renders concurrent rsc streams as single rsc stream', async () => {
  expect.assertions(258);
  const asyncQueue = new AsyncQueue<string>();
  const stream = renderComponent({ asyncQueue });
  const reader = new StreamReader(stream);

  const chunks: string[] = [];
  let chunk = await reader.nextChunk();
  chunks.push(chunk);
  expect(chunk).toContain('Async Queue');
  expect(chunk).toContain('Loading Item2');
  expect(chunk).not.toContain('Random Value');

  asyncQueue.enqueue('Random Value1');
  chunk = await reader.nextChunk();
  chunks.push(chunk);
  expect(chunk).toContain('Random Value1');

  asyncQueue.enqueue('Random Value2');
  chunk = await reader.nextChunk();
  chunks.push(chunk);
  expect(chunk).toContain('Random Value2');

  asyncQueue.enqueue('Random Value3');
  chunk = await reader.nextChunk();
  chunks.push(chunk);
  expect(chunk).toContain('Random Value3');

  await expect(reader.nextChunk()).rejects.toThrow(/Queue Ended/);

  const { enqueue, expectNextChunk, expectEndOfStream } = createParallelRenders(50);

  expect(chunks).toHaveLength(4);
  await expectNextChunk(chunks[0]);
  enqueue('Random Value1');
  await expectNextChunk(chunks[1]);
  enqueue('Random Value2');
  await expectNextChunk(chunks[2]);
  enqueue('Random Value3');
  await expectNextChunk(chunks[3]);
  await expectEndOfStream();
});
