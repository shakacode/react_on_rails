import * as mock from 'mock-fs';
import * as fs from 'fs';
import ReactOnRails, { RailsContextWithServerStreamingCapabilities } from '../src/ReactOnRailsRSC.ts';

const Component1 = () => <div>HelloWorld</div>;

ReactOnRails.register({ Component1 });

mock({
  'server/react-client-manifest.json': '{}'
});

afterAll(() => {
  mock.restore();
})

test('eeee', () => {
  expect(fs.readFileSync('./server/react-client-manifest.json').toString()).toEqual('{}');
  ReactOnRails.serverRenderRSCReactComponent({
    railsContext: {} as unknown as RailsContextWithServerStreamingCapabilities,
    name: 'Component1',
    reactClientManifestFileName: 'react-client-manifest.json',
    renderingReturnsPromises: true,
    throwJsErrors: true,
    domNodeId: 'dom-id',
  })
})
