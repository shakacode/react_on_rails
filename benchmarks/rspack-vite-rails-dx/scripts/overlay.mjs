import { chmod, mkdir, readFile, realpath, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { format as formatOutput } from 'prettier';
import { captureEnvironment, startApp } from './app-session.mjs';
import { assertNoLocalPaths, redactLocalPaths } from './local-paths.mjs';
import {
  addCompileError,
  addRuntimeError,
  buildOverlayReport,
  compileErrorMarker,
  parseEditorInvocation,
  runtimeErrorMarker,
  sourceLocationVisible,
} from './overlay-helpers.mjs';
import { prepareWorkspaces, removeWorkspaces } from './starter-workspace.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repositoryRoot = path.resolve(root, '../..');
const output = path.resolve(root, readArgument('--output') ?? 'results/overlay-local.json');
const report = path.resolve(root, readArgument('--report') ?? 'OVERLAY_RESULTS.local.md');
const tools = ['rspack', 'vite'];
const rootAliases = [
  ...new Set([root, await realpath(root), repositoryRoot, await realpath(repositoryRoot)]),
];
let browser;
let activeSession;

const environment = captureEnvironment(root);
if (!environment.harness_git_clean)
  throw new Error('overlay verification must start from a clean committed worktree');

await prepareWorkspaces(root);
const recorderPath = path.join(root, '.work/editor-recorder.mjs');
const recorderOutput = path.join(root, '.work/editor-invocations.jsonl');
await writeEditorRecorder(recorderPath);

const raw = {
  schema_version: 1,
  created_at: new Date().toISOString(),
  environment,
  methodology: {
    compile_overlay:
      'append a deterministic syntax error and require the overlay marker plus original TSX file and line',
    runtime_overlay:
      'insert a deterministic render-time throw and require the overlay marker plus original TSX file and line',
    click_to_editor:
      'click the compile-error source link with LAUNCH_EDITOR set to a recorder; require exact copied source path, line, and column',
    cleanup:
      'restore each source mutation, wait for the overlay to clear, then remove the process group, workspace, and ports',
  },
  results: {},
};

try {
  browser = await chromium.launch({ headless: true });
  for (const tool of tools) raw.results[tool] = await verifyTool(tool);
} finally {
  await activeSession?.stop();
  await browser?.close();
  await removeWorkspaces(root);
}

const safeRaw = JSON.parse(redactLocalPaths(JSON.stringify(raw), rootAliases));
assertNoLocalPaths(safeRaw, rootAliases);
await mkdir(path.dirname(output), { recursive: true });
await writeFile(output, await formatOutput(JSON.stringify(safeRaw), { parser: 'json' }));
await writeFile(report, await formatOutput(buildOverlayReport(safeRaw), { parser: 'markdown' }));
console.log(`Wrote ${path.relative(root, output)} and ${path.relative(root, report)}`);
console.log(JSON.stringify(matrixSummary(safeRaw), null, 2));

async function verifyTool(tool) {
  await rm(recorderOutput, { force: true });
  const browserErrors = [];
  const session = await startApp({
    browser,
    root,
    tool,
    label: 'overlay',
    extraEnv: {
      LAUNCH_EDITOR: recorderPath,
      OVERLAY_EDITOR_RECORD: recorderOutput,
    },
  });
  activeSession = session;
  session.page.on('pageerror', (error) =>
    browserErrors.push(redactEvidence(error.stack ?? error.message, session)),
  );
  const healthySource = await session.workspace.readSource();

  try {
    const compile = addCompileError(healthySource);
    await session.workspace.writeSource(compile.source);
    const compileEvidence = await observeOverlay(session, tool, compileErrorMarker, compile.line);
    const clickEvidence =
      compileEvidence.status === 'PASS'
        ? await verifyClickToEditor(session, tool, compile.line)
        : { status: 'FAIL', reason: 'compile overlay did not expose verified source evidence' };
    await restoreHealthy(session, tool, healthySource, compileErrorMarker);

    const runtime = addRuntimeError(healthySource, tool);
    await session.workspace.writeSource(runtime.source);
    const runtimeEvidence = await observeOverlay(session, tool, runtimeErrorMarker, runtime.line, 12_000);
    await restoreHealthy(session, tool, healthySource, runtimeErrorMarker);

    return {
      compile_overlay: compileEvidence,
      runtime_overlay: runtimeEvidence,
      click_to_editor: clickEvidence,
      browser_error_excerpt: excerpt(browserErrors.join('\n')),
      cleanup: 'PASS',
    };
  } finally {
    await session.workspace.writeSource(healthySource).catch(() => {});
    await session.stop();
    activeSession = undefined;
  }
}

async function observeOverlay(session, tool, marker, line, timeout = 30_000) {
  const text = await waitForOverlayText(session.page, tool, marker, timeout);
  if (text === undefined) {
    return {
      status: 'FAIL',
      marker_visible: false,
      source_location_visible: false,
      expected_source: `${session.workspace.relativeMessagePath}:${line}`,
      evidence: 'No matching overlay appeared before the bounded timeout.',
    };
  }
  const locationVisible = sourceLocationVisible(text, session.workspace.relativeMessagePath, line);
  return {
    status: locationVisible ? 'PASS' : 'FAIL',
    marker_visible: true,
    source_location_visible: locationVisible,
    expected_source: `${session.workspace.relativeMessagePath}:${line}`,
    evidence: excerpt(redactEvidence(text, session)),
  };
}

async function verifyClickToEditor(session, tool, expectedLine) {
  const target =
    tool === 'rspack'
      ? session.page
          .frameLocator('#rspack-dev-server-client-overlay')
          .locator('[data-can-open="true"]')
          .first()
      : session.page.locator('vite-error-overlay').locator('.file-link').first();
  try {
    await target.click({ timeout: 5_000 });
    const invocation = await waitForEditorInvocation();
    const parsed = parseEditorInvocation(
      invocation,
      session.workspace.directory,
      session.workspace.messagePath,
    );
    const positionMatches =
      parsed?.line === expectedLine && Number.isInteger(parsed.column) && parsed.column > 0;
    return {
      status: positionMatches ? 'PASS' : 'FAIL',
      expected_source: `${session.workspace.relativeMessagePath}:${expectedLine}:<column>`,
      recorded_source: parsed ? `${parsed.file}:${parsed.line}:${parsed.column}` : undefined,
      evidence: positionMatches
        ? 'The temporary editor recorder received the exact copied source path, line, and column.'
        : 'The editor recorder did not receive the expected copied source location.',
    };
  } catch (error) {
    return {
      status: 'FAIL',
      expected_source: `${session.workspace.relativeMessagePath}:${expectedLine}:<column>`,
      evidence: excerpt(redactEvidence(error.message, session)),
    };
  }
}

async function restoreHealthy(session, tool, healthySource, marker) {
  await session.workspace.writeSource(healthySource);
  const deadline = Date.now() + 30_000;
  let lastOverlay = '';
  let lastReady = false;
  while (Date.now() < deadline) {
    lastOverlay = await currentOverlayText(session.page, tool);
    lastReady = await session.page
      .locator('[data-benchmark-marker]')
      .filter({ hasText: session.marker })
      .isVisible()
      .catch(() => false);
    if (!lastOverlay.includes(marker) && lastReady) return;
    await delay(100);
  }
  throw new Error(
    `${tool} overlay did not clear after restoring the source: ready=${lastReady}; overlay=${excerpt(redactEvidence(lastOverlay, session))}`,
  );
}

async function waitForOverlayText(page, tool, marker, timeout) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const text = await currentOverlayText(page, tool);
    if (text.includes(marker)) return text;
    await delay(100);
  }
  return undefined;
}

