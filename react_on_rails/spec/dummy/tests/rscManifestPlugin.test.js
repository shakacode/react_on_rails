/**
 * Unit tests for the pure logic inside the generated `rscManifestPlugin.js`
 * helper (`rscManifestPlugin.js.tt`).
 *
 * The helper ships as a Thor template but contains no ERB, so it is valid
 * CommonJS. Its trickiest branches — glob → RegExp translation (including
 * brace alternation and bracket expressions), the `'use client'` directive
 * scanner, and the chunk-pair merge — were previously validated only with
 * throwaway `node` probes. These tests load the template directly and lock
 * that behavior in so it is regression-tested in CI.
 *
 * See the PR #3385 review:
 * https://github.com/shakacode/react_on_rails/pull/3385#issuecomment-4565058647
 */
const fs = require('fs');
const path = require('path');
const Module = require('module');

const TEMPLATE_PATH = path.resolve(
  __dirname,
  '../../../lib/generators/react_on_rails/templates/base/base/config/webpack/rscManifestPlugin.js.tt',
);

// `rscManifestPlugin.js.tt` eagerly requires `shakapacker` at load time, but
// only touches it at config-evaluation time — code these tests never call — and
// it is not installed in the dummy app. Stub it so the template loads
// hermetically; Node's built-ins (fs/path/url) resolve normally.
const moduleStubs = {
  shakapacker: { config: {} },
};

// Only `addRSCManifestPlugin` is exported, to keep the generated file's public
// surface small. Rather than shipping test-only exports into every generated
// app, compile the ERB-free template as a CommonJS module here and expose the
// module-private helpers under test.
/* eslint-disable no-underscore-dangle -- _compile/_nodeModulePaths are the CommonJS loader primitives */
function loadHelperInternals() {
  const source = fs.readFileSync(TEMPLATE_PATH, 'utf8');
  const body = [
    source,
    'module.exports.testInternals = {',
    '  globToRegExp,',
    '  splitBraceAlternatives,',
    '  hasUseClientDirective,',
    '  globBaseDirectory,',
    '  mergeChunkPairsInPlace,',
    '  normalizeCrossOrigin,',
    '};',
  ].join('\n');

  const helperModule = new Module(TEMPLATE_PATH, module);
  helperModule.filename = TEMPLATE_PATH;
  helperModule.paths = Module._nodeModulePaths(path.dirname(TEMPLATE_PATH));

  const nodeRequire = helperModule.require.bind(helperModule);
  helperModule.require = (request) => {
    if (Object.prototype.hasOwnProperty.call(moduleStubs, request)) {
      return moduleStubs[request];
    }
    return nodeRequire(request);
  };

  helperModule._compile(body, TEMPLATE_PATH);
  return helperModule.exports.testInternals;
}
/* eslint-enable no-underscore-dangle */

const {
  globToRegExp,
  splitBraceAlternatives,
  hasUseClientDirective,
  globBaseDirectory,
  mergeChunkPairsInPlace,
  normalizeCrossOrigin,
} = loadHelperInternals();

