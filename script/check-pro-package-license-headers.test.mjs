import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { SENTINEL, findMissingHeaders } from './check-pro-package-license-headers.mjs';

test('reports packed .js files without the sentinel', () => {
  const files = [
    { path: 'package/lib/ok.js', content: `/*\n * This file is ${SENTINEL} (open source) license.\n */\n` },
    { path: 'package/lib/dropped.js', content: 'import { jsx as _jsx } from "react/jsx-runtime";\n' },
    { path: 'package/lib/types.d.ts', content: 'export {};\n' },
    { path: 'package/package.json', content: '{}' },
  ];

  assert.deepEqual(findMissingHeaders(files), ['package/lib/dropped.js']);
});

test('sentinel matches the source header checker', () => {
  const sourceChecker = readFileSync(new URL('./check-pro-license-headers', import.meta.url), 'utf8');
  assert.match(sourceChecker, new RegExp(`SENTINEL = "${SENTINEL}"`));
});
