import assert from 'node:assert/strict';
import test from 'node:test';
import {
  addCompileError,
  addRuntimeError,
  buildOverlayReport,
  compileErrorMarker,
  parseEditorInvocation,
  replaceBenchmarkMarker,
  restorationVisible,
  readOverlayText,
  runtimeErrorMarker,
  sourceLocationVisible,
  sourceLinkPattern,
  waitForSourceOverlay,
} from './overlay-helpers.mjs';

test('compile probe reports the appended source line', () => {
  const rspackProbe = addCompileError('const valid = true;\n', 'rspack');
  const viteProbe = addCompileError('const valid = true;\n', 'vite');
  assert.equal(rspackProbe.line, 2);
  assert.equal(rspackProbe.column, 36);
  assert.equal(viteProbe.column, 37);
  assert.match(rspackProbe.source, new RegExp(compileErrorMarker));
});

test('runtime probe inserts a deterministic throw and reports its line', () => {
  const probe = addRuntimeError('header\nconst HelloWorld = () => {\n  return null;\n};\n', 'rspack');
  assert.equal(probe.line, 3);
  assert.match(probe.source, new RegExp(runtimeErrorMarker));
});

test('source location accepts an original path and line but rejects a generated frame', () => {
  const relativePath = 'app/frontend/pages/inertia_example/index.tsx';
  assert.equal(sourceLocationVisible(`${relativePath}:17:9`, relativePath, 17), true);
  assert.equal(sourceLocationVisible(`${relativePath} ╭─[17:9]`, relativePath, 17), true);
  assert.equal(sourceLocationVisible('assets/application.js:17:9', relativePath, 17), false);
  assert.equal(sourceLocationVisible('/tmp/other/index.tsx:17:9', relativePath, 17), false);
  assert.equal(sourceLocationVisible(`${relativePath} mentioned; node.js:17:9`, relativePath, 17), false);
  assert.equal(sourceLocationVisible(`${relativePath}:18:9`, relativePath, 17), false);
  assert.equal(
    sourceLocationVisible(
      `${relativePath} mentioned without a frame; ${'x'.repeat(450)} ${relativePath} ╭─[17:9]`,
      relativePath,
      17,
    ),
    true,
  );
});

test('source location rejects path substrings and unrelated code frames', () => {
  const source = 'app/frontend/pages/inertia_example/index.tsx';
  assert.equal(sourceLocationVisible(`other-${source}:17:9`, source, 17), false);
  assert.equal(sourceLocationVisible(`${source}.backup:17:9`, source, 17), false);
  assert.equal(sourceLocationVisible(`${source} mentioned; unrelated.js ╭─[17:9]`, source, 17), false);
  assert.equal(sourceLocationVisible(`/workspace/${source}:17:9`, source, 17), true);
  assert.equal(
    sourceLocationVisible(
      `./${source} × Module build failed (from builtin:swc-loader):\n ╰─▶ × Syntax Error: Expression expected\n ╭─[17:9]`,
      source,
      17,
    ),
    true,
  );
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
  assert.equal(parseEditorInvocation([`builtin:swc-loader!${source}:12:7`], workspace, source), undefined);
  assert.equal(parseEditorInvocation([`${source}:12:7.backup`], workspace, source), undefined);
});

test('restoration health marker must replace an existing benchmark marker', () => {
  assert.equal(
    replaceBenchmarkMarker("const BENCHMARK_MARKER = 'old';\n", 'recovered'),
    "const BENCHMARK_MARKER = 'recovered';\n",
  );
  assert.throws(() => replaceBenchmarkMarker('const other = true;\n', 'recovered'), /was not found/);
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
        source_restoration: { status: 'PASS' },
      },
      vite: {
        compile_overlay: { status: 'PASS' },
        runtime_overlay: { status: 'FAIL' },
        click_to_editor: { status: 'PASS' },
        source_restoration: { status: 'PASS' },
      },
    },
  };
  assert.match(buildOverlayReport(raw), /Inertia Rails \+ Vite \| PASS \| FAIL \| PASS \| PASS/);
});

test('editor target uses the full source path rather than a shared basename', () => {
  const pattern = sourceLinkPattern('app/frontend/pages/inertia_example/index.tsx');
  assert.equal(pattern.test('file:///workspace/node_modules/example/index.tsx:17:9'), false);
  assert.equal(pattern.test('app/frontend/pages/inertia_example/index.tsx.backup:17:9'), false);
  assert.equal(pattern.test('file:///workspace/app/frontend/pages/inertia_example/index.tsx:17:9'), true);
});

test('overlay polling waits for a source frame after the marker appears', async () => {
  const source = 'app/frontend/pages/inertia_example/index.tsx';
  let reads = 0;
  const frame = `${compileErrorMarker} ${source}:17:9`;
  const text = await waitForSourceOverlay(
    async () => (++reads === 1 ? undefined : reads === 2 ? compileErrorMarker : frame),
    compileErrorMarker,
    source,
    17,
    1000,
    0,
  );
  assert.equal(text, frame);
  assert.equal(reads, 3);
});

test('overlay polling retains matching evidence when its source frame never arrives', async () => {
  const text = await waitForSourceOverlay(
    async () => compileErrorMarker,
    compileErrorMarker,
    'app/source.tsx',
    17,
    20,
    0,
  );
  assert.equal(text, compileErrorMarker);
});

test('restoration requires a healthy source marker and a cleared overlay', () => {
  assert.equal(restorationVisible(true, ''), true);
  assert.equal(restorationVisible(true, '  '), true);
  assert.equal(restorationVisible(false, ''), false);
  assert.equal(restorationVisible(true, compileErrorMarker), false);
  assert.equal(restorationVisible(true, 'a different build error'), false);
  assert.equal(restorationVisible(true, undefined), false);
  assert.equal(restorationVisible(true, null), false);
});

test('overlay read failures remain unknown rather than cleared', async () => {
  const fail = async () => {
    throw new Error('browser disconnected');
  };
  assert.equal(await readOverlayText(fail, async () => ''), undefined);
  assert.equal(await readOverlayText(async () => true, fail), undefined);
  assert.equal(
    await readOverlayText(
      async () => true,
      async () => null,
    ),
    undefined,
  );
});

test('only a successful overlay visibility or text read can establish clearance', async () => {
  assert.equal(
    await readOverlayText(
      async () => false,
      async () => {
        throw new Error('must not read');
      },
    ),
    '',
  );
  assert.equal(
    await readOverlayText(
      async () => true,
      async () => '',
    ),
    '',
  );
  assert.equal(
    await readOverlayText(
      async () => true,
      async () => 'different error',
    ),
    'different error',
  );
});
