import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { LICENSE_MARKER, SENTINEL, findMissingHeaders } from './check-pro-package-license-headers.mjs';

test('reports packed .js files without the sentinel', () => {
  const files = [
    {
      path: 'package/lib/ok.js',
      content: `/*\n * This file is ${SENTINEL} license.\n * ${LICENSE_MARKER}\n */\n`,
    },
    { path: 'package/lib/dropped.js', content: 'import { jsx as _jsx } from "react/jsx-runtime";\n' },
    { path: 'package/lib/types.d.ts', content: 'export {};\n' },
    { path: 'package/package.json', content: '{}' },
  ];

  assert.deepEqual(findMissingHeaders(files), ['package/lib/dropped.js']);
});

test('sentinel matches the source header checker', () => {
  const sourceChecker = readFileSync(new URL('./check-pro-license-headers', import.meta.url), 'utf8');
  assert.match(sourceChecker, new RegExp(`SENTINEL = "${SENTINEL}"`));
  assert.ok(sourceChecker.includes(LICENSE_MARKER));
});

test('rejects an earlier Pro header without free use wording', () => {
  const files = [{ path: 'package/lib/old.js', content: `/* This file is ${SENTINEL} license. */` }];

  assert.deepEqual(findMissingHeaders(files), ['package/lib/old.js']);
});
