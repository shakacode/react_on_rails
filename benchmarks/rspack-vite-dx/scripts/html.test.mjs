import assert from 'node:assert/strict';
import test from 'node:test';
import { assertExactlyOneEntry } from './html.mjs';

test('accepts one generated Rspack entry', () => {
  assert.doesNotThrow(() => assertExactlyOneEntry('<script defer src="/main.js"></script>', 'rspack'));
});

test('rejects duplicate Rspack entry injection', () => {
  const duplicated = '<script src="/main.js"></script><script defer src="/main.js"></script>';
  assert.throws(() => assertExactlyOneEntry(duplicated, 'rspack'), /found 2/);
});

test('accepts the Vite entry alongside its runtime client', () => {
  const html =
    '<script type="module" src="/@vite/client"></script><script type="module" src="/src/index.js"></script>';
  assert.doesNotThrow(() => assertExactlyOneEntry(html, 'vite'));
});
