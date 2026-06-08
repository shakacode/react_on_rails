/**
 * @jest-environment node
 */

import * as fs from 'fs';
import * as path from 'path';

const repoRoot = path.resolve(__dirname, '../../..');
const proPackageJsonPath = path.join(repoRoot, 'packages/react-on-rails-pro/package.json');
const dummyClientRoot = path.join(repoRoot, 'react_on_rails_pro/spec/dummy/client/app');
const componentsRoot = path.join(dummyClientRoot, 'components');
const autoLoadRoot = path.join(dummyClientRoot, 'ror-auto-load-components');

describe('refetch stress dummy app conventions', () => {
  it('publishes declaration paths for Pro subpath imports used by the dummy app', () => {
    const proPackageJson = JSON.parse(fs.readFileSync(proPackageJsonPath, 'utf8'));

    expect(proPackageJson.exports['./RSCRoute']).toEqual({
      types: './lib/RSCRoute.d.ts',
      default: './lib/RSCRoute.js',
    });
    expect(proPackageJson.exports['./rscPayloadNode']).toEqual({
      types: './lib/createRscPayloadNode.client.d.ts',
      'react-server': './lib/createRscPayloadNode.server.js',
      node: {
        types: './lib/createRscPayloadNode.server.d.ts',
        default: './lib/createRscPayloadNode.server.js',
      },
      default: './lib/createRscPayloadNode.client.js',
    });
  });

  it('keeps the rscPayloadNode server export browser-runtime free', async () => {
    const { createRscPayloadNode } = await import('../src/createRscPayloadNode.server.ts');

    await expect(
      createRscPayloadNode({
        componentName: 'DashboardPanel',
        payloadPath: '/rsc_payload',
      }),
    ).rejects.toThrow(
      'createRscPayloadNode is browser-only. Use it only from client-only route loaders or set ssr: false for the route.',
    );
  });

  it('keeps client-only helpers behind .client.tsx file suffixes', () => {
    expect(fs.existsSync(path.join(componentsRoot, 'RefetchStressPage.client.tsx'))).toBe(true);
    expect(fs.existsSync(path.join(componentsRoot, 'InlineRefreshButton.client.tsx'))).toBe(true);
    expect(fs.existsSync(path.join(componentsRoot, 'RefetchStressPage.tsx'))).toBe(false);
    expect(fs.existsSync(path.join(componentsRoot, 'InlineRefreshButton.tsx'))).toBe(false);

    const routerSource = fs.readFileSync(path.join(componentsRoot, 'ServerComponentRouter.tsx'), 'utf8');
    expect(routerSource).toContain("import RefetchStressPage from './RefetchStressPage.client';");

    const serverComponentSource = fs.readFileSync(
      path.join(autoLoadRoot, 'RefetchStressServerComponent.jsx'),
      'utf8',
    );
    expect(serverComponentSource).toContain(
      "import InlineRefreshButton from '../components/InlineRefreshButton.client';",
    );

    const inlineRefreshSource = fs.readFileSync(
      path.join(componentsRoot, 'InlineRefreshButton.client.tsx'),
      'utf8',
    );
    expect(inlineRefreshSource).toContain('React.useTransition()');
    expect(inlineRefreshSource).toContain("isPending ? 'Refreshing…' : label");
  });
});
