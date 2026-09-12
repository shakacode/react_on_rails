import assert from 'node:assert/strict';
import test from 'node:test';
import {
  addCompileError,
  addRuntimeError,
  buildOverlayReport,
  compileErrorMarker,
  parseEditorInvocation,
  runtimeErrorMarker,
  sourceLocationVisible,
} from './overlay-helpers.mjs';

test('compile probe reports the appended source line', () => {
  const probe = addCompileError('const valid = true;\n');
  assert.equal(probe.line, 2);
  assert.match(probe.source, new RegExp(compileErrorMarker));
});

test('runtime probe inserts a deterministic throw and reports its line', () => {
  const probe = addRuntimeError('header\nconst HelloWorld = () => {\n  return null;\n};\n', 'rspack');
  assert.equal(probe.line, 3);
  assert.match(probe.source, new RegExp(runtimeErrorMarker));
});

test('source location accepts an original path and line but rejects a generated frame', () => {
  const relativePath = 'app/frontend/pages/inertia_example/index.tsx';
  assert.equal(sourceLocationVisible(`${relativePath}:17:9`, relativePath, 17), true);
  assert.equal(sourceLocationVisible('assets/application.js:17:9', relativePath, 17), false);
  assert.equal(sourceLocationVisible(`${relativePath}:18:9`, relativePath, 17), false);
});

test('editor invocation must contain the exact workspace source, line, and column', () => {
  const workspace = '/tmp/overlay/vite';
  const source = `${workspace}/app/frontend/pages/index.tsx`;
  assert.deepEqual(parseEditorInvocation([`${source}:12:7`], workspace, source), {
    file: 'app/frontend/pages/index.tsx',
    line: 12,
    column: 7,
  });
  assert.deepEqual(parseEditorInvocation([source, '12', '7'], workspace, source), {
    file: 'app/frontend/pages/index.tsx',
    line: 12,
    column: 7,
  });
  assert.equal(parseEditorInvocation(['/other/index.tsx:12:7'], workspace, source), undefined);
});

test('report renders all measured matrix cells', () => {
  const raw = {
    created_at: '2026-09-11T00:00:00.000Z',
    environment: {
      harness_git_head: 'abc',
      harness_git_clean: true,
      operating_system: 'test',
      cpu: 'test',
      logical_cpu_count: 1,
      node: 'v22',
      pnpm: '10',
      ruby: 'ruby',
      dependencies: {
        rspack_ruby: 'react_on_rails 17',
        rspack_javascript: 'rspack 2',
        vite_ruby: 'vite_rails 3',
        vite_javascript: 'vite 8',
      },
    },
    results: {
      rspack: {
        compile_overlay: { status: 'PASS' },
        runtime_overlay: { status: 'PASS' },
        click_to_editor: { status: 'PASS' },
      },
      vite: {
        compile_overlay: { status: 'PASS' },
        runtime_overlay: { status: 'FAIL' },
        click_to_editor: { status: 'PASS' },
      },
    },
  };
  assert.match(buildOverlayReport(raw), /Inertia Rails \+ Vite \| PASS \| FAIL \| PASS/);
});
