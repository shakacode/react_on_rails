/**
 * @jest-environment node
 */

import * as mock from 'mock-fs';
import * as fs from 'fs';
import * as path from 'path';
import { pipeline, finished } from 'stream';
import ReactOnRails, { RailsContextWithServerStreamingCapabilities } from '../src/ReactOnRailsRSC.ts';

const Component1 = () => <div>HelloWorld</div>;

ReactOnRails.register({ Component1 });

mock({
  './src/react-client-manifest.json': '{}'
});

afterAll(() => {
  mock.restore();
})

test('eeee', async () => {
  console.log(path.resolve('./src/react-client-manifest.json'));
  expect(fs.readFileSync('./src/react-client-manifest.json').toString()).toEqual('{}');
  const readable = ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {
      reactClientManifestFileName: 'react-client-manifest.json',
      reactServerClientManifestFileName: 'react-server-client-manifest.json',
    } as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'Component1',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
  });

  const decoder = new TextDecoder();
  readable.on('data', chunk => {
    console.log(decoder.decode(chunk));
  })
  await new Promise((resolve, reject) => {
    readable.on('end', resolve);
    readable.on('error', reject);
  })
}, 100000)
