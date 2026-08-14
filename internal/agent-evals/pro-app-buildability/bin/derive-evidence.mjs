#!/usr/bin/env node
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { ARTIFACT_LIMITS, readBoundedEvents } from './evidence-limits.mjs';
import { redactLocalPaths } from './local-paths.mjs';
import { normalizeCommand } from './normalize-command.mjs';
import { redactSensitiveValues } from './sensitive-values.mjs';

const [eventsPath, workspace, outputDir, reportPath, invocationPath] = process.argv.slice(2);
if (!eventsPath || !workspace || !outputDir || !reportPath || !invocationPath) {
  console.error('usage: derive-evidence.mjs EVENTS WORKSPACE OUTPUT REPORT INVOCATION');
  process.exit(64);
}

const MAX_OUTPUT = 12_000;
const MAX_EXCERPT = 16_000;
const sanitize = (value) => redactSensitiveValues(redactLocalPaths(value, [workspace, outputDir]));

const truncate = (value, limit) => {
  const safe = sanitize(value);
  return { value: safe.slice(0, limit), truncated: safe.length > limit };
};

const { events, limits: eventLimits } = readBoundedEvents(eventsPath);

const commands = [];
for (const event of events) {
  const item = event?.item;
  if (event?.type === 'item.completed' && item?.type === 'command_execution') {
    const output = truncate(item.aggregated_output ?? item.output ?? '', MAX_OUTPUT);
    commands.push({
      id: `command-${commands.length + 1}`,
      command: sanitize(normalizeCommand(item.command) || 'UNKNOWN'),
      exit_code: Number.isInteger(item.exit_code) ? item.exit_code : null,
      status: String(item.status ?? 'unknown'),
      output: output.value,
      output_truncated: output.truncated,
    });
  }
}
const commandEvidence = { schema_version: '1.0', limits: eventLimits, commands };

const excludedDirectories = new Set(['.git', 'node_modules', 'vendor', 'tmp', 'log', 'storage']);
const selectedBasenames = new Set(['Gemfile', 'package.json', 'routes.rb']);
const selectedExtensions = new Set(['.rb', '.js', '.jsx', '.ts', '.tsx']);
const selectedRoots = ['app/', 'spec/', 'test/'];
const artifacts = [];
const artifactLimits = {
  ...ARTIFACT_LIMITS,
  visited_entries: 0,
  selected_files: 0,
  included_files: 0,
  included_bytes: 0,
  omitted_files: 0,
  exceeded: false,
  reasons: [],
};
let stopWalk = false;
const exceedArtifactLimit = (reason, omitted = false) => {
  artifactLimits.exceeded = true;
  if (!artifactLimits.reasons.includes(reason)) artifactLimits.reasons.push(reason);
  if (omitted) artifactLimits.omitted_files += 1;
};

function walk(directory, depth = 0) {
  if (stopWalk) return;
  if (depth > ARTIFACT_LIMITS.max_depth) {
    exceedArtifactLimit('depth');
    stopWalk = true;
    return;
  }
  const entries = fs.opendirSync(directory);
  try {
    while (!stopWalk) {
      const entry = entries.readSync();
      if (entry === null) break;
      artifactLimits.visited_entries += 1;
      if (artifactLimits.visited_entries > ARTIFACT_LIMITS.max_visited_entries) {
        exceedArtifactLimit('visited_entries');
        stopWalk = true;
        return;
      }
      if (!entry.isSymbolicLink() && !excludedDirectories.has(entry.name)) {
        const absolute = path.join(directory, entry.name);
        if (entry.isDirectory()) {
          walk(absolute, depth + 1);
        } else if (entry.isFile()) {
          const relative = path.relative(workspace, absolute).replaceAll(path.sep, '/');
          const insideSelectedRoot = selectedRoots.some(
            (root) => relative.startsWith(root) || relative.includes(`/${root}`),
          );
          const selected =
            selectedBasenames.has(entry.name) ||
            (insideSelectedRoot && selectedExtensions.has(path.extname(entry.name)));
          if (selected) {
            artifactLimits.selected_files += 1;
            if (artifactLimits.selected_files > ARTIFACT_LIMITS.max_files) {
              exceedArtifactLimit('selected_files', true);
              stopWalk = true;
              return;
            }
            const fileSize = fs.statSync(absolute).size;
            if (fileSize > ARTIFACT_LIMITS.max_file_bytes) {
              exceedArtifactLimit('file_bytes', true);
            } else if (artifactLimits.included_bytes + fileSize > ARTIFACT_LIMITS.max_total_bytes) {
              exceedArtifactLimit('total_bytes', true);
              stopWalk = true;
              return;
            } else {
              const content = fs.readFileSync(absolute);
              const excerpt = truncate(content.toString('utf8'), MAX_EXCERPT);
              artifacts.push({
                path: relative,
                sha256: crypto.createHash('sha256').update(content).digest('hex'),
                size: fileSize,
                excerpt: excerpt.value,
                excerpt_truncated: excerpt.truncated,
              });
              artifactLimits.included_files += 1;
              artifactLimits.included_bytes += fileSize;
            }
          }
        }
      }
    }
  } finally {
    entries.closeSync();
  }
}
walk(workspace);
artifacts.sort((left, right) => left.path.localeCompare(right.path));
artifactLimits.reasons.sort();
const artifactEvidence = { schema_version: '1.0', limits: artifactLimits, artifacts };

const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
const invocation = JSON.parse(fs.readFileSync(invocationPath, 'utf8'));
const successfulCommands = commands.filter((command) => command.exit_code === 0);
const matchingArtifacts = (pathPattern, contentPattern) =>
  artifacts.filter((artifact) => pathPattern.test(artifact.path) && contentPattern.test(artifact.excerpt));
const artifactCitations = (matched) => matched.map((artifact) => `artifact-evidence.json#${artifact.path}`);
const commandCitations = (matched) => matched.map((command) => `command-evidence.json#${command.id}`);
const unwrapShellCommand = (command) => {
  const match = command.match(/^\/(?:usr\/)?bin\/(?:zsh|bash|sh) -lc (['"])([\s\S]*)\1$/);
  return (match?.[2] ?? command).trim();
};
const isHelpOrVersion = (command) => /(?:^|\s)(?:--help|--version|-h|-V)(?:\s|$)/.test(command);
const boundedLogPipeline =
  /^(.*\S)\s+2>&1\s*\|\s*tee\s+(?:--\s+)?(?:"<LOCAL_PATH>"|'<LOCAL_PATH>'|<LOCAL_PATH>|<LOCAL_PATH>\/\.ror-eval-state\/create-app\.log|"(?:[A-Za-z0-9_./-]|\$(?:[A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\}))*"|'[A-Za-z0-9_./${}-]+'|[A-Za-z0-9_./${}-]+)\s*\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/;
const completedScaffoldLogPipeline =
  /^(.*\S)\s+2>&1\s*\|\s*tee\s+(?:--\s+)?(?:"<LOCAL_PATH>"|'<LOCAL_PATH>'|<LOCAL_PATH>|<LOCAL_PATH>\/\.create-app\.log|<LOCAL_PATH>\/\.ror-eval-state\/create-app\.log|"(?:[A-Za-z0-9_./-]|\$(?:[A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\}))*"|'[A-Za-z0-9_./${}-]+'|[A-Za-z0-9_./${}-]+)\s*\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/;
const statusMarkedScaffoldPipeline =
  /^(.*\S)\s+2>&1\s*\|\s*tee\s+<LOCAL_PATH>\/scaffold\.log\s*\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/;
const safeOutputRedirection = /^(.*\S)\s+>\s+(?:"<LOCAL_PATH>"|'<LOCAL_PATH>'|<LOCAL_PATH>)\s+2>&1$/;
const boundedPlaceholderTail =
  /^tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})\s+(?:"<LOCAL_PATH>"|'<LOCAL_PATH>'|<LOCAL_PATH>)$/;
const boundedTailPipeline = /^(.*\S)\s+2>&1\s*\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/;
const boundedStatusPipeline =
  /^(.*\S)\s+2>&1\s*(?:\|\s*tee\s+(?:(?:<LOCAL_PATH>)|[A-Za-z0-9_./-])+\s*)?\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/;
const boundedStdoutStatusPipeline = /^(.*\S)\s+\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/;
const exactScaffoldTailSuffix = /[ \t]*\|[ \t]*tail[ \t]+-c[ \t]+4096$/;
const canonicalizeExactScaffoldTail = (line) => {
  const suffix = line.match(exactScaffoldTailSuffix);
  return suffix ? `${line.slice(0, suffix.index).trimEnd()} | tail -n 1` : null;
};
const matchExactScaffoldPipeline = (line, pattern) =>
  canonicalizeExactScaffoldTail(line)?.match(pattern) ?? null;
const normalizedStateSourceLines = new Set([
  'source <LOCAL_PATH>/.ror-eval-state/pgenv.sh',
  'source <LOCAL_PATH>/.ror-eval-state/env.sh',
  'source /workspace/pgtools/env.sh',
]);
const normalizedSetupLines = [
  'export HOME=<LOCAL_PATH>/runner-home',
  'export PGHOST=<LOCAL_PATH>/.pgsocket PGPORT=5433 PGUSER=postgres',
];
const stripSanitizedSetupPrefix = (lines) => {
  let cursor = 0;
  if (normalizedStateSourceLines.has(lines[cursor])) cursor += 1;
  for (const setupLine of normalizedSetupLines) {
    if (lines[cursor] === setupLine) cursor += 1;
  }
  if (cursor < lines.length - 1 && /^cd <LOCAL_PATH>(?:\/eval_app)?$/.test(lines[cursor])) {
    cursor += 1;
  }
  return lines.slice(cursor);
};
const stripSanitizedPhaseSetupPrefix = (lines) => {
  const cdThenSource =
    /^cd <LOCAL_PATH>(?:\/eval_app)?$/.test(lines[0]) && normalizedStateSourceLines.has(lines[1]);
  return cdThenSource ? lines.slice(2) : stripSanitizedSetupPrefix(lines);
};
const explicitPgTestSetupLines = [
  'export PGHOST=<LOCAL_PATH>/.ror-eval-state/pgsocket',
  'export PGPORT=5433',
  'export PGUSER=postgres',
];
const sanitizedEvalDirectory = /^cd <LOCAL_PATH>(?:\/eval_app)?$/;
const stripExplicitPgTestSetupPrefix = (lines) => {
  const cdFirst = sanitizedEvalDirectory.test(lines[0]);
  let cursor = cdFirst ? 1 : 0;
  if (!explicitPgTestSetupLines.every((line, index) => lines[cursor + index] === line)) return null;
  cursor += explicitPgTestSetupLines.length;
  if (!cdFirst && cursor < lines.length - 1 && sanitizedEvalDirectory.test(lines[cursor])) cursor += 1;
  return lines.slice(cursor);
};
const relativeCdTestSetupLines = ['cd eval_app', ...explicitPgTestSetupLines];
const stripRelativeCdTestSetupPrefix = (lines) =>
  relativeCdTestSetupLines.every((line, index) => lines[index] === line)
    ? lines.slice(relativeCdTestSetupLines.length)
    : null;
const scaffoldRetrySetupLines = [
  'rm -rf <LOCAL_PATH>/eval_app',
  'cd <LOCAL_PATH>',
  ...explicitPgTestSetupLines,
];
const stripScaffoldRetrySetupPrefix = (lines) =>
  scaffoldRetrySetupLines.every((line, index) => lines[index] === line)
    ? lines.slice(scaffoldRetrySetupLines.length)
    : null;
const immediatePhaseStatusTarget = (
  lines,
  output,
  phase,
  allowWithoutPipefail = false,
  allowStdoutOnly = false,
) => {
  const hasTopLevelPipefail = lines[0] === 'set -o pipefail';
  const proofLines = hasTopLevelPipefail ? lines.slice(1) : lines;
  if (
    (proofLines.length !== 2 && proofLines.length !== 3) ||
    (!hasTopLevelPipefail && (!allowWithoutPipefail || proofLines.length !== 3))
  ) {
    return null;
  }

  const pipelineMatch =
    proofLines[0].match(boundedStatusPipeline) ??
    (allowStdoutOnly && proofLines.length === 3 ? proofLines[0].match(boundedStdoutStatusPipeline) : null);
  const directMarkerMatch =
    proofLines.length === 2 && hasTopLevelPipefail
      ? proofLines[1].match(/^echo "([A-Z][A-Z0-9_]{0,63})=\$\{PIPESTATUS\[0\]\}"$/)
      : null;
  const assignedMarkerMatch =
    proofLines.length === 3 ? proofLines[1].match(/^([A-Z][A-Z0-9_]{0,63})=\$\{PIPESTATUS\[0\]\}$/) : null;
  const assignedEchoMatch =
    proofLines.length === 3
      ? proofLines[2].match(/^echo "([A-Z][A-Z0-9_]{0,63})=\$([A-Z][A-Z0-9_]{0,63})"$/)
      : null;
  const markerName = directMarkerMatch?.[1] ?? assignedMarkerMatch?.[1];
  if (
    !pipelineMatch ||
    Number(pipelineMatch[2]) > 1000 ||
    !markerName ||
    (assignedMarkerMatch && (assignedEchoMatch?.[1] !== markerName || assignedEchoMatch?.[2] !== markerName))
  ) {
    return null;
  }

  const markerTokens = markerName.split('_');
  if (
    !markerTokens.includes(phase) ||
    !markerTokens.some((token) => /^(?:EXIT|EXITCODE|STATUS|PIPESTATUS)$/.test(token))
  ) {
    return null;
  }

  const outputLines = output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const markerPrefix = `${markerName}=`;
  const markers = outputLines.filter(
    (line) => line.startsWith(markerPrefix) && /^-?[0-9]+$/.test(line.slice(markerPrefix.length)),
  );
  return markers.length === 1 && markers[0] === `${markerName}=0` && outputLines.at(-1) === markers[0]
    ? { target: pipelineMatch[1], outputLines }
    : null;
};
const exactBuildMarkerProof = (lines, targetIndex, output) => {
  const tailMatch = lines[targetIndex + 2]?.match(boundedPlaceholderTail);
  const markers = output.split(/\r?\n/).filter((line) => /^BUILD_EXIT_CODE=-?[0-9]+$/.test(line));
  return (
    targetIndex === 1 &&
    lines.length === 4 &&
    lines[0] === 'rm -rf public/packs public/packs-test' &&
    lines[targetIndex + 1] === 'echo "BUILD_EXIT_CODE=$?"' &&
    tailMatch !== null &&
    Number(tailMatch[1]) <= 1000 &&
    markers.length === 1 &&
    markers[0] === 'BUILD_EXIT_CODE=0'
  );
};
const immediateBuildMarkerProof = (lines, targetIndex, output) => {
  if (targetIndex !== 0 || lines.length !== 3) return false;
  const markerMatch = lines[1].match(/^echo "([A-Z][A-Z0-9_]*)=\$\?"$/);
  const tailMatch = lines[2].match(boundedPlaceholderTail);
  if (!markerMatch || !tailMatch || Number(tailMatch[1]) > 1000) return false;

  const markerName = markerMatch[1];
  const markerPattern = new RegExp(`^${markerName}=-?[0-9]+$`);
  const markers = output.split(/\r?\n/).filter((line) => markerPattern.test(line));
  return markers.length === 1 && markers[0] === `${markerName}=0`;
};
const inlineBuildMarkerTarget = (lines, output) => {
  if (lines.length !== 1) return null;
  const match = lines[0].match(
    /^echo "last exit status check:";\s*(npm run build)\s+>\s+<LOCAL_PATH>\s+2>&1;\s*echo "EXIT_CODE:\$\?";\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})\s+<LOCAL_PATH>$/,
  );
  const markers = output.split(/\r?\n/).filter((line) => /^EXIT_CODE:-?[0-9]+$/.test(line));
  return match && Number(match[2]) <= 1000 && markers.length === 1 && markers[0] === 'EXIT_CODE:0'
    ? match[1]
    : null;
};
const inlineColonBuildMarkerTarget = (lines, output) => {
  if (lines.length !== 1) return null;
  const match = lines[0].match(
    /^(npm run build) > <LOCAL_PATH> 2>&1;\s*echo "([A-Z][A-Z0-9_]*):( ?)\$\?";\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})\s+<LOCAL_PATH>$/,
  );
  if (!match || Number(match[4]) > 1000) return null;

  const markerName = match[2];
  const markerSpacing = match[3];
  const markerPattern = new RegExp(`^${markerName}:${markerSpacing}-?[0-9]+$`);
  const markers = output.split(/\r?\n/).filter((line) => markerPattern.test(line));
  return markers.length === 1 && markers[0] === `${markerName}:${markerSpacing}0` ? match[1] : null;
};
const isolatedProductionBuildTarget = (lines, output) => {
  if (
    lines.length !== 4 ||
    lines[0] !==
      'RAILS_ENV=production NODE_ENV=production SECRET_KEY_BASE="<GENERATED_AT_RUNTIME>" npm run build > <LOCAL_PATH>/.ror-eval-state/prod-build.log 2>&1' ||
    lines[1] !== 'echo "EXIT CODE: $?"' ||
    lines[3] !== 'ls public/packs/js | head -20'
  ) {
    return null;
  }
  const tailMatch = lines[2].match(
    /^tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})\s+<LOCAL_PATH>\/\.ror-eval-state\/prod-build\.log$/,
  );
  const markers = output.split(/\r?\n/).filter((line) => /^EXIT CODE: -?[0-9]+$/.test(line));
  return tailMatch && Number(tailMatch[1]) <= 1000 && markers.length === 1 && markers[0] === 'EXIT CODE: 0'
    ? 'npm run build'
    : null;
};
const artifactCheckedProductionBuildTarget = (lines, output) => {
  if (
    lines.length !== 5 ||
    lines[0] !== 'rm -rf public/packs ssr-generated' ||
    lines[1] !== 'npm run build > <LOCAL_PATH> 2>&1' ||
    lines[2] !== 'echo "build_prod_exit=$?"' ||
    lines[4] !==
      'ls public/packs/manifest.json ssr-generated/server-bundle.js ssr-generated/rsc-bundle.js 2>&1'
  ) {
    return null;
  }
  const tailMatch = lines[3].match(/^tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})\s+<LOCAL_PATH>$/);
  const markers = output.split(/\r?\n/).filter((line) => /^build_prod_exit=-?[0-9]+$/.test(line));
  return tailMatch &&
    Number(tailMatch[1]) <= 1000 &&
    markers.length === 1 &&
    markers[0] === 'build_prod_exit=0'
    ? 'npm run build'
    : null;
};
const pipelineStatusProductionBuildTarget = (lines, output) => {
  if (
    lines.length !== 6 ||
    lines[0] !== 'cd <LOCAL_PATH>/eval_app' ||
    !/^echo "FINAL_BUILD_EXIT=\$\{PIPESTATUS\[0\]\}"$/.test(lines[2]) ||
    lines[3] !== 'git status --short' ||
    lines[4] !== 'echo "---git log---"' ||
    lines[5] !== 'git log --oneline --reverse'
  ) {
    return null;
  }
  const pipelineMatch = lines[1].match(/^(npm run build)\s+2>&1\s*\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/);
  const outputLines = output.split(/\r?\n/);
  const markers = outputLines.filter((line) => /^FINAL_BUILD_EXIT=-?[0-9]+$/.test(line));
  const markerIndex = outputLines.indexOf('FINAL_BUILD_EXIT=0');
  const compilationPrecedesMarker = outputLines
    .slice(0, markerIndex)
    .some((line) => /compiled|compilation (?:complete|successful)|built successfully/i.test(line));
  return pipelineMatch &&
    Number(pipelineMatch[2]) <= 1000 &&
    markers.length === 1 &&
    markers[0] === 'FINAL_BUILD_EXIT=0' &&
    compilationPrecedesMarker
    ? pipelineMatch[1]
    : null;
};
const phaseStatusProductionBuildTarget = (lines, output) => {
  const cleanup = 'rm -rf public/assets public/packs public/packs-test';
  const hasCleanup = lines[0] === cleanup;
  const proofLines = hasCleanup ? lines.slice(1) : lines;
  const proof = immediatePhaseStatusTarget(proofLines, output, 'BUILD', !hasCleanup, !hasCleanup);
  if (
    !proof ||
    (proof.target !== 'npm run build' &&
      proof.target !== 'env RAILS_ENV=production NODE_ENV=production bin/rails assets:precompile')
  ) {
    return null;
  }
  return proof.outputLines
    .slice(0, -1)
    .some((line) => /compiled|compilation (?:complete|successful)|built successfully/i.test(line))
    ? proof.target
    : null;
};
const compoundShakapackerBuildTarget =
  '{ RAILS_ENV=production NODE_ENV=production bin/shakapacker-precompile-hook && SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=production NODE_ENV=production bin/shakapacker; }';