async function currentOverlayText(page, tool) {
  const host =
    tool === 'rspack'
      ? page.locator('#rspack-dev-server-client-overlay')
      : page.locator('vite-error-overlay');
  if (!(await host.isVisible().catch(() => false))) return '';
  const locator =
    tool === 'rspack' ? page.frameLocator('#rspack-dev-server-client-overlay').locator('body') : host;
  return (await locator.textContent({ timeout: 500 }).catch(() => '')) ?? '';
}

async function waitForEditorInvocation() {
  const deadline = Date.now() + 10_000;
  while (Date.now() < deadline) {
    try {
      const lines = (await readFile(recorderOutput, 'utf8')).trim().split('\n');
      if (lines[0]) return JSON.parse(lines.at(-1));
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    await delay(100);
  }
  throw new Error('timed out waiting for the LAUNCH_EDITOR recorder');
}

async function writeEditorRecorder(filename) {
  await writeFile(
    filename,
    `#!/usr/bin/env node\nimport { appendFile } from 'node:fs/promises';\nawait appendFile(process.env.OVERLAY_EDITOR_RECORD, JSON.stringify(process.argv.slice(2)) + '\\n');\n`,
  );
  await chmod(filename, 0o755);
}

function redactEvidence(value, session) {
  return redactLocalPaths(value, [...rootAliases, session.workspace.directory]);
}

function excerpt(value) {
  if (!value) return undefined;
  return value.replace(/\s+/g, ' ').trim().slice(0, 1_000);
}

function matrixSummary(result) {
  return Object.fromEntries(
    tools.map((tool) => [
      tool,
      {
        compile_overlay: result.results[tool].compile_overlay.status,
        runtime_overlay: result.results[tool].runtime_overlay.status,
        click_to_editor: result.results[tool].click_to_editor.status,
      },
    ]),
  );
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}
