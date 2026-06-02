/**
 * @jest-environment node
 */

import * as fs from 'fs';
import * as path from 'path';

const repoRoot = path.resolve(__dirname, '../../..');
const dummyClientRoot = path.join(repoRoot, 'react_on_rails_pro/spec/dummy/client/app');
const componentsRoot = path.join(dummyClientRoot, 'components');
const autoLoadRoot = path.join(dummyClientRoot, 'ror-auto-load-components');

describe('refetch stress dummy app conventions', () => {
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
  });
});