const relativeCdCompoundProductionBuildTarget = (lines, output, outputTruncated) => {
  if (outputTruncated || lines[0] !== 'cd eval_app' || /(?:^|\n)\s*(?:[^\n]*:\s*)?cd:\s/i.test(output)) {
    return null;
  }
  const proof = immediatePhaseStatusTarget(lines.slice(1), output, 'BUILD', true);
  return proof?.target === compoundShakapackerBuildTarget &&
    proof.outputLines
      .slice(0, -1)
      .some((line) => /compiled|compilation (?:complete|successful)|built successfully/i.test(line))
    ? proof.target
    : null;
};
const directRuntimeProductionBuildTarget = (lines) =>
  lines.length === 1 && lines[0] === 'SECRET_KEY_BASE="<GENERATED_AT_RUNTIME>" npm run build'
    ? 'npm run build'
    : null;
const completedScaffoldOutput = (output) => {
  const lines = output.split(/\r?\n/).map((line) => line.trim());
  const created = lines.filter((line) => line === 'Created eval_app with React on Rails!');
  const done = lines.filter((line) => line === '✓ Done!');
  const errorBanner = lines.some((line) =>
    /\b(?:error|failed|aborted)\b(?::|\s|$)|(?:^|\s)(?:npm\s+ERR!|ERR!)/i.test(line),
  );
  return created.length === 1 && done.length === 1 && !errorBanner;
};
const statusMarkedScaffoldTarget = (lines, output) => {
  if (
    lines.length !== 3 ||
    lines[0] !== 'set -o pipefail' ||
    lines[2] !== 'echo "PIPE_EXIT_STATUS=$?"' ||
    !completedScaffoldOutput(output)
  ) {
    return null;
  }
  const pipelineMatch = matchExactScaffoldPipeline(lines[1], statusMarkedScaffoldPipeline);
  const outputLines = output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const markers = outputLines.filter((line) => /^PIPE_EXIT_STATUS=-?[0-9]+$/.test(line));
  return pipelineMatch &&
    Number(pipelineMatch[2]) <= 1000 &&
    markers.length === 1 &&
    markers[0] === 'PIPE_EXIT_STATUS=0' &&
    outputLines.at(-1) === markers[0]
    ? pipelineMatch[1]
    : null;
};
const phaseStatusScaffoldTarget = (lines, output) => {
  const canonicalPipeline = canonicalizeExactScaffoldTail(lines[1] ?? '');
  if (!canonicalPipeline) return null;
  const canonicalLines = [...lines];
  canonicalLines[1] = canonicalPipeline;
  const proof = immediatePhaseStatusTarget(canonicalLines, output, 'SCAFFOLD');
  return proof && completedScaffoldOutput(output) ? proof.target : null;
};
const stripBoundedTimeoutPrefix = (line) => {
  const match = line.match(/^timeout ([1-9][0-9]{0,8}) (.+)$/);
  if (!match) return line;
  const timeoutSeconds = Number(match[1]);
  const scaffoldLimit = invocation.scaffold_timeout_seconds;
  if (!Number.isSafeInteger(scaffoldLimit) || timeoutSeconds > scaffoldLimit) return null;
  return match[2];
};
const stripScaffoldTimePrefix = (line) => (line.startsWith('time ') ? line.slice(5) : line);
const stripScaffoldNodeVersionPrefix = (line) =>
  line.startsWith('node -v; ') ? line.slice('node -v; '.length) : line;
const topLevelShellLines = (command) => {
  const invocation = unwrapShellCommand(command);
  if (invocation.includes('<<')) return [];

  const executableLines = [];
  for (const physicalLine of invocation.split(/\r?\n/)) {
    let quote = null;
    let escaped = false;
    let commentAt = physicalLine.length;
    for (let index = 0; index < physicalLine.length; index += 1) {
      const character = physicalLine[index];
      if (quote !== null) {
        if (quote !== "'" && escaped) escaped = false;
        else if (quote !== "'" && character === '\\') escaped = true;
        else if (character === quote) quote = null;
      } else if (escaped) {
        escaped = false;
      } else if (character === '\\') {
        escaped = true;
      } else if (character === '"' || character === "'") {
        quote = character;
      } else if (character === '#' && (index === 0 || /\s/.test(physicalLine[index - 1]))) {
        commentAt = index;
        break;
      }
    }
    const continuedToNext = quote !== "'" && escaped;
    // Never discard part of a physical command and classify the remaining lines as independent proof.
    if (quote !== null || continuedToNext) return [];
    const candidate = physicalLine.slice(0, commentAt).trim();
    if (candidate) executableLines.push(candidate);
  }
  return executableLines;
};
const normalizedEvidenceLines = (command) => stripSanitizedSetupPrefix(topLevelShellLines(command));
const pipefailPipelineTargets = (lines, pipelineMatcher = (line) => line.match(boundedLogPipeline)) =>
  lines.flatMap((line, index) => {
    const pipelineMatch = pipelineMatcher(line);
    const hasTopLevelPipefail = lines.length === 2 && index === 1 && lines[0] === 'set -o pipefail';
    return pipelineMatch && hasTopLevelPipefail && Number(pipelineMatch[2]) <= 1000 ? [pipelineMatch[1]] : [];
  });
const installEvidenceTargets = (command) => {
  const rawLines = topLevelShellLines(command.command);
  const lines = stripSanitizedSetupPrefix(rawLines);
  const phaseLines = stripScaffoldRetrySetupPrefix(rawLines) ?? stripSanitizedPhaseSetupPrefix(rawLines);
  const outputIsUsable =
    !command.output_truncated && !command.output.includes('[normalized-output-truncated]');
  const pipefailTargets = outputIsUsable
    ? pipefailPipelineTargets(lines, (line) => matchExactScaffoldPipeline(line, boundedLogPipeline))
    : [];
  const statusMarkedTarget = outputIsUsable ? statusMarkedScaffoldTarget(rawLines, command.output) : null;
  const phaseStatusTarget = outputIsUsable ? phaseStatusScaffoldTarget(phaseLines, command.output) : null;
  const completionBackedTarget = (() => {
    if (!outputIsUsable || lines.length !== 1 || !completedScaffoldOutput(command.output)) return [];
    const pipelineMatch = matchExactScaffoldPipeline(lines[0], completedScaffoldLogPipeline);
    return pipelineMatch && Number(pipelineMatch[2]) <= 1000
      ? [stripScaffoldNodeVersionPrefix(stripScaffoldTimePrefix(pipelineMatch[1]))]
      : [];
  })();
  const directTargets = lines.length === 1 && !/[;&|<>]/.test(lines[0]) ? lines : [];
  return [
    ...directTargets,
    ...pipefailTargets,
    ...completionBackedTarget,
    ...(statusMarkedTarget ? [statusMarkedTarget] : []),
    ...(phaseStatusTarget ? [phaseStatusTarget] : []),
  ];
};
const buildEvidenceTargets = (command) => {
  const rawLines = topLevelShellLines(command.command);
  const lines = normalizedEvidenceLines(command.command);
  const phaseLines = stripSanitizedPhaseSetupPrefix(rawLines);
  const targets = [
    ...(lines.length === 1 && !/[;&|<>]/.test(lines[0]) ? lines : []),
    ...pipefailPipelineTargets(lines),
  ];
  const inlineTarget = inlineBuildMarkerTarget(lines, command.output);
  if (inlineTarget) targets.push(inlineTarget);
  const inlineColonTarget = inlineColonBuildMarkerTarget(lines, command.output);
  if (inlineColonTarget) targets.push(inlineColonTarget);
  const isolatedProductionTarget = isolatedProductionBuildTarget(lines, command.output);
  if (isolatedProductionTarget) targets.push(isolatedProductionTarget);
  const artifactCheckedProductionTarget = artifactCheckedProductionBuildTarget(lines, command.output);
  if (artifactCheckedProductionTarget) targets.push(artifactCheckedProductionTarget);
  const pipelineStatusProductionTarget = pipelineStatusProductionBuildTarget(rawLines, command.output);
  if (pipelineStatusProductionTarget) targets.push(pipelineStatusProductionTarget);
  const phaseStatusProductionTarget = phaseStatusProductionBuildTarget(phaseLines, command.output);
  if (phaseStatusProductionTarget) targets.push(phaseStatusProductionTarget);
  const relativeCdCompoundTarget = relativeCdCompoundProductionBuildTarget(
    rawLines,
    command.output,
    command.output_truncated,
  );
  if (relativeCdCompoundTarget) targets.push(relativeCdCompoundTarget);
  const directRuntimeProductionTarget = directRuntimeProductionBuildTarget(lines);
  if (directRuntimeProductionTarget) targets.push(directRuntimeProductionTarget);
  for (const [index, line] of lines.entries()) {
    const redirectionMatch = line.match(safeOutputRedirection);
    if (
      redirectionMatch &&
      (exactBuildMarkerProof(lines, index, command.output) ||
        immediateBuildMarkerProof(lines, index, command.output))
    ) {
      targets.push(redirectionMatch[1]);
    }
  }
  return targets;
};

