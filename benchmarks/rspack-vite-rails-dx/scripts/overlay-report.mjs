import { readFile, realpath, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { format as formatMarkdown } from 'prettier';
import { assertNoLocalPaths } from './local-paths.mjs';
import { buildOverlayReport } from './overlay-helpers.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rawPath = path.resolve(root, readArgument('--raw') ?? 'results/overlay-recorded.json');
const outputPath = path.resolve(root, readArgument('--output') ?? 'OVERLAY_RESULTS.md');
const raw = JSON.parse(await readFile(rawPath, 'utf8'));
assertNoLocalPaths(raw, [...new Set([root, await realpath(root)])]);
const rendered = await formatMarkdown(buildOverlayReport(raw), { parser: 'markdown' });

if (process.argv.includes('--check')) {
  if ((await readFile(outputPath, 'utf8')) !== rendered) {
    console.error(
      `${path.relative(root, outputPath)} is stale; regenerate it with pnpm exec node scripts/overlay-report.mjs`,
    );
    process.exitCode = 1;
  }
} else {
  await writeFile(outputPath, rendered);
  console.log(`Wrote ${path.relative(root, outputPath)}`);
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}
