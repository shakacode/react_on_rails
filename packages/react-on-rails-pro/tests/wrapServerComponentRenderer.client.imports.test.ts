/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import * as fs from 'fs';
import * as path from 'path';

// Regression test for https://github.com/shakacode/react_on_rails/issues/3366
//
// `wrapServerComponentRenderer/client.tsx` MUST contain a top-level side-effect
// import of `react-on-rails-rsc/client.browser`. RSCWebpackPlugin walks the
// client bundle's module graph and only emits `react-client-manifest.json`
// when it parses a module whose resolved path equals the plugin's
// `require.resolve("../client.browser.js")`. Without a direct side-effect
// import, the plugin relies on the 3-level chain
// `wrapServerComponentRenderer/client` → `getReactServerComponent.client`
// → `react-on-rails-rsc/client.browser`, and any tooling that severs that
// chain (tree-shaking, transpiler quirks, custom replacers) silently drops
// the manifest, breaking RSC hydration on the Pro Node Renderer.
describe('wrapServerComponentRenderer/client.tsx side-effect imports', () => {
  it('keeps the react-on-rails-rsc/client.browser runtime in the client module graph', () => {
    const srcPath = path.join(__dirname, '..', 'src', 'wrapServerComponentRenderer', 'client.tsx');
    const source = fs.readFileSync(srcPath, 'utf8');

    expect(source).toMatch(/^\s*import\s+['"]react-on-rails-rsc\/client\.browser['"]\s*;?\s*$/m);
  });

  it('keeps the same runtime present in the compiled lib output', () => {
    const libPath = path.join(__dirname, '..', 'lib', 'wrapServerComponentRenderer', 'client.js');
    if (!fs.existsSync(libPath)) {
      // lib is only built before publish or after `pnpm run build`. Skip when
      // running tests from a fresh checkout without a prior build.
      return;
    }
    const compiled = fs.readFileSync(libPath, 'utf8');
    expect(compiled).toMatch(/import\s+['"]react-on-rails-rsc\/client\.browser['"]\s*;?/);
  });
});