const rubyProManifests = matchingArtifacts(/Gemfile$/, /react_on_rails_pro/);
const jsProManifests = matchingArtifacts(/package\.json$/, /react-on-rails-pro/);
const evalAppPackageManifest = artifacts.find(
  (artifact) =>
    (artifact.path === 'package.json' || artifact.path === 'eval_app/package.json') &&
    !artifact.excerpt_truncated,
);
let manifestBackedProductionBuild = false;
if (evalAppPackageManifest) {
  try {
    const packageManifest = JSON.parse(evalAppPackageManifest.excerpt);
    const buildScript = packageManifest?.scripts?.build;
    manifestBackedProductionBuild =
      typeof buildScript === 'string' &&
      /(?:^|\s)RAILS_ENV=production(?=\s|$)/.test(buildScript) &&
      /(?:^|\s)NODE_ENV=production(?=\s|$)/.test(buildScript);
  } catch {
    manifestBackedProductionBuild = false;
  }
}
const installCommands = successfulCommands.filter((command) => {
  return installEvidenceTargets(command).some((invocationLine) => {
    const targetCommand = stripBoundedTimeoutPrefix(invocationLine);
    return (
      targetCommand !== null &&
      !isHelpOrVersion(targetCommand) &&
      /^(?:npx(?: --yes)?|npm exec|pnpm dlx) create-react-on-rails-app(?:@[^\s]+)? [A-Za-z0-9][A-Za-z0-9._-]*(?:\s+[^;&|<>]+)?$/.test(
        targetCommand,
      )
    );
  });
});
const rscRoutes = matchingArtifacts(/config\/routes\.rb$/, /rsc|server_component|server-component/i);
const rscSources = matchingArtifacts(
  /(?:^|\/)app\/(?:(?:.*(?:\.server\.|rsc|server_component))|(?:.*\/)?ror_components(?:\/|$))/i,
  /export|class|module|render/i,
);
const validationModels = matchingArtifacts(/app\/models\/.*\.rb$/, /validates|validate\s/);
const validationControllers = matchingArtifacts(
  /app\/controllers\/.*\.rb$/,
  /unprocessable_entity|unprocessable_content|errors/,
);
const pageTests = artifacts.filter((artifact) => {
  const testContent = /expect|assert|test\s|it\s/.test(artifact.excerpt);
  const namedPageTest =
    /(?:spec|test)\/.*(?:page|rsc).*(?:_spec\.rb|_test\.rb|\.(?:test|spec)\.[jt]sx?)$/i.test(artifact.path);
  const uncommentedRuby = artifact.excerpt.replace(/^\s*#.*$/gm, '');
  const actionDispatchIntegrationTest =
    /^\s*class\s+[A-Za-z_][A-Za-z0-9_:]*\s*<\s*ActionDispatch::IntegrationTest\b/m.test(uncommentedRuby);
  const controllerIntegrationTest =
    /test\/controllers\/.*_test\.rb$/i.test(artifact.path) && actionDispatchIntegrationTest;
  const rubyIntegrationTest = /test\/integration\/.*_test\.rb$/i.test(artifact.path);
  const semanticPhraseName =
    /^\s*(?:test|it)\s+["'][^"'\r\n]*(?:react server component|server-provided data)[^"'\r\n]*["']/im.test(
      uncommentedRuby,
    );
  const explicitRscPageName =
    actionDispatchIntegrationTest &&
    /^\s*test\s+["'](?=[^"'\r\n]*\bRSC\b)(?=[^"'\r\n]*\bpage\b)[^"'\r\n]+["']/im.test(uncommentedRuby);
  const semanticRscIntegrationTest =
    (/(?:spec|test)\/integration\/.*(?:_spec\.rb|_test\.rb)$/i.test(artifact.path) ||
      controllerIntegrationTest) &&
    (semanticPhraseName || ((rubyIntegrationTest || controllerIntegrationTest) && explicitRscPageName)) &&
    /^\s*(?:get|visit)(?:\s+|\()[^\r\n]+/m.test(uncommentedRuby) &&
    /^\s*(?:assert\w*|expect)(?:\s|\()/m.test(uncommentedRuby);
  return testContent && (namedPageTest || semanticRscIntegrationTest);
});
const rubyPercentLiteralDescriptor = (line, start) => {
  const opener = line.slice(start).match(/^%([qQwWiIxrs]?)([^A-Za-z0-9_\s])/);
  if (!opener) return undefined;
  const opening = opener[2];
  const closing = { '(': ')', '[': ']', '{': '}', '<': '>' }[opening] ?? opening;
  return {
    bodyStart: start + opener[0].length,
    closing,
    depth: 1,
    escaped: false,
    opening,
    paired: closing !== opening,
    type: opener[1],
  };
};
const scanRubyPercentLiteral = (line, start, priorState = null) => {
  const descriptor = priorState ?? rubyPercentLiteralDescriptor(line, start);
  if (descriptor === undefined) return undefined;
  const { closing, opening, paired } = descriptor;
  let { depth, escaped } = descriptor;
  const cursor = priorState === null ? descriptor.bodyStart : start;
  for (let index = cursor; index < line.length; index += 1) {
    const character = line[index];
    if (escaped) {
      escaped = false;
    } else if (character === '\\') {
      escaped = true;
    } else if (paired && character === opening) {
      depth += 1;
    } else if (character === closing) {
      depth -= 1;
      if (depth === 0) return { descriptor, end: index, state: null };
    }
  }
  return { descriptor, end: null, state: { ...descriptor, depth, escaped } };
};
const rubySlashRegexEnd = (line, start) => {
  const prefix = line.slice(0, start).trimEnd();
  if (!/(?:^|[=(:,[!&|?{};])$/.test(prefix)) return undefined;
  let escaped = false;
  let characterClass = false;
  for (let index = start + 1; index < line.length; index += 1) {
    const character = line[index];
    if (escaped) {
      escaped = false;
    } else if (character === '\\') {
      escaped = true;
    } else if (character === '[') {
      if (characterClass) {
        const posixClass = line.slice(index).match(/^\[:[a-z]+:\]/i)?.[0];
        if (posixClass === undefined) return null;
        index += posixClass.length - 1;
      } else {
        characterClass = true;
      }
    } else if (character === ']') {
      if (!characterClass) return null;
      characterClass = false;
    } else if (character === '/' && !characterClass) {
      while (/[imxounes]/.test(line[index + 1] ?? '')) index += 1;
      return index;
    }
  }
  return null;
};
const rubyHeredocOpeners = (line, localVariables) => {
  const openers = [];
  let quote = null;
  let escaped = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (escaped) {
      escaped = false;
    } else if (quote !== null && character === '\\') {
      escaped = true;
    } else if (quote !== null) {
      if (character === quote) quote = null;
    } else if (character === '"' || character === "'") {
      quote = character;
    } else if (character === '%') {
      const percentLiteral = scanRubyPercentLiteral(line, index);
      if (percentLiteral?.end === null) {
        return { multilinePercent: { index, state: percentLiteral.state }, openers };
      }
      if (percentLiteral?.end !== undefined) index = percentLiteral.end;
    } else if (character === '/') {
      const regexEnd = rubySlashRegexEnd(line, index);
      if (regexEnd === null) return null;
      if (regexEnd !== undefined) index = regexEnd;
    } else if (character === '#') {
      break;
    } else if (character === '<' && line[index + 1] === '<') {
      const opener = line.slice(index).match(/^<<([-~]?)(["']?)([A-Za-z_][A-Za-z0-9_]*)\2/);
      if (opener) {
        const receiver = line.slice(0, index).match(/\b([a-z_][A-Za-z0-9_]*)[ \t]*$/)?.[1];
        if (receiver === undefined || !localVariables.has(receiver)) {
          openers.push({ allowIndent: opener[1] !== '', index, name: opener[3] });
        }
        index += opener[0].length - 1;
      }
    }
  }
  return quote === null && !escaped ? { multilinePercent: null, openers } : null;
};
const maskRubyHeredocs = (content) => {
  const records = content.match(/[^\r\n]*(?:\r\n|\n|$)/g)?.filter(Boolean) ?? [];
  let terminator = null;
  let multilinePercent = null;
  const masked = [];
  const localVariables = new Set();
  for (const record of records) {
    const lineEnding = record.match(/\r?\n$/)?.[0] ?? '';
    const line = record.slice(0, record.length - lineEnding.length);
    if (terminator !== null) {
      const candidate = terminator.allowIndent ? line.trim() : line.trimEnd();
      const closes = candidate === terminator.name && (terminator.allowIndent || !/^[ \t]/.test(line));
      masked.push(`${line.replace(/./g, ' ')}${lineEnding}`);
      if (closes) terminator = null;
    } else if (multilinePercent !== null) {
      const scan = scanRubyPercentLiteral(line, 0, multilinePercent.state);
      if (scan?.end === null) {
        masked.push(`${line.replace(/./g, ' ')}${lineEnding}`);
        multilinePercent = { state: scan.state };
      } else {
        const suffix = line.slice((scan?.end ?? -1) + 1);
        const suffixPattern =
          scan?.descriptor.type === 'r' ? /^[imxounes]*[ \t]*(?:#.*)?$/ : /^[ \t]*(?:#.*)?$/;
        if (!suffixPattern.test(suffix)) return null;
        masked.push(`${line.replace(/./g, ' ')}${lineEnding}`);
        multilinePercent = null;
      }
    } else {
      const localAssignment = line.match(/^[ \t]*([a-z_][A-Za-z0-9_]*)[ \t]*=(?!=)/)?.[1];
      if (localAssignment !== undefined) localVariables.add(localAssignment);
      const scan = rubyHeredocOpeners(line, localVariables);
      if (scan === null || scan.openers.length > 1) return null;
      if (scan.multilinePercent !== null) {
        if (scan.openers.length > 0) return null;
        const literalStart = scan.multilinePercent.index;
        masked.push(
          `${line.slice(0, literalStart)}${line.slice(literalStart).replace(/./g, ' ')}${lineEnding}`,
        );
        multilinePercent = { state: scan.multilinePercent.state };
      } else if (scan.openers.length === 0) {
        masked.push(record);
      } else {
        const opener = scan.openers[0];
        terminator = { allowIndent: opener.allowIndent, name: opener.name };
        const prefix = line.slice(0, opener.index);
        masked.push(`${prefix}${line.slice(opener.index).replace(/./g, ' ')}${lineEnding}`);
      }
    }
  }
  return terminator === null && multilinePercent === null ? masked.join('') : null;
};
const rubyTestCases = (content) => {
  const maskedContent = maskRubyHeredocs(content);
  if (maskedContent === null) return [];
  const starts = [
    ...maskedContent.matchAll(/^([ \t]*)test\s+(?:"([^"\r\n]+)"|'([^'\r\n]+)')\s+do\b[^\r\n]*$/gm),
  ];
  return starts.flatMap((match, index) => {
    const bodyRegion = maskedContent.slice(
      match.index + match[0].length,
      starts[index + 1]?.index ?? maskedContent.length,
    );
    const declarationIndent = match[1];
    const regionLines = bodyRegion.split(/\r?\n/);
    const closingEnd = regionLines.findIndex(
      (line) => line.match(/^([ \t]*)end\s*$/)?.[1] === declarationIndent,
    );
    if (closingEnd < 0) return [];

    const physicalLines = regionLines.slice(0, closingEnd);
    const body = physicalLines
      .filter((line) => {
        const indent = line.match(/^([ \t]*)\S/)?.[1];
        return indent?.startsWith(declarationIndent) && indent.length > declarationIndent.length;
      })
      .join('\n');
    return [{ name: match[2] ?? match[3], body, physicalLines }];
  });
};
const semanticFormIntegrationTest = (artifact, uncommentedRuby) => {
  if (
    !/test\/(?:controllers|integration)\/.*_test\.rb$/i.test(artifact.path) ||
    !/^\s*class\s+[A-Za-z_][A-Za-z0-9_:]*\s*<\s*ActionDispatch::IntegrationTest\b/m.test(uncommentedRuby)
  ) {
    return false;
  }

  const cases = rubyTestCases(uncommentedRuby);
  const normalizedNameTokens = (name) =>
    name
      .toLowerCase()
      .replace(/n['’]t\b/g, ' not')
      .replace(/\bcannot\b/g, 'can not')
      .match(/[a-z]+|[0-9]+/g) ?? [];
  const negationTokens = new Set(['neither', 'never', 'no', 'nor', 'not', 'without']);
  const clauseBoundaries = new Set(['and', 'but', 'yet']);
  const conditionConnectors = new Set(['after', 'during', 'for', 'on', 'upon', 'when', 'while']);
  const markerIsNegated = (tokens, index) => {
    const clauseBoundary = tokens.slice(0, index).findLastIndex((token) => clauseBoundaries.has(token));
    let connectorIndex = tokens
      .slice(clauseBoundary + 1, index)
      .findLastIndex((token) => conditionConnectors.has(token));
    if (connectorIndex >= 0) {
      connectorIndex += clauseBoundary + 1;
      if (negationTokens.has(tokens[connectorIndex - 1])) return true;
      return tokens.slice(connectorIndex + 1, index).some((token) => negationTokens.has(token));
    }
    return tokens.slice(clauseBoundary + 1, index).some((token) => negationTokens.has(token));
  };
  const outcomeIsNegated = (tokens, index) => {
    const clauseBoundary = tokens.slice(0, index).findLastIndex((token) => clauseBoundaries.has(token));
    let scopeStart = clauseBoundary + 1;
    const connectorOffset = tokens
      .slice(scopeStart, index)
      .findLastIndex((token) => conditionConnectors.has(token));
    if (connectorOffset >= 0) {
      const connectorIndex = scopeStart + connectorOffset;
      if (negationTokens.has(tokens[connectorIndex - 1])) return true;
      scopeStart = connectorIndex + 1;
    }
    let failureIndex = -1;
    if (/^(?:fail|fails|failed)$/.test(tokens[index - 2] ?? '') && tokens[index - 1] === 'to') {
      failureIndex = index - 2;
    } else if (/^(?:fail|fails|failed)$/.test(tokens[index - 3] ?? '') && tokens[index - 2] === 'to') {
      failureIndex = index - 3;
    }
    if (failureIndex >= 0) {
      const failureGovernors = tokens.slice(Math.max(scopeStart, failureIndex - 3), failureIndex);
      return !failureGovernors.some((token) => negationTokens.has(token));
    }
    const governingTokens = tokens.slice(Math.max(scopeStart, index - 4), index);
    return governingTokens.some((token) => negationTokens.has(token));
  };
  const positiveSubmissionMarkers = (tokens, markers) =>
    tokens.flatMap((token, index) => {
      if (!markers.includes(token) || tokens[index + 1] !== 'submission' || markerIsNegated(tokens, index)) {
        return [];
      }
      return [{ index }];
    });
  const submissionMarkerIndexes = (tokens) =>
    tokens.flatMap((token, index) =>
      ['invalid', 'successful', 'valid'].includes(token) && tokens[index + 1] === 'submission' ? [index] : [],
    );
  const submissionMarkerRegion = (tokens, markerIndex) => {
    const markers = submissionMarkerIndexes(tokens);
    const markerPosition = markers.indexOf(markerIndex);
    return {
      start: markerPosition > 0 ? markers[markerPosition - 1] + 2 : 0,
      end:
        markerPosition >= 0 && markerPosition < markers.length - 1
          ? markers[markerPosition + 1]
          : tokens.length,
    };
  };
  const validationErrorsAreAbsent = (tokens, validationIndex) => {
    if (/^(?:0|zero)$/.test(tokens[validationIndex - 1] ?? '')) return true;
    if (
      /^(?:avoid|avoids|avoided|avoiding|bypass|bypasses|bypassed|bypassing)$/.test(
        tokens[validationIndex - 1] ?? '',
      )
    ) {
      return true;
    }
    const trailingClause = [];
    for (const token of tokens.slice(validationIndex + 2, validationIndex + 8)) {
      if (['and', 'but', 'yet', 'while'].includes(token)) break;
      if (token === 'invalid' && trailingClause.length > 0) break;
      trailingClause.push(token);
    }
    const phrase = trailingClause.join(' ');
    return (
      /^(?:(?:are|be|is|remain|remains|were) )?(?:absent|missing)\b/.test(phrase) ||
      /^(?:(?:are|be|is|remain|remains|were) )?(?:not|never) (?:appear|display|displayed|present|render|rendered|show|shown|visible)\b/.test(
        phrase,
      ) ||
      /^(?:do|does|did) not (?:appear|display|render|show)\b/.test(phrase) ||
      /^never (?:appear|display|render|show)\b/.test(phrase) ||
      /^(?:fail|fails|failed) to (?:appear|display|render|show)\b/.test(phrase)
    );
  };
  const validationFailureIsAbsent = (tokens, validationIndex) => {
    const trailingClause = [];
    const trailingEnd = Math.min(tokens.length, validationIndex + 8);
    for (let index = validationIndex + 2; index < trailingEnd; index += 1) {
      const token = tokens[index];
      if (['and', 'but', 'yet', 'while'].includes(token)) break;
      if (
        ['invalid', 'successful', 'valid'].includes(token) &&
        tokens[index + 1] === 'submission' &&
        trailingClause.length > 0
      ) {
        break;
      }
      trailingClause.push(token);
    }
    const phrase = trailingClause.join(' ');
    return (
      /^(?:(?:are|be|is|remain|remains|were) )?(?:absent|missing)\b/.test(phrase) ||
      /^(?:(?:are|be|is|remain|remains|were) )?(?:not|never) (?:happen|happened|occur|occurred|present)\b/.test(
        phrase,
      ) ||
      /^(?:do|does|did) not (?:happen|occur)\b/.test(phrase) ||
      /^never (?:happen|occur)\b/.test(phrase) ||
      /^(?:fail|fails|failed) to (?:happen|occur)\b/.test(phrase)
    );
  };
  const positiveFailureOutcomeName = (name) => {
    const tokens = normalizedNameTokens(name);
    const validationFailure = tokens.some(
      (token, index) =>
        token === 'validation' &&
        tokens[index + 1] === 'failure' &&
        !outcomeIsNegated(tokens, index) &&
        !validationFailureIsAbsent(tokens, index),
    );
    if (validationFailure) return true;
    const invalidMarkers = positiveSubmissionMarkers(tokens, ['invalid']);
    if (invalidMarkers.length === 0 || submissionMarkerIndexes(tokens).length !== 1) return false;
    return invalidMarkers.some((marker) => {
      const region = submissionMarkerRegion(tokens, marker.index);
      return tokens.some((token, index) => {
        if (index < region.start || index >= region.end || index === marker.index) return false;
        if (token === 'validation' && /^errors?$/.test(tokens[index + 1] ?? '')) {
          return !outcomeIsNegated(tokens, index) && !validationErrorsAreAbsent(tokens, index);
        }
        if (token === 'validation' && /^(?:fail|fails|failed)$/.test(tokens[index + 1] ?? '')) {
          return !outcomeIsNegated(tokens, index + 1);
        }
        if (/^(?:fail|fails|failed)$/.test(token) && tokens[index + 1] === 'server') {
          return (
            tokens[index + 2] === 'side' &&
            tokens[index + 3] === 'validation' &&
            !outcomeIsNegated(tokens, index)
          );
        }
        return (
          /^(?:fail|fails|failed)$/.test(token) &&
          tokens[index + 1] === 'validation' &&
          !outcomeIsNegated(tokens, index)
        );
      });
    });
  };
  const failureCandidates = cases.filter((testCase) => positiveFailureOutcomeName(testCase.name));
  const positiveSubmissionOutcomeName = (name) => {
    const tokens = normalizedNameTokens(name);
    const submissionMarkers = positiveSubmissionMarkers(tokens, ['valid', 'successful']);
    if (submissionMarkers.length === 0 || submissionMarkerIndexes(tokens).length !== 1) return false;

    const successOutcome =
      /^(?:accept(?:s|ed|ing)?|creat(?:e|es|ed|ing)|succeed(?:s|ed|ing)?|sav(?:e|es|ed|ing)|persist(?:s|ed|ing)?|redirect(?:s|ed|ing)?)$/;
    const outcomeHasNegativeObject = (index) => {
      if (!/^(?:creat(?:e|es|ed|ing)|sav(?:e|es|ed|ing)|persist(?:s|ed|ing)?)$/.test(tokens[index])) {
        return false;
      }
      const trailing = tokens.slice(index + 1, index + 7);
      if (trailing[0] === 'nothing') return true;
      if (!/^(?:no|without|zero)$/.test(trailing[0] ?? '')) return false;
      let objectIndex = /^(?:a|an|any|the)$/.test(trailing[1] ?? '') ? 2 : 1;
      if (/^(?:additional|new)$/.test(trailing[objectIndex] ?? '')) objectIndex += 1;
      const object = trailing[objectIndex];
      return /^(?:entries|entry|record|records|resource|resources|submission|submissions|subscriber|subscribers)$/.test(
        object ?? '',
      );
    };
    const hasNegativeResult = submissionMarkers.some((marker) => {
      const region = submissionMarkerRegion(tokens, marker.index);
      return tokens.some((token, index) => {
        if (index < region.start || index >= region.end) return false;
        if (
          index !== marker.index &&
          /^success(?:ful|fully)?$/.test(token) &&
          outcomeIsNegated(tokens, index)
        ) {
          return true;
        }
        if (outcomeIsNegated(tokens, index)) return false;
        if (outcomeHasNegativeObject(index)) return true;
        if (
          /^creat(?:e|es|ed|ing)$/.test(token) &&
          tokens.slice(index + 1, index + 4).some((candidate) => /^(?:duplicate|duplicates)$/.test(candidate))
        ) {
          return true;
        }
        if (/^(?:fail|fails|failed)$/.test(token) && tokens[index + 1] !== 'to') return true;
        if (/^(?:ignore|ignored|ignores|ignoring)$/.test(token)) return true;
        if (/^(?:unsuccessful|unsuccessfully)$/.test(token)) return true;
        if (
          token === 'failure' &&
          /^(?:a|the)$/.test(tokens[index - 1] ?? '') &&
          /^(?:be|become|becomes|became|get|gets|got|is|remain|remains|was|were)$/.test(
            tokens[index - 2] ?? '',
          )
        ) {
          return true;
        }
        if (
          /^(?:blocked|denied|invalid|refused|rejected)$/.test(token) &&
          /^(?:be|become|becomes|became|get|gets|got|is|remain|remains|was|were)$/.test(
            tokens[index - 1] ?? '',
          )
        ) {
          return true;
        }
        if (
          /^(?:produce|produced|produces|raise|raised|raises|render|rendered|renders|result|resulted|results|return|returned|returns|show|showed|shows)$/.test(
            token,
          )
        ) {
          const resultTokens = tokens.slice(index + 1, index + 4);
          return resultTokens.some((result, offset) => {
            const resultIndex = index + offset + 1;
            const errorFree = /^(?:error|errors)$/.test(result) && tokens[resultIndex + 1] === 'free';
            return (
              /^(?:error|errors|failure|rejection)$/.test(result) &&
              !errorFree &&
              !outcomeIsNegated(tokens, resultIndex)
            );
          });
        }
        if (/^redirect(?:s|ed|ing)?$/.test(token) && /^(?:to|with)$/.test(tokens[index + 1] ?? '')) {
          return tokens
            .slice(index + 2, index + 6)
            .some((result) => /^(?:error|errors|failure|invalid|rejection)$/.test(result));
        }
        const errorFree = /^(?:error|errors)$/.test(token) && tokens[index + 1] === 'free';
        return /^(?:error|errors|failure|rejection)$/.test(token) && !errorFree;
      });
    });
    if (hasNegativeResult) return false;
    const outcomeIndexes = tokens.flatMap((token, index) => {
      if (!successOutcome.test(token)) return [];
      const duplicateCreation =
        /^creat(?:e|es|ed|ing)$/.test(token) &&
        tokens.slice(index + 1, index + 4).some((candidate) => /^(?:duplicate|duplicates)$/.test(candidate));
      return duplicateCreation && outcomeIsNegated(tokens, index) ? [] : [index];
    });
    if (outcomeIndexes.length > 0) return outcomeIndexes.every((index) => !outcomeIsNegated(tokens, index));
    return true;
  };
  const successCandidates = cases.filter((testCase) => positiveSubmissionOutcomeName(testCase.name));
  const positiveInteger = /^[1-9][0-9]{0,4}$/;
  const rubyPercentRegexParts = (literal) => {
    if (!literal.startsWith('%r')) return undefined;
    const descriptor = rubyPercentLiteralDescriptor(literal, 0);
    if (descriptor?.type !== 'r') return null;
    const scan = scanRubyPercentLiteral(literal, 0);
    if (scan?.end === null || scan?.end === undefined) return null;
    const flags = literal.slice(scan.end + 1);
    if (!/^[imx]*$/.test(flags)) return null;
    return { body: literal.slice(descriptor.bodyStart, scan.end), flags };
  };
  const literalKind = (rawLiteral) => {
    const literal = rawLiteral.trim();
    const hasControlCharacter = [...literal].some((character) => {
      const codePoint = character.codePointAt(0);
      return codePoint <= 0x1f || codePoint === 0x7f;
    });
    if (literal.length < 2 || hasControlCharacter || /#(?:\{|@|\$)/.test(literal)) return null;
    const percentRegex = rubyPercentRegexParts(literal);
    if (percentRegex !== undefined)
      return percentRegex !== null && /\S/.test(percentRegex.body) ? 'regex' : null;
    const opening = literal[0];
    if (opening === '"' || opening === "'") {
      let escaped = false;
      let meaningful = false;
      for (let index = 1; index < literal.length; index += 1) {
        const character = literal[index];
        if (escaped) {
          escaped = false;
          meaningful ||= !/\s/.test(character);
        } else if (character === '\\') {
          escaped = true;
        } else if (character === opening) {
          return index === literal.length - 1 && meaningful ? 'quoted' : null;
        } else {
          meaningful ||= !/\s/.test(character);
        }
      }
      return null;
    }
    if (opening !== '/') return null;
    let escaped = false;
    let meaningful = false;
    for (let index = 1; index < literal.length; index += 1) {
      const character = literal[index];
      if (escaped) {
        escaped = false;
        meaningful ||= !/\s/.test(character);
      } else if (character === '\\') {
        escaped = true;
      } else if (character === '/') {
        return meaningful && /^[imx]*$/.test(literal.slice(index + 1)) ? 'regex' : null;
      } else {
        meaningful ||= !/\s/.test(character);
      }
    }
    return null;
  };
  const simpleRegexBodyIsSafe = (body) => {
    if (body.length > 256) return false;
    let escaped = false;
    let characterClass = false;
    for (const character of body) {
      if (escaped) {
        if (!characterClass && /[1-9]/.test(character)) return false;
        escaped = false;
      } else if (character === '\\') {
        escaped = true;
      } else if (character === '[') {
        if (characterClass) return false;
        characterClass = true;
      } else if (character === ']') {
        if (!characterClass) return false;
        characterClass = false;
      } else if (!characterClass && /[*+?{]/.test(character)) {
        return false;
      }
    }
    return !escaped && !characterClass;
  };
  const javascriptRegexForLiteral = (rawLiteral) => {
    if (literalKind(rawLiteral) !== 'regex') return null;
    const literal = rawLiteral.trim();
    const percentRegex = rubyPercentRegexParts(literal);
    const body = percentRegex?.body ?? literal.slice(1, literal.lastIndexOf('/'));
    if (/\\[GK]/.test(body) || !simpleRegexBodyIsSafe(body)) return null;
    let escaped = false;
    let hasLiteralContent = false;
    for (const character of body) {
      if (escaped) {
        escaped = false;
      } else if (character === '\\') {
        escaped = true;
      } else if (/[A-Za-z0-9]/.test(character)) {
        hasLiteralContent = true;
      }
    }
    if (!hasLiteralContent || body.includes('(?')) return null;
    const flags = percentRegex?.flags ?? literal.slice(literal.lastIndexOf('/') + 1);
    if (flags.includes('x')) return null;
    const javascriptBody = body.replaceAll('\\A', '^').replace(/\\[zZ]/g, '$');
    try {
      return new RegExp(javascriptBody, flags);
    } catch {
      return null;
    }
  };
  const positiveMatchLiteral = (rawLiteral) => {
    const kind = literalKind(rawLiteral);
    if (kind === 'quoted') return true;
    const regex = javascriptRegexForLiteral(rawLiteral);
    return regex !== null && !regex.test('');
  };
  function splitTopLevelCommas(value) {
    const parts = [];
    let cursor = 0;
    let quote = null;
    let regex = false;
    let escaped = false;
    let braces = 0;
    let brackets = 0;
    for (let index = 0; index < value.length; index += 1) {
      const character = value[index];
      if (escaped) {
        escaped = false;
      } else if (character === '\\' && (quote !== null || regex)) {
        escaped = true;
      } else if (quote !== null) {
        if (character === quote) quote = null;
      } else if (regex) {
        if (character === '/') regex = false;
      } else if (character === '"' || character === "'") {
        quote = character;
      } else if (character === '/') {
        regex = true;
      } else if (character === '{') {
        braces += 1;
      } else if (character === '}') {
        braces -= 1;
        if (braces < 0) return null;
      } else if (character === '[') {
        brackets += 1;
      } else if (character === ']') {
        brackets -= 1;
        if (brackets < 0) return null;
      } else if (character === ',' && braces === 0 && brackets === 0) {
        parts.push(value.slice(cursor, index).trim());
        cursor = index + 1;
      }
    }
    if (quote !== null || regex || escaped || braces !== 0 || brackets !== 0) return null;
    parts.push(value.slice(cursor).trim());
    return parts.some((part) => part === '') ? null : parts;
  }
  function positiveAssertMatch(assertion) {
    const match = assertion.match(/^assert_match(?:[ \t]+(.+)|\([ \t]*(.+)\))$/);
    if (!match) return null;
    const argumentsList = splitTopLevelCommas(match[1] ?? match[2]);
    if (
      argumentsList === null ||
      (argumentsList.length !== 2 &&
        !(argumentsList.length === 3 && literalKind(argumentsList[2]) === 'quoted')) ||
      !positiveMatchLiteral(argumentsList[0])
    ) {
      return null;
    }
    return { pattern: argumentsList[0], subject: argumentsList[1] };
  }
  function positiveAssertIncludes(assertion) {
    const match = assertion.match(/^assert_includes(?:[ \t]+(.+)|\([ \t]*(.+)\))$/);
    if (!match) return null;
    const argumentsList = splitTopLevelCommas(match[1] ?? match[2]);
    if (
      argumentsList === null ||
      (argumentsList.length !== 2 &&
        !(argumentsList.length === 3 && literalKind(argumentsList[2]) === 'quoted')) ||
      literalKind(argumentsList[1]) !== 'quoted'
    ) {
      return null;
    }
    return { member: argumentsList[1], subject: argumentsList[0] };
  }
  function validationErrorLiteralIsNegative(literal) {
    const normalizedLiteral = literal.replace(/\\s(?:[*+?]|\{[0-9]+(?:,[0-9]*)?\})?/g, ' ');
    const regex = javascriptRegexForLiteral(literal);
    if (
      regex !== null &&
      [
        'validation errors: 0',
        '0 validation errors',
        'validation errors are zero',
        'no validation errors',
      ].some((candidate) => regex.test(candidate))
    ) {
      return true;
    }
    return (
      /\b(?:0|empty|no|without|zero)[ \t_-]+(?:validation[ \t_-]+)?errors?\b/i.test(normalizedLiteral) ||
      /\b(?:validation[ \t_-]+)?errors?(?:[ \t_-]+are|[ \t]*[:=])?[ \t_-]*(?:0|empty|false|no|none|off|zero)\b/i.test(
        normalizedLiteral,
      ) ||
      /\b(?:validation[ \t_-]+)?errors?[ \t_-]+(?:(?:are|is|was|were)[ \t_-]+)?(?:absent|empty|missing|not[ \t_-]+(?:displayed|present|rendered|shown|visible))\b/i.test(
        normalizedLiteral,
      ) ||
      /\b(?:validation[ \t_-]+)?errors?[ \t_-]+(?:(?:do|does|did)[ \t_-]+not|never|fail(?:s|ed)?[ \t_-]+to)[ \t_-]+(?:appear|display|render|show)\b/i.test(
        normalizedLiteral,
      )
    );
  }
  function noticeLiteralIsNegative(literal) {
    const normalizedLiteral = literal.replace(/\\s(?:[*+?]|\{[0-9]+(?:,[0-9]*)?\})?/g, ' ');
    return (
      /\b(?:no|without|zero)[ \t_-]+(?:flash[ \t_-]+)?notices?\b/i.test(normalizedLiteral) ||
      /\bnotices?[ \t_-]+(?:are[ \t_-]+)?(?:absent|empty|false|missing|no|none|off|zero)\b/i.test(
        normalizedLiteral,
      )
    );
  }
  function positiveAssertEqualLiteralArray(assertion, negativeLiteralPredicate) {
    const match = assertion.match(/^assert_equal(?:[ \t]+(.+)|\([ \t]*(.+)\))$/);
    if (!match) return null;
    const argumentsList = splitTopLevelCommas(match[1] ?? match[2]);
    if (
      argumentsList === null ||
      (argumentsList.length !== 2 &&
        !(argumentsList.length === 3 && literalKind(argumentsList[2]) === 'quoted'))
    ) {
      return null;
    }
    const expected = argumentsList[0].trim();
    if (!expected.startsWith('[') || !expected.endsWith(']')) return null;
    const members = splitTopLevelCommas(expected.slice(1, -1));
    if (
      members === null ||
      members.length === 0 ||
      members.length > 16 ||
      members.some(
        (member) =>
          literalKind(member) !== 'quoted' ||
          (negativeLiteralPredicate !== null && negativeLiteralPredicate(member)),
      )
    ) {
      return null;
    }
    return { subject: argumentsList[1] };
  }
  const positiveSelectorComparator = (method, rawComparator) => {
    let comparator = rawComparator.trim();
    let parts = splitTopLevelCommas(comparator);
    if (!parts) return false;
    let hasMessage = false;
    if (method === 'select' && parts.length > 1 && literalKind(parts.at(-1)) === 'quoted') {
      hasMessage = true;
      parts.pop();
      comparator = parts.join(', ');
    }
    const braced = comparator.startsWith('{');
    if (braced) {
      if (!comparator.startsWith('{') || !comparator.endsWith('}')) return false;
      comparator = comparator.slice(1, -1).trim();
      if (comparator.endsWith(',')) comparator = comparator.slice(0, -1).trim();
      parts = splitTopLevelCommas(comparator);
      if (!parts) return false;
    } else {
      parts = splitTopLevelCommas(comparator);
      if (
        !parts ||
        (hasMessage && parts.some((part) => /^(?:count|html|maximum|minimum|text)\s*:/.test(part)))
      ) {
        return false;
      }
    }
    if (method === 'select' && (comparator === 'true' || positiveInteger.test(comparator))) return true;
    if (method === 'select' && literalKind(comparator)) return true;
    const rangeMatch =
      method === 'select' && comparator.match(/^([1-9][0-9]{0,4})[ \t]*\.\.\.?[ \t]*(0|[1-9][0-9]{0,4})$/);
    if (rangeMatch) return Number(rangeMatch[1]) <= Number(rangeMatch[2]);
    if (parts.length > 3) return false;
    let contentFilter = null;
    let count = null;
    let minimum = null;
    let maximum = null;
    for (const part of parts) {
      const contentMatch = part.match(/^(text|html):\s*(.+)$/);
      const cardinalityMatch = part.match(/^(count|minimum|maximum):\s*([0-9]{1,5})$/);
      if (
        contentMatch &&
        contentFilter === null &&
        (contentMatch[1] === 'text' || method === 'select') &&
        literalKind(contentMatch[2])
      ) {
        [, contentFilter] = contentMatch;
      } else if (cardinalityMatch) {
        const [, key, value] = cardinalityMatch;
        if (key === 'count' && count === null) count = Number(value);
        else if (key === 'minimum' && minimum === null) minimum = Number(value);
        else if (key === 'maximum' && maximum === null) maximum = Number(value);
        else return false;
      } else {
        return false;
      }
    }
    if (count !== null) {
      return minimum === null && maximum === null && count >= 1;
    }
    if (method === 'selector' && maximum !== null && minimum === null) return false;
    const effectiveMinimum = minimum ?? 1;
    if (effectiveMinimum < 1 || (maximum !== null && maximum < effectiveMinimum)) return false;
    return contentFilter !== null || minimum !== null || maximum !== null;
  };
  const validationErrorComparatorLiterals = (method, rawComparator) => {
    let comparator = rawComparator.trim();
    let parts = splitTopLevelCommas(comparator);
    if (!parts) return [];
    if (method === 'select' && parts.length > 1 && literalKind(parts.at(-1)) === 'quoted') {
      parts.pop();
      comparator = parts.join(', ').trim();
    }
    if (comparator.startsWith('{') && comparator.endsWith('}')) {
      comparator = comparator.slice(1, -1).trim();
      if (comparator.endsWith(',')) comparator = comparator.slice(0, -1).trim();
      parts = splitTopLevelCommas(comparator);
      if (!parts) return [];
    } else {
      parts = splitTopLevelCommas(comparator);
      if (!parts) return [];
    }
    const literals = [];
    if (method === 'select' && parts.length === 1 && literalKind(parts[0]) !== null) {
      literals.push(parts[0]);
    }
    for (const part of parts) {
      const content = part.match(/^(text|html):\s*(.+)$/);
      if (
        content !== null &&
        (content[1] === 'text' || method === 'select') &&
        literalKind(content[2]) !== null
      ) {
        literals.push(content[2]);
      }
    }
    return literals;
  };
  const stripRubyTrailingComment = (line) => {
    let quote = null;
    let regex = false;
    let escaped = false;
    for (let index = 0; index < line.length; index += 1) {
      const character = line[index];
      if (escaped) {
        escaped = false;
      } else if (character === '\\' && (quote !== null || regex)) {
        escaped = true;
      } else if (quote !== null) {
        if (character === quote) quote = null;
      } else if (regex) {
        if (character === '/') regex = false;
      } else if (character === '"' || character === "'") {
        quote = character;
      } else if (character === '/') {
        regex = true;
      } else if (character === '#') {
        return line.slice(0, index);
      }
    }
    return quote === null && !regex && !escaped ? line : null;
  };
  const maskRubyStringAndCommentContent = (line) => {
    const masked = [];
    let quote = null;
    let regex = false;
    let escaped = false;
    for (let index = 0; index < line.length; index += 1) {
      const character = line[index];
      if (escaped) {
        masked.push(' ');
        escaped = false;
      } else if (character === '\\' && (quote !== null || regex)) {
        masked.push(' ');
        escaped = true;
      } else if (quote !== null) {
        masked.push(' ');
        if (character === quote) quote = null;
      } else if (regex) {
        masked.push(' ');
        if (character === '/') regex = false;
      } else if (character === '"' || character === "'") {
        masked.push(' ');
        quote = character;
      } else if (character === '/') {
        masked.push(' ');
        regex = true;
      } else if (character === '#') {
        masked.push(line.slice(index).replace(/./g, ' '));
        break;
      } else {
        masked.push(character);
      }
    }
    return quote === null && !regex && !escaped ? masked.join('') : null;
  };
  const hasPositiveValueAssertion = (
    body,
    subjectPattern,
    allowSubjectFirstEquality = false,
    negativeLiteralPredicate = null,
  ) =>
    body.split(/\r?\n/).some((line) => {
      const uncommentedLine = stripRubyTrailingComment(line);
      if (uncommentedLine === null) return false;
      const assertion = uncommentedLine.trim();
      const matchesSubject = (value) => {
        const maskedValue = maskRubyStringAndCommentContent(value);
        if (maskedValue === null) return false;
        if (subjectPattern.test(maskedValue)) return true;
        return (
          subjectPattern.test(value) &&
          /\bresponse\.parsed_body\b/.test(maskedValue) &&
          /(?:\.fetch\(\s*["']errors?["']\s*\)|\[\s*["']errors?["']\s*\])/i.test(value)
        );
      };
      let match = assertion.match(/^assert(?:\s+|\(\s*)([^,\r\n]+?\.(?:any|present)\?)(?=\s*(?:,|\)|$))/);
      if (match && matchesSubject(match[1])) return true;
      match = assertion.match(
        /^assert(?:\s+|\(\s*)([^,\r\n]+?\.errors?\.added\?\(\s*(?::[a-z_][a-z0-9_]*|"[^"\r\n]+"|'[^'\r\n]+')\s*,\s*(?::[a-z_][a-z0-9_]*|"[^"\r\n]+"|'[^'\r\n]+')\s*\))(?=\s*(?:,|\)|$))/i,
      );
      if (match && matchesSubject(match[1])) return true;
      match = assertion.match(
        /^(?:assert_not|refute)(?:\s+|\(\s*)([^,\r\n]+?\.(?:blank|empty)\?)(?=\s*(?:,|\)|$))/,
      );
      if (match && matchesSubject(match[1])) return true;
      match = assertion.match(/^(?:assert_not_empty|refute_empty)(?:\s+|\(\s*)([^,\r\n)]+)/);
      if (match && matchesSubject(match[1])) return true;
      const includesAssertion = positiveAssertIncludes(assertion);
      if (
        includesAssertion !== null &&
        matchesSubject(includesAssertion.subject) &&
        (negativeLiteralPredicate === null || !negativeLiteralPredicate(includesAssertion.member))
      ) {
        return true;
      }
      const matchAssertion = positiveAssertMatch(assertion);
      if (
        matchAssertion !== null &&
        matchesSubject(matchAssertion.subject) &&
        (negativeLiteralPredicate === null || !negativeLiteralPredicate(matchAssertion.pattern))
      ) {
        return true;
      }
      match = assertion.match(/^assert_present(?:\s+|\(\s*)([^,\r\n)]+)/);
      if (match && matchesSubject(match[1])) return true;
      match = assertion.match(/^assert_equal(?:\s+|\(\s*)[1-9][0-9]{0,4}\s*,\s*([^,\r\n)]+)/);
      if (match && matchesSubject(match[1]) && /\berrors?\.(?:count|length|size)\b/i.test(match[1])) {
        return true;
      }
      match = assertion.match(
        /^assert_operator(?:\s+|\(\s*)([^,\r\n]+)\s*,\s*:(>|>=)\s*,\s*(0|[1-9][0-9]{0,4})(?=\s*(?:,|\)|$))/,
      );
      if (
        match &&
        matchesSubject(match[1]) &&
        /\berrors?\.(?:count|length|size)\b/i.test(match[1]) &&
        (match[2] === '>' || Number(match[3]) >= 1)
      ) {
        return true;
      }
      match = assertion.match(
        /^assert_equal(?:\s+|\(\s*)((?:"[^"\r\n]*[^\s"\r\n][^"\r\n]*"|'[^'\r\n]*[^\s'\r\n][^'\r\n]*'))\s*,\s*([^,\r\n)]+)/,
      );
      if (
        match &&
        matchesSubject(match[2]) &&
        (negativeLiteralPredicate === null || !negativeLiteralPredicate(match[1]))
      ) {
        return true;
      }
      if (allowSubjectFirstEquality) {
        match = assertion.match(
          /^assert_equal(?:\s+|\(\s*)([^,\r\n]+)\s*,\s*((?:"[^"\r\n]*[^\s"\r\n][^"\r\n]*"|'[^'\r\n]*[^\s'\r\n][^'\r\n]*'))(?=\s*(?:,|\)|$))/,
        );
        if (
          match &&
          matchesSubject(match[1]) &&
          (negativeLiteralPredicate === null || !negativeLiteralPredicate(match[2]))
        ) {
          return true;
        }
      }
      const arrayAssertion = positiveAssertEqualLiteralArray(assertion, negativeLiteralPredicate);
      if (arrayAssertion !== null && matchesSubject(arrayAssertion.subject)) return true;
      match = assertion.match(
        /^assert_predicate(?:\s+|\(\s*)([^,\r\n]+)\s*,\s*:(?:any|present)\?(?=[\s,)]|$)/,
      );
      if (match && matchesSubject(match[1])) return true;
      match = assertion.match(
        /^refute_predicate(?:\s+|\(\s*)([^,\r\n]+)\s*,\s*:(?:blank|empty)\?(?=[\s,)]|$)/,
      );
      return match !== null && matchesSubject(match[1]);
    });
  const hasRenderedBodyAssertion = (body) =>
    body.split(/\r?\n/).some((line) => {
      const uncommentedLine = stripRubyTrailingComment(line);
      if (uncommentedLine === null) return false;
      const assertion = uncommentedLine.trim();
      const includesAssertion = positiveAssertIncludes(assertion);
      if (
        includesAssertion !== null &&
        /^(?:@response|response)\.body$/.test(includesAssertion.subject) &&
        !validationErrorLiteralIsNegative(includesAssertion.member)
      ) {
        return true;
      }
      const matchAssertion = positiveAssertMatch(assertion);
      return (
        matchAssertion !== null &&
        /^(?:@response|response)\.body$/.test(matchAssertion.subject) &&
        !validationErrorLiteralIsNegative(matchAssertion.pattern)
      );
    });
  const positiveValidationErrorComparator = (method, rawComparator) => {
    if (!positiveSelectorComparator(method, rawComparator)) return false;
    return validationErrorComparatorLiterals(method, rawComparator).some(
      (literal) =>
        /\bvalidation[ \t_-]+errors?\b/i.test(literal) &&
        (literalKind(literal) !== 'regex' || positiveMatchLiteral(literal)) &&
        !validationErrorLiteralIsNegative(literal),
    );
  };
  const negativeValidationErrorComparator = (method, rawComparator) =>
    validationErrorComparatorLiterals(method, rawComparator).some(validationErrorLiteralIsNegative);
  const negativeErrorStates = new Set([
    '0',
    'no',
    'none',
    'not',
    'false',
    'off',
    'absent',
    'absence',
    'empty',
    'free',
    'missing',
    'without',
    'zero',
  ]);
  const positiveErrorIdentifier = (identifier) => {
    const segments = identifier.toLowerCase().split(/[-_]+/).filter(Boolean);
    return (
      segments.some((segment) => segment === 'error' || segment === 'errors') &&
      !segments.some((segment) => negativeErrorStates.has(segment))
    );
  };
  const negativeErrorIdentifier = (identifier) => {
    const segments = identifier.toLowerCase().split(/[-_]+/).filter(Boolean);
    return (
      segments.some((segment) => segment === 'error' || segment === 'errors') &&
      segments.some((segment) => negativeErrorStates.has(segment))
    );
  };
  const selectorErrorSemantics = (selector) => {
    let attribute = null;
    const functionFrames = [];
    let negationDepth = 0;
    let positiveOutsideNegation = false;
    let negativeStateOutsideNegation = false;
    const isPositiveContext = () => negationDepth === 0 && functionFrames.every((frame) => frame === 'has');
    for (let index = 0; index < selector.length; index += 1) {
      const character = selector[index];
      if (attribute?.quote !== null && attribute?.quote !== undefined) {
        if (character === '\\') return null;
        if (character === attribute.quote) attribute.quote = null;
      } else if (character === '\\') {
        return null;
      } else if (attribute && (character === '"' || character === "'")) {
        attribute.quote = character;
      } else if (character === '[') {
        if (attribute) return null;
        attribute = { start: index + 1, quote: null, positiveContext: isPositiveContext() };
      } else if (character === ']') {
        if (!attribute) return null;
        const parsed = selector
          .slice(attribute.start, index)
          .trim()
          .match(/^([A-Za-z_][A-Za-z0-9_-]*)(?:\s*=\s*(?:"([^"\r\n]*)"|'([^'\r\n]*)'|([A-Za-z0-9_-]+)))?$/);
        if (!parsed) return null;
        if (attribute.positiveContext) {
          const name = parsed[1].toLowerCase();
          const value = parsed[2] ?? parsed[3] ?? parsed[4];
          if (positiveErrorIdentifier(name)) positiveOutsideNegation = true;
          if (negativeErrorIdentifier(name)) negativeStateOutsideNegation = true;
          if (value !== undefined) {
            const normalizedValue = value.toLowerCase();
            if (name === 'class') {
              if (normalizedValue.length > 256) return null;
              const classTokens = normalizedValue.split(/[ \t]+/).filter(Boolean);
              if (
                classTokens.length === 0 ||
                classTokens.length > 16 ||
                classTokens.some((token) => !/^[a-z_][a-z0-9_-]{0,63}$/.test(token))
              ) {
                return null;
              }
              if (classTokens.some((token) => positiveErrorIdentifier(token))) positiveOutsideNegation = true;
              if (classTokens.some((token) => negativeErrorIdentifier(token))) {
                negativeStateOutsideNegation = true;
              }
            }
            if (name === 'data-testid') {
              if (positiveErrorIdentifier(normalizedValue)) positiveOutsideNegation = true;
              if (negativeErrorIdentifier(normalizedValue)) negativeStateOutsideNegation = true;
            }
            if (
              (positiveErrorIdentifier(name) && negativeErrorStates.has(normalizedValue)) ||
              (name === 'aria-invalid' && normalizedValue === 'false')
            ) {
              negativeStateOutsideNegation = true;
            }
          }
        }
        attribute = null;
      } else if (!attribute && character === ':') {
        const pseudoMatch = selector.slice(index + 1).match(/^([A-Za-z_-][A-Za-z0-9_-]*)/);
        if (!pseudoMatch) return null;
        const name = pseudoMatch[1].toLowerCase();
        let cursor = index + pseudoMatch[0].length + 1;
        while (selector[cursor] === ' ' || selector[cursor] === '\t') cursor += 1;
        if (selector[cursor] === '(') {
          const negated = name === 'not';
          if (negated && negationDepth > 0) return null;
          let frame = 'opaque';
          if (negated) frame = 'not';
          else if (name === 'has') frame = 'has';
          if (frame === 'has' && functionFrames.includes('has')) return null;
          functionFrames.push(frame);
          if (negated) negationDepth += 1;
          index = cursor;
        } else {
          if (name === 'not') return null;
          if (name === 'empty' && isPositiveContext()) {
            negativeStateOutsideNegation = true;
          }
          index += pseudoMatch[0].length;
        }
      } else if (!attribute && character === '(') {
        return null;
      } else if (!attribute && character === ')') {
        const frame = functionFrames.pop();
        if (frame === undefined) return null;
        if (frame === 'not') negationDepth -= 1;
      } else if (!attribute && character === ',' && functionFrames.includes('has')) {
        return null;
      } else if (!attribute && (character === '{' || character === '}')) {
        return null;
      } else if (/[A-Za-z_]/.test(character)) {
        const identifier = selector.slice(index).match(/^[A-Za-z_][A-Za-z0-9_-]*/)?.[0];
        if (!identifier) return null;
        if (!attribute && isPositiveContext() && positiveErrorIdentifier(identifier)) {
          positiveOutsideNegation = true;
        }
        if (!attribute && isPositiveContext() && negativeErrorIdentifier(identifier)) {
          negativeStateOutsideNegation = true;
        }
        index += identifier.length - 1;
      }
    }
    return !attribute && functionFrames.length === 0
      ? { positiveOutsideNegation, negativeStateOutsideNegation }
      : null;
  };
  const splitSelectorBranches = (selector) => {
    const branches = [];
    let cursor = 0;
    let attribute = false;
    let quote = null;
    let parentheses = 0;
    for (let index = 0; index < selector.length; index += 1) {
      const character = selector[index];
      if (quote !== null) {
        if (character === '\\') return null;
        if (character === quote) quote = null;
      } else if (attribute && (character === '"' || character === "'")) {
        quote = character;
      } else if (character === '\\' || character === '{' || character === '}') {
        return null;
      } else if (character === '[') {
        if (attribute) return null;
        attribute = true;
      } else if (character === ']') {
        if (!attribute) return null;
        attribute = false;
      } else if (!attribute && character === '(') {
        parentheses += 1;
      } else if (!attribute && character === ')') {
        parentheses -= 1;
        if (parentheses < 0) return null;
      } else if (!attribute && parentheses === 0 && character === ',') {
        branches.push(selector.slice(cursor, index).trim());
        cursor = index + 1;
      }
    }
    if (attribute || quote !== null || parentheses !== 0) return null;
    branches.push(selector.slice(cursor).trim());
    return branches.some((branch) => branch === '') ? null : branches;
  };
  const containsRubyCodeClosingParenthesis = (value) => {
    let quote = null;
    let regex = false;
    let escaped = false;
    for (const character of value) {
      if (escaped) {
        escaped = false;
      } else if (character === '\\' && (quote !== null || regex)) {
        escaped = true;
      } else if (quote !== null) {
        if (character === quote) quote = null;
      } else if (regex) {
        if (character === '/') regex = false;
      } else if (character === '"' || character === "'") {
        quote = character;
      } else if (character === '/') {
        regex = true;
      } else if (character === ')') {
        return true;
      }
    }
    return quote !== null || regex || escaped;
  };
  const selectorStatementPositive = (statement) => {
    const callMatch = statement.match(/^[ \t]*assert_(select|selector|dom)([ \t]+|\([ \t]*)/i);
    if (!callMatch) return false;
    const method = callMatch[1].toLowerCase() === 'dom' ? 'select' : callMatch[1].toLowerCase();
    const openingQuote = statement[callMatch[0].length];
    if (openingQuote !== '"' && openingQuote !== "'") return false;
    let selector = '';
    let selectorEnd = -1;
    for (let index = callMatch[0].length + 1; index < statement.length; index += 1) {
      const character = statement[index];
      const codePoint = character.codePointAt(0);
      if (codePoint <= 0x1f || codePoint === 0x7f) return false;
      if (character === '\\') {
        const escapedCharacter = statement[index + 1];
        if (escapedCharacter !== openingQuote && escapedCharacter !== '\\') return false;
        selector += escapedCharacter;
        index += 1;
      } else if (character === openingQuote) {
        selectorEnd = index;
        break;
      } else {
        if (character === '#' && /[{@$]/.test(statement[index + 1] ?? '')) return false;
        selector += character;
      }
    }
    if (selectorEnd < 0 || selector === '') return false;

    const selectorBranches = splitSelectorBranches(selector);
    const selectorSemantics = selectorBranches?.map(selectorErrorSemantics);
    if (!selectorSemantics || selectorSemantics.some((semantics) => !semantics)) return false;
    if (selectorSemantics.some((semantics) => semantics.negativeStateOutsideNegation)) return false;
    const selectorIsPositive = selectorSemantics.every((semantics) => semantics.positiveOutsideNegation);

    const parenthesized = callMatch[2].includes('(');
    let remainder = statement
      .slice(selectorEnd + 1)
      .replace(/\s+do(?:\s*\|[^|\r\n]*\|)?\s*$/i, '')
      .trim();
    const braceBlock = remainder.match(
      /^(.*\))[ \t]+\{[ \t]*(?:\|[A-Za-z_][A-Za-z0-9_]*(?:[ \t]*,[ \t]*[A-Za-z_][A-Za-z0-9_]*)*\|[ \t]*)?[^{}\r\n]*\}[ \t]*$/,
    );
    if (braceBlock) remainder = braceBlock[1].trim();
    if (parenthesized) {
      if (!remainder.endsWith(')')) return false;
      remainder = remainder.slice(0, -1).trim();
      if (remainder.endsWith(',')) remainder = remainder.slice(0, -1).trim();
    } else if (containsRubyCodeClosingParenthesis(remainder)) {
      return false;
    }
    if (remainder === '') return selectorIsPositive;
    if (!remainder.startsWith(',')) return false;

    const comparator = remainder.slice(1);
    return (
      positiveSelectorComparator(method, comparator) &&
      !negativeValidationErrorComparator(method, comparator) &&
      (selectorIsPositive || positiveValidationErrorComparator(method, comparator))
    );
  };
  const delimiterState = (lines) => {
    const frames = [];
    let quote = null;
    let regex = false;
    let escaped = false;
    for (const line of lines) {
      const delimiterOnly = line.text.match(/^([)}])\s*,?\s*(?:do(?:\s*\|[^|\r\n]*\|)?)?$/);
      for (const character of line.text) {
        if (escaped) {
          escaped = false;
        } else if (character === '\\' && (quote !== null || regex)) {
          escaped = true;
        } else if (quote !== null) {
          if (character === quote) quote = null;
        } else if (regex) {
          if (character === '/') regex = false;
        } else if (character === '"' || character === "'") {
          quote = character;
        } else if (character === '/') {
          regex = true;
        } else if (character === '(' || character === '{') {
          frames.push({ closer: character === '(' ? ')' : '}', indent: line.indent });
        } else if (character === ')' || character === '}') {
          const frame = frames.pop();
          if (!frame || frame.closer !== character) return null;
          if (delimiterOnly && line.indent !== frame.indent) return null;
        }
      }
    }
    return quote === null && !regex && !escaped ? frames : null;
  };
  const selectorStatements = (testCase) => {
    const statements = [];
    for (let index = 0; index < testCase.physicalLines.length; index += 1) {
      const start = stripRubyTrailingComment(testCase.physicalLines[index]);
      const startMatch = start?.match(
        /^([ \t]*)(?:assert_(?:select|selector|dom)|assert_not_(?:select|selector|dom)|refute_(?:select|selector|dom))\b/,
      );
      if (startMatch) {
        const startIndent = startMatch[1];
        const collected = [{ text: start.trim(), indent: startIndent }];
        let statement = collected[0].text;
        let frames = delimiterState(collected);
        let incomplete = statement.endsWith(',') || (frames && frames.length > 0);
        for (let offset = 1; incomplete && offset < 8; offset += 1) {
          const rawContinuation = testCase.physicalLines[index + offset];
          if (rawContinuation === undefined) break;
          const continuation = stripRubyTrailingComment(rawContinuation);
          if (continuation === null || continuation.trim() === '') break;
          const indent = continuation.match(/^([ \t]*)\S/)?.[1];
          const delimiterOnly = /^[)}]\s*,?\s*(?:do(?:\s*\|[^|\r\n]*\|)?)?$/.test(continuation.trim());
          if (indent === undefined || (!delimiterOnly && indent.length <= startIndent.length)) {
            break;
          }
          collected.push({ text: continuation.trim(), indent });
          statement = collected.map((line) => line.text).join(' ');
          if (statement.length > 512) break;
          frames = delimiterState(collected);
          if (!frames) break;
          incomplete = statement.endsWith(',') || frames.length > 0;
        }
        if (!incomplete && statement.length <= 512) statements.push(statement);
      }
    }
    return statements;
  };
  const hasPositiveErrorSelector = (testCase) => selectorStatements(testCase).some(selectorStatementPositive);
  const positiveNoticeSelectorStatement = (statement) => {
    if (noticeLiteralIsNegative(statement)) return false;
    const call = statement.match(
      /^([ \t]*assert_(?:select|selector|dom)(?:[ \t]+|\([ \t]*))(["'])((?:(?!\2).)*)\2/,
    );
    if (!call || /#(?:\{|@|\$)/.test(call[3])) return false;
    const errorSelector = call[3].replace(/([.#])([A-Za-z_][A-Za-z0-9_-]*)/g, (_identifier, sigil, name) => {
      const errorName = name.replace(/(^|[-_])(?:flash|notice)(?=$|[-_])/gi, '$1errors');
      return `${sigil}${errorName}`;
    });
    if (errorSelector === call[3]) return false;
    return selectorStatementPositive(
      `${call[1]}${call[2]}${errorSelector}${call[2]}${statement.slice(call[0].length)}`,
    );
  };
  const hasPositiveNoticeSelector = (testCase) =>
    selectorStatements(testCase).some(positiveNoticeSelectorStatement);
  const postResponseScopes = (testCase) => {
    const scopes = [];
    let currentScope = null;
    for (const physicalLine of testCase.physicalLines) {
      const codeLine = stripRubyTrailingComment(physicalLine)?.trim() ?? '';
      const request = codeLine.match(/^(delete|get|head|options|patch|post|put)(?:\s+|\()/);
      if (request) {
        if (currentScope !== null) scopes.push(currentScope);
        currentScope = request[1] === 'post' ? [] : null;
      }
      if (currentScope !== null) currentScope.push(physicalLine);
    }
    if (currentScope !== null) scopes.push(currentScope);
    return scopes.map((physicalLines) => ({ ...testCase, body: physicalLines.join('\n'), physicalLines }));
  };
  const hasPotentiallyInactiveEvidence = (testCase) =>
    testCase.physicalLines.some((physicalLine) => {
      const codeLine = maskRubyStringAndCommentContent(physicalLine);
      const supportedCountDifference =
        codeLine !== null &&
        /^\s*assert_difference(?:\s+|\()\s*->\s*\{\s*[A-Z][A-Za-z0-9_:]*\.count\s*\}(?:\s*,\s*1)?\s*\)?\s+do\s*$/.test(
          codeLine,
        );
      return (
        codeLine === null ||
        /\b(?:case|class|def|elsif|ensure|for|if|module|rescue|unless|until|when|while)\b/.test(codeLine) ||
        (!supportedCountDifference && /->|(?:^|[; \t])(?:lambda|proc|Proc\.new)(?=$|[; \t({])/.test(codeLine))
      );
    });
  const qualifiesFailure = (testCase) => {
    if (hasPotentiallyInactiveEvidence(testCase)) return false;
    return postResponseScopes(testCase).some((responseScope) => {
      const nonSelectorBody = responseScope.body
        .split(/\r?\n/)
        .filter(
          (line) =>
            !/^\s*(?:assert_(?:(?:no|not)_)?(?:select|selector|dom)|refute_(?:select|selector|dom))\b/i.test(
              line,
            ),
        )
        .join('\n');
      const response =
        /^\s*assert_response(?:\s+|\()\s*(?::(?:unprocessable_entity|unprocessable_content)\b|422\b)/m.test(
          responseScope.body,
        );
      const errors =
        hasPositiveValueAssertion(
          nonSelectorBody,
          /(?:^|[^A-Za-z0-9_])@?(?:[A-Za-z_][A-Za-z0-9_]*\.errors?\b|response\.parsed_body\b[^\r\n]*\berrors?\b)/i,
          false,
          validationErrorLiteralIsNegative,
        ) ||
        hasPositiveErrorSelector(responseScope) ||
        hasRenderedBodyAssertion(responseScope.body);
      return response && errors;
    });
  };
  const qualifiesSuccess = (testCase) => {
    if (hasPotentiallyInactiveEvidence(testCase)) return false;
    const successLines = testCase.body.split(/\r?\n/);
    const resourceStemsForConstant = (constant) => {
      const singular = constant
        .split('::')
        .at(-1)
        .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
        .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
        .toLowerCase();
      let plural = `${singular}s`;
      if (/[^aeiou]y$/.test(singular)) plural = `${singular.slice(0, -1)}ies`;
      else if (/(?:s|x|z|ch|sh)$/.test(singular)) plural = `${singular}es`;
      return { plural, singular };
    };
    const staticPostRequest = (postStatement) => {
      const requestPrefix = postStatement.match(/^\s*post(?:\s+|\(\s*)\s*[a-z][a-z0-9_]*_(?:path|url)\b/);
      if (!requestPrefix) return false;
      const parenthesized = /^\s*post\s*\(/.test(postStatement);
      let argumentsTail = postStatement.slice(requestPrefix[0].length).trim();
      if (parenthesized) {
        if (!argumentsTail.endsWith(')')) return false;
        argumentsTail = argumentsTail.slice(0, -1).trim();
      }
      if (argumentsTail === '') return true;
      if (!argumentsTail.startsWith(',')) return false;
      argumentsTail = argumentsTail.slice(1).trim();
      const paramsPrefix = argumentsTail.match(/^params\s*:\s*/);
      if (!paramsPrefix) return false;
      const paramsHash = argumentsTail.slice(paramsPrefix[0].length).trim();
      if (!paramsHash.startsWith('{')) return false;
      let depth = 0;
      let closingIndex = -1;
      for (let index = 0; index < paramsHash.length; index += 1) {
        if (paramsHash[index] === '{') depth += 1;
        else if (paramsHash[index] === '}') {
          depth -= 1;
          if (depth < 0) return false;
          if (depth === 0) {
            closingIndex = index;
            break;
          }
        }
      }
      if (closingIndex !== paramsHash.length - 1 || depth !== 0) return false;
      const literalBody = paramsHash
        .slice(1, -1)
        .replace(/\b[A-Za-z_][A-Za-z0-9_]*\s*:/g, '')
        .replace(/:[A-Za-z_][A-Za-z0-9_]*\b/g, '')
        .replace(/\b(?:false|nil|true)\b/g, '')
        .replace(/\b(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\b/g, '');
      return !/[^\s{},[\]:,+-]/.test(literalBody);
    };
    const createdRecord = successLines.some((line, index) => {
      const start = line.match(
        /^([ \t]*)assert_difference(?:\s+|\()\s*(?:"([A-Z][A-Za-z0-9_:]*)\.count"|'([A-Z][A-Za-z0-9_:]*)\.count'|->\s*\{\s*([A-Z][A-Za-z0-9_:]*)\.count\s*\})(?:\s*,\s*1)?\s*\)?\s+do\s*$/,
      );
      if (!start) return false;
      const expectedResource = resourceStemsForConstant(start[2] ?? start[3] ?? start[4]);
      const blockLines = [];
      let closed = false;
      for (let offset = 1; offset <= 32; offset += 1) {
        const blockLine = successLines[index + offset];
        if (blockLine === undefined) return false;
        const closingIndent = blockLine.match(/^([ \t]*)end\s*$/)?.[1];
        if (closingIndent === start[1]) {
          closed = true;
          break;
        }
        const contentIndent = blockLine.match(/^([ \t]*)\S/)?.[1];
        if (contentIndent !== undefined && contentIndent.length <= start[1].length) return false;
        blockLines.push(blockLine);
      }
      if (!closed) return false;
      const contentLines = blockLines.filter((blockLine) => blockLine.trim() !== '');
      if (contentLines.length === 0 || !/^\s*post(?:\s+|\()/.test(contentLines[0])) return false;
      if (contentLines.some((blockLine) => /#(?:\{|@|\$)/.test(blockLine))) return false;
      const postIndent = contentLines[0].match(/^([ \t]*)/)?.[1].length ?? 0;
      for (let contentIndex = 1; contentIndex < contentLines.length; contentIndex += 1) {
        const blockLine = contentLines[contentIndex];
        const indent = blockLine.match(/^([ \t]*)/)?.[1].length ?? 0;
        const finalClosingParenthesis =
          contentIndex === contentLines.length - 1 && indent === postIndent && /^\s*\)\s*$/.test(blockLine);
        if (indent <= postIndent && !finalClosingParenthesis) return false;
      }
      const postCodeLines = contentLines.map(maskRubyStringAndCommentContent);
      if (postCodeLines.some((line) => line === null)) return false;
      const postStatement = postCodeLines.join('\n');
      if (!staticPostRequest(postStatement)) return false;
      const postRoute = postStatement.match(/^\s*post(?:\s+|\(\s*)\s*([a-z][a-z0-9_]*)_(?:path|url)\b/)?.[1];
      const matchingRoute =
        postRoute !== undefined &&
        (postRoute === expectedResource.plural || postRoute.endsWith(`_${expectedResource.plural}`));
      const matchingParameter = new RegExp(`\\bparams\\s*:\\s*\\{\\s*${expectedResource.singular}\\s*:`).test(
        postStatement,
      );
      return matchingRoute || matchingParameter;
    });
    const responseScopes = postResponseScopes(testCase);
    return responseScopes.some((responseScope) => {
      const redirect = /^\s*assert_redirected_to(?:\s+|\()/m.test(responseScope.body);
      const message =
        hasPositiveValueAssertion(
          responseScope.body,
          /(?:\bflash\b|\bnotice\b)/i,
          true,
          noticeLiteralIsNegative,
        ) ||
        hasPositiveNoticeSelector(responseScope) ||
        (/^\s*follow_redirect!(?:\s*|\(\s*\))$/m.test(responseScope.body) &&
          hasRenderedBodyAssertion(responseScope.body)) ||
        (responseScopes.length === 1 && createdRecord);
      return redirect && message;
    });
  };
  return failureCandidates.some(
    (failureCase) =>
      qualifiesFailure(failureCase) &&
      successCandidates.some((successCase) => successCase !== failureCase && qualifiesSuccess(successCase)),
  );
};
const formTests = artifacts.filter((artifact) => {
  const uncommentedRuby = artifact.excerpt.replace(/^\s*#.*$/gm, '');
  return semanticFormIntegrationTest(artifact, uncommentedRuby);
});
const plainManifestBuildInvocation = (invocation) =>
  manifestBackedProductionBuild && /^(?:npm|pnpm) run build$/i.test(invocation);
const buildCommands = successfulCommands.filter((command) => {
  const allowedInvocation = buildEvidenceTargets(command).some((invocationLine) => {
    const targetCommand = stripBoundedTimeoutPrefix(invocationLine);
    return (
      targetCommand !== null &&
      !isHelpOrVersion(targetCommand) &&
      (/^(?:(?:RAILS_ENV|NODE_ENV)=production\s+)?(?:(?:bin\/rails|bundle exec rails|bundle exec rake|rake) assets:precompile|(?:bin\/shakapacker|bundle exec rake shakapacker:compile)|(?:npm|pnpm) run build:production)$/i.test(
        targetCommand,
      ) ||
        (targetCommand === compoundShakapackerBuildTarget && manifestBackedProductionBuild) ||
        targetCommand === 'env RAILS_ENV=production NODE_ENV=production bin/rails assets:precompile' ||
        plainManifestBuildInvocation(targetCommand))
    );
  });
  const buildResult =
    /compiled|compilation (?:complete|successful)|built successfully|assets? (?:written|built)|webpack compiled|rspack compiled/i.test(
      command.output,
    );
  const helpOutput = /usage:|options:|available commands/i.test(command.output);
  const errorOutput = /(?:^|\n)\s*(?:npm\s+ERR!|ERR!|ERROR:)|\b(?:failed|aborted)\b/i.test(command.output);
  return allowedInvocation && buildResult && !helpOutput && !errorOutput;
});
const manifestBackedBuildCommands = buildCommands.filter((command) =>
  buildEvidenceTargets(command).some((invocationLine) => {
    const targetCommand = stripBoundedTimeoutPrefix(invocationLine);
    return (
      targetCommand !== null &&
      (plainManifestBuildInvocation(targetCommand) || targetCommand === compoundShakapackerBuildTarget)
    );
  }),
);
const testOutputPassed =
  /0 failures|0 failed|pass(?:ed|ing)|[1-9][0-9]* examples?, 0 failures|[1-9][0-9]* tests?, 0 failures/i;
const railsTestSummary =
  /^[1-9][0-9]* runs?, [1-9][0-9]* assertions?, 0 failures, 0 errors(?:, [0-9]+ skips?)?$/;
const railsTestOutputPassed = (output) => {
  const lines = output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const summaries = lines.filter((line) => railsTestSummary.test(line));
  return summaries.length === 1 && lines.at(-1) === summaries[0];
};
const statusMarkedRailsTestTarget = (lines, output) => {
  if (
    lines.length !== 4 ||
    lines[0] !== 'source /workspace/pgtools/env.sh' ||
    lines[1] !== 'cd <LOCAL_PATH>/eval_app' ||
    !/^echo "FINAL_TEST_EXIT=\$\{PIPESTATUS\[0\]\}"$/.test(lines[3])
  ) {
    return null;
  }
  const pipelineMatch = lines[2].match(
    /^(RAILS_ENV=test bin\/rails test)\s+2>&1\s*\|\s*tail\s+(?:-n\s+|-)([1-9][0-9]{0,4})$/,
  );
  const outputLines = output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const summaries = outputLines.filter((line) => railsTestSummary.test(line));
  const markers = outputLines.filter((line) => /^FINAL_TEST_EXIT=-?[0-9]+$/.test(line));
  return pipelineMatch &&
    Number(pipelineMatch[2]) <= 1000 &&
    summaries.length === 1 &&
    markers.length === 1 &&
    markers[0] === 'FINAL_TEST_EXIT=0' &&
    outputLines.at(-2) === summaries[0] &&
    outputLines.at(-1) === markers[0]
    ? pipelineMatch[1]
    : null;
};
const stripRailsTestEnvironment = (line) => {
  if (!line.startsWith('RAILS_ENV=test ')) return line;
  const target = line.slice('RAILS_ENV=test '.length);
  return /^(?:(?:bundle exec )?rails test|bin\/rails test)(?:\s|$)/i.test(target) ? target : line;
};
const recognizedTestInvocation = (line) => {
  const target = stripRailsTestEnvironment(line);
  return (
    /^(?:(?:bundle exec )?(?:rspec|rails test|rake test)|bin\/rails test|npm (?:run )?test|pnpm (?:run )?test|jest|playwright)(?:\s|$)/i.test(
      target,
    ) && !/[;&|<>]/.test(target)
  );
};
const phaseStatusRailsTestTarget = (lines, output) => {
  const proof = immediatePhaseStatusTarget(lines, output, 'TEST', true, true);
  if (!proof || isHelpOrVersion(proof.target) || !recognizedTestInvocation(proof.target)) return null;
  const summaries = proof.outputLines.filter((line) => railsTestSummary.test(line));
  return summaries.length === 1 && proof.outputLines.at(-2) === summaries[0] ? proof.target : null;
};
const relativeCdPhaseStatusRailsTestTarget = (lines, output, outputTruncated) => {
  if (outputTruncated || /(?:^|\n)\s*(?:[^\n]*:\s*)?cd:\s/i.test(output)) return null;
  const proofLines = stripRelativeCdTestSetupPrefix(lines);
  return proofLines ? phaseStatusRailsTestTarget(proofLines, output) : null;
};
const testEvidenceTargets = (command) => {
  const rawLines = topLevelShellLines(command.command);
  const lines = stripSanitizedSetupPrefix(rawLines);
  const phaseLines = stripExplicitPgTestSetupPrefix(rawLines) ?? stripSanitizedPhaseSetupPrefix(rawLines);
  const directTargets = lines.length === 1 && recognizedTestInvocation(lines[0]) ? [lines[0]] : [];
  const statusMarkedTarget = statusMarkedRailsTestTarget(rawLines, command.output);
  const phaseStatusTarget = phaseStatusRailsTestTarget(phaseLines, command.output);
  const relativeCdPhaseStatusTarget = relativeCdPhaseStatusRailsTestTarget(
    rawLines,
    command.output,
    command.output_truncated,
  );
  if (statusMarkedTarget || phaseStatusTarget || relativeCdPhaseStatusTarget) {
    return [
      ...directTargets,
      ...(statusMarkedTarget ? [statusMarkedTarget] : []),
      ...(phaseStatusTarget ? [phaseStatusTarget] : []),
      ...(relativeCdPhaseStatusTarget ? [relativeCdPhaseStatusTarget] : []),
    ];
  }
  if (lines.length !== 1) return directTargets;
  const pipelineMatch = lines[0].match(boundedTailPipeline);
  if (
    !pipelineMatch ||
    Number(pipelineMatch[2]) > 1000 ||
    !recognizedTestInvocation(pipelineMatch[1]) ||
    !railsTestOutputPassed(command.output)
  ) {
    return directTargets;
  }
  return [...directTargets, pipelineMatch[1]];
};
const testCommands = successfulCommands.filter(
  (command) => testEvidenceTargets(command).length > 0 && testOutputPassed.test(command.output),
);
const fullSuitePrefixes = [
  ['rspec'],
  ['bundle', 'exec', 'rspec'],
  ['bin/rails', 'test'],
  ['bundle', 'exec', 'rails', 'test'],
  ['bundle', 'exec', 'rake', 'test'],
  ['rake', 'test'],
  ['npm', 'test'],
  ['npm', 'run', 'test'],
  ['pnpm', 'test'],
  ['pnpm', 'run', 'test'],
  ['jest'],
  ['playwright'],
];
const fullSuiteTest = (invocation) => {
  const tokens = stripRailsTestEnvironment(invocation).trim().split(/\s+/);
  return fullSuitePrefixes.some((prefix) => {
    const prefixMatches = prefix.every((token, index) => tokens[index]?.toLowerCase() === token);
    if (!prefixMatches) return false;
    if (tokens.length === prefix.length) return true;
    const railsTest = /(?:^|\/)rails$/.test(prefix.at(-2) ?? '') && prefix.at(-1) === 'test';
    return railsTest && tokens.length === prefix.length + 1 && tokens.at(-1) === '-v';
  });
};
const hasSkippedRailsTests = (output) =>
  output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .some((line) => railsTestSummary.test(line) && /, [1-9][0-9]* skips?$/.test(line));
const testCommandsFor = (matchedArtifacts) =>
  testCommands.filter((command) => {
    if (hasSkippedRailsTests(command.output)) return false;
    return testEvidenceTargets(command).some((invocation) => {
      if (fullSuiteTest(invocation)) return true;
      return matchedArtifacts.some((artifact) => {
        const testPath = artifact.path.match(/(?:^|\/)((?:spec|test)\/.*)$/i)?.[1];
        if (!testPath) return false;
        return invocation.includes(testPath) || invocation.includes(path.posix.dirname(testPath));
      });
    });
  });
const pageTestCommands = testCommandsFor(pageTests);
const formTestCommands = testCommandsFor(formTests);

const installProPassed =
  rubyProManifests.length > 0 && jsProManifests.length > 0 && installCommands.length > 0;
const pageTestsPassed = pageTests.length > 0 && pageTestCommands.length > 0;
const formTestsPassed = formTests.length > 0 && formTestCommands.length > 0;
const rscRoutePassed = rscRoutes.length > 0 && rscSources.length > 0 && pageTestsPassed;
const formValidationPassed =
  validationModels.length > 0 &&
  validationControllers.length > 0 &&
  formTests.length > 0 &&
  formTestCommands.length > 0;

const outcomeRows = [
  {
    id: 'install.pro',
    status: installProPassed ? 'pass' : 'unknown',
    reason: installProPassed
      ? 'The public scaffold command exited 0 and captured Ruby/JavaScript manifests contain exact Pro dependencies.'
      : 'A successful public scaffold plus exact Ruby and JavaScript Pro manifest entries are not all evidenced.',
    citations: [
      ...artifactCitations(rubyProManifests),
      ...artifactCitations(jsProManifests),
      ...commandCitations(installCommands),
    ],
  },
  {
    id: 'rsc.route',
    status: rscRoutePassed ? 'pass' : 'unknown',
    reason: rscRoutePassed
      ? 'An RSC-specific route and source are paired with successful test output.'
      : 'RSC-specific route, source, and successful test output are not all evidenced.',
    citations: [
      ...artifactCitations(rscRoutes),
      ...artifactCitations(rscSources),
      ...commandCitations(pageTestCommands),
    ],
  },
  {
    id: 'form.validation',
    status: formValidationPassed ? 'pass' : 'unknown',
    reason: formValidationPassed
      ? 'Model validation, invalid-response controller behavior, failure/success tests, and successful test output are evidenced.'
      : 'Server validation, invalid-response behavior, failure/success tests, and successful output are not all evidenced.',
    citations: [
      ...artifactCitations(validationModels),
      ...artifactCitations(validationControllers),
      ...artifactCitations(formTests),
      ...commandCitations(formTestCommands),
    ],
  },
  {
    id: 'tests.page',
    status: pageTestsPassed ? 'pass' : 'unknown',
    reason: pageTestsPassed
      ? 'A page/RSC-specific test is paired with successful test output.'
      : 'No passing page/RSC test is independently proven.',
    citations: [...artifactCitations(pageTests), ...commandCitations(pageTestCommands)],
  },
  {
    id: 'tests.form',
    status: formTestsPassed ? 'pass' : 'unknown',
    reason: formTestsPassed
      ? 'A test covering both form failure and success is paired with successful test output.'
      : 'Passing coverage of both form failure and success is not independently proven.',
    citations: [...artifactCitations(formTests), ...commandCitations(formTestCommands)],
  },
  {
    id: 'build.production',
    status: buildCommands.length > 0 ? 'pass' : 'unknown',
    reason:
      buildCommands.length > 0
        ? 'A production-relevant build command completed with exit status 0.'
        : 'No successful production build command was captured.',
    citations: [
      ...(evalAppPackageManifest && manifestBackedBuildCommands.length > 0
        ? artifactCitations([evalAppPackageManifest])
        : []),
      ...commandCitations(buildCommands),
    ],
  },
  {
    id: 'tests.green',
    status: testCommands.length > 0 ? 'pass' : 'unknown',
    reason:
      testCommands.length > 0
        ? 'At least one relevant automated test command completed with exit status 0.'
        : 'No successful relevant automated test command was captured.',
    citations: commandCitations(testCommands),
  },
  {
    id: 'unaided',
    status: invocation.human_followups_sent === 0 ? 'pass' : 'unknown',
    reason:
      invocation.human_followups_sent === 0
        ? 'The runner-owned invocation record proves that no human follow-up input was sent.'
        : 'Runner-owned evidence does not prove that the attempt was unaided.',
    citations: invocation.human_followups_sent === 0 ? ['invocation.json#/human_followups_sent'] : [],
  },
];

const reportCompleted = report.status === 'completed';
const sourceLimitsExceeded = eventLimits.exceeded || artifactLimits.exceeded;
const outcomesComplete =
  reportCompleted && !sourceLimitsExceeded && outcomeRows.every((item) => item.status === 'pass');
const completionRow = outcomesComplete
  ? {
      id: 'evidence.complete',
      status: 'pass',
      reason: 'Every required outcome row has passing, cited evidence.',
      citations: ['command-evidence.json', 'artifact-evidence.json', 'SHA256SUMS'],
    }
  : {
      id: 'evidence.complete',
      status: 'unknown',
      reason: sourceLimitsExceeded
        ? 'Evidence source limits were exceeded; completeness remains UNKNOWN.'
        : 'At least one required outcome row is not proven; evidence completeness remains UNKNOWN.',
      citations: [],
    };
const items = [...outcomeRows, completionRow];
let overall = 'incomplete';
if (sourceLimitsExceeded) {
  overall = 'incomplete';
} else if (outcomesComplete) {
  overall = 'pass';
} else if (reportCompleted) {
  overall = 'fail';
}
const rubricResults = { schema_version: '1.0', overall, items };

fs.writeFileSync(
  path.join(outputDir, 'command-evidence.json'),
  `${JSON.stringify(commandEvidence, null, 2)}\n`,
  { mode: 0o600 },
);
fs.writeFileSync(
  path.join(outputDir, 'artifact-evidence.json'),
  `${JSON.stringify(artifactEvidence, null, 2)}\n`,
  { mode: 0o600 },
);
fs.writeFileSync(path.join(outputDir, 'rubric-results.json'), `${JSON.stringify(rubricResults, null, 2)}\n`, {
  mode: 0o600,
});