describe('rscManifestPlugin helper', () => {
  describe('globToRegExp', () => {
    describe('wildcards', () => {
      test.each([
        ['*.js', 'foo.js', true],
        ['*.js', 'foo.ts', false],
        // A single `*` never crosses a path separator.
        ['*.js', 'dir/foo.js', false],
        ['**/*.js', 'foo.js', true],
        ['**/*.js', 'a/b/foo.js', true],
        ['src/**', 'src/a/b.js', true],
        ['src/**', 'other/a.js', false],
        // `?` matches exactly one non-separator character.
        ['a?c.js', 'abc.js', true],
        ['a?c.js', 'ac.js', false],
        ['a?c.js', 'a/c.js', false],
      ])('%s matches %j -> %s', (pattern, input, expected) => {
        expect(globToRegExp(pattern).test(input)).toBe(expected);
      });
    });

    describe('brace alternation', () => {
      test.each([
        ['*.{js,jsx}', 'a.js', true],
        ['*.{js,jsx}', 'a.jsx', true],
        ['*.{js,jsx}', 'a.ts', false],
        ['{a,b,c}.js', 'b.js', true],
        ['{a,b,c}.js', 'd.js', false],
        // Nested braces.
        ['{a,{b,c}}.js', 'c.js', true],
        ['{a,{b,c}}.js', 'd.js', false],
      ])('%s matches %j -> %s', (pattern, input, expected) => {
        expect(globToRegExp(pattern).test(input)).toBe(expected);
      });

      test('treats an unmatched opening brace as a literal', () => {
        // With no closing brace the `{` falls through and is matched literally.
        expect(globToRegExp('{a.js').test('{a.js')).toBe(true);
        expect(globToRegExp('{a.js').test('a.js')).toBe(false);
      });
    });

    describe('bracket expressions', () => {
      test.each([
        ['file[0-9].js', 'file3.js', true],
        ['file[0-9].js', 'fileX.js', false],
        ['file[0-9].js', 'file12.js', false],
        // `!` negation (glob form).
        ['file[!0-9].js', 'fileX.js', true],
        ['file[!0-9].js', 'file3.js', false],
        // `^` negation (regex form) is also honored.
        ['file[^0-9].js', 'fileX.js', true],
        ['file[^0-9].js', 'file3.js', false],
      ])('%s matches %j -> %s', (pattern, input, expected) => {
        expect(globToRegExp(pattern).test(input)).toBe(expected);
      });

      test('treats a leading `]` inside a bracket as a literal member', () => {
        // `[]]` is a class containing `]`: the `]` immediately after `[` is literal.
        const regex = globToRegExp('[]].js');
        expect(regex.test('].js')).toBe(true);
        expect(regex.test('a.js')).toBe(false);
      });
    });
  });

  describe('splitBraceAlternatives', () => {
    test('splits on top-level commas only', () => {
      expect(splitBraceAlternatives('js,jsx,ts')).toEqual(['js', 'jsx', 'ts']);
    });

    test('does not split commas nested inside inner braces', () => {
      expect(splitBraceAlternatives('a,{b,c},d')).toEqual(['a', '{b,c}', 'd']);
    });

    test('returns a single element when there are no commas', () => {
      expect(splitBraceAlternatives('js')).toEqual(['js']);
    });
  });

  describe('hasUseClientDirective', () => {
    test.each([
      ["'use client';\nexport const x = 1;", true],
      ['"use client";\n', true],
      // Leading comments are skipped.
      ["// a comment\n'use client';", true],
      ['/* a block comment */\n"use client";', true],
      // The directive may follow other directives in the prologue.
      ["'use strict';\n'use client';", true],
      // A trailing line or block comment after the directive is tolerated.
      ["'use client' // legacy compat", true],
      ["'use client' // legacy compat\nexport {};", true],
      ["'use client' /* note */;", true],
      // A trailing comment on an earlier directive must not break the scan.
      ["'use strict' // first\n'use client';", true],
      // A leading byte-order mark is ignored.
      ["﻿'use client';", true],
      // Anything other than a string-literal directive ends the prologue.
      ["import x from 'y';\n'use client';", false],
      ["const x = 1;\n'use client';", false],
      ['export default function () {}', false],
      ['// only a comment', false],
      ['', false],
    ])('%j -> %s', (source, expected) => {
      expect(hasUseClientDirective(source)).toBe(expected);
    });
  });

  describe('mergeChunkPairsInPlace', () => {
    test('appends new [id, file] pairs', () => {
      const existing = [1, 'a.js'];
      mergeChunkPairsInPlace(existing, [2, 'b.js']);
      expect(existing).toEqual([1, 'a.js', 2, 'b.js']);
    });

    test('skips chunk ids already present', () => {
      const existing = [1, 'a.js'];
      mergeChunkPairsInPlace(existing, [1, 'other.js', 2, 'b.js']);
      expect(existing).toEqual([1, 'a.js', 2, 'b.js']);
    });

    test('does not mutate the additions array', () => {
      const additions = [2, 'b.js'];
      mergeChunkPairsInPlace([1, 'a.js'], additions);
      expect(additions).toEqual([2, 'b.js']);
    });

    test('handles empty additions', () => {
      const existing = [1, 'a.js'];
      mergeChunkPairsInPlace(existing, []);
      expect(existing).toEqual([1, 'a.js']);
    });
  });

  describe('normalizeCrossOrigin', () => {
    test.each([
      ['anonymous', 'anonymous'],
      ['use-credentials', 'use-credentials'],
    ])('passes through the supported value %s', (input, expected) => {
      expect(normalizeCrossOrigin(input)).toEqual({ value: expected });
    });

    test('narrows non-string values to null', () => {
      expect(normalizeCrossOrigin(true)).toEqual({ value: null });
      expect(normalizeCrossOrigin(undefined)).toEqual({ value: null });
    });

    test('falls back to anonymous with a warning for unsupported strings', () => {
      const result = normalizeCrossOrigin('bogus');
      expect(result.value).toBe('anonymous');
      expect(result.warning).toEqual(expect.stringContaining("'bogus'"));
    });
  });

  describe('globBaseDirectory', () => {
    // The production-throw vs dev-warn branch is environment-dependent and reads
    // `process.env.NODE_ENV`/`console` from the helper's own realm, which the
    // Module._compile harness here does not share. That branch is locked instead by
    // the generator spec (rsc_generator_spec.rb asserts the production-throw and
    // dev-warn strings are emitted). Here we cover the realm-independent base split.
    test('returns the static prefix before the first glob segment', () => {
      expect(globBaseDirectory('/root', 'app/javascript/**/*.client.jsx')).toBe(
        path.resolve('/root/app/javascript'),
      );
    });

    test('keeps a fully static path intact', () => {
      expect(globBaseDirectory('/root', 'app/javascript/packs')).toBe(
        path.resolve('/root/app/javascript/packs'),
      );
    });
  });
});
