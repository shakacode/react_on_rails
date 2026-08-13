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
  const pipelineMatch = lines[1].match(statusMarkedScaffoldPipeline);
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
  const proof = immediatePhaseStatusTarget(lines, output, 'SCAFFOLD');
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
  let quote = null;
  let continuedFromPrevious = false;
  for (const physicalLine of invocation.split(/\r?\n/)) {
    const startedInsideSyntax = quote !== null || continuedFromPrevious;
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
    if (!startedInsideSyntax && quote === null && !continuedToNext) {
      const candidate = physicalLine.slice(0, commentAt).trim();
      if (candidate) executableLines.push(candidate);
    }
    continuedFromPrevious = continuedToNext;
  }
  return executableLines;
};
const normalizedEvidenceLines = (command) => stripSanitizedSetupPrefix(topLevelShellLines(command));
const pipefailPipelineTargets = (lines) =>
  lines.flatMap((line, index) => {
    const pipelineMatch = line.match(boundedLogPipeline);
    const hasTopLevelPipefail = lines.length === 2 && index === 1 && lines[0] === 'set -o pipefail';
    return pipelineMatch && hasTopLevelPipefail && Number(pipelineMatch[2]) <= 1000 ? [pipelineMatch[1]] : [];
  });
const installEvidenceTargets = (command) => {
  const rawLines = topLevelShellLines(command.command);
  const lines = stripSanitizedSetupPrefix(rawLines);
  const phaseLines = stripScaffoldRetrySetupPrefix(rawLines) ?? stripSanitizedPhaseSetupPrefix(rawLines);
  const pipefailTargets = pipefailPipelineTargets(lines);
  const statusMarkedTarget = statusMarkedScaffoldTarget(rawLines, command.output);
  const phaseStatusTarget = phaseStatusScaffoldTarget(phaseLines, command.output);
  const completionBackedTarget = (() => {
    if (lines.length !== 1 || !completedScaffoldOutput(command.output)) return [];
    const pipelineMatch = lines[0].match(completedScaffoldLogPipeline);
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
const rubyTestCases = (content) => {
  const starts = [...content.matchAll(/^([ \t]*)test\s+(?:"([^"\r\n]+)"|'([^'\r\n]+)')\s+do\b[^\r\n]*$/gm)];
  return starts.flatMap((match, index) => {
    const bodyRegion = content.slice(
      match.index + match[0].length,
      starts[index + 1]?.index ?? content.length,
    );
    const declarationIndent = match[1];
    const regionLines = bodyRegion.split(/\r?\n/);
    const closingEnd = regionLines.findIndex(
      (line) => line.match(/^([ \t]*)end\s*$/)?.[1] === declarationIndent,
    );
    if (closingEnd < 0) return [];

    const body = regionLines
      .slice(0, closingEnd)
      .filter((line) => {
        const indent = line.match(/^([ \t]*)\S/)?.[1];
        return indent?.startsWith(declarationIndent) && indent.length > declarationIndent.length;
      })
      .join('\n');
    return [{ name: match[2] ?? match[3], body }];
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
  const failureCase = cases.find((testCase) =>
    /\b(?:server-side\s+)?validation failure\b/i.test(testCase.name),
  );
  const successCase = cases.find((testCase) => /\bsuccessful submission\b/i.test(testCase.name));
  if (!failureCase || !successCase || failureCase === successCase) return false;

  const hasPost = (body) => /^\s*post(?:\s+|\()/m.test(body);
  const hasRenderedBodyAssertion = (body) =>
    /^\s*(?:assert_includes|refute_includes)(?:\s+|\()\s*(?:@response|response)\.body\s*,/m.test(body) ||
    /^\s*assert_match(?:\s+|\()\s*(?:"[^"\r\n]*[^\s"\r\n][^"\r\n]*"|'[^'\r\n]*[^\s'\r\n][^'\r\n]*')\s*,\s*(?:@response|response)\.body\s*\)?\s*$/m.test(
      body,
    );
  const failureResponse =
    /^\s*assert_response(?:\s+|\()\s*(?::(?:unprocessable_entity|unprocessable_content)\b|422\b)/m.test(
      failureCase.body,
    );
  const failureErrors =
    /^\s*(?:assert\w*|refute\w*)\b[^\r\n]*\berrors?\b/im.test(failureCase.body) ||
    hasRenderedBodyAssertion(failureCase.body);
  const successRedirect = /^\s*assert_redirected_to(?:\s+|\()/m.test(successCase.body);
  const successMessage =
    /^\s*(?:assert\w*|refute\w*)\b[^\r\n]*(?:\bflash\b|\bnotice\b)/im.test(successCase.body) ||
    (/^\s*follow_redirect!(?:\s*|\(\s*\))$/m.test(successCase.body) &&
      hasRenderedBodyAssertion(successCase.body));
  return (
    hasPost(failureCase.body) &&
    hasPost(successCase.body) &&
    failureResponse &&
    failureErrors &&
    successRedirect &&
    successMessage
  );
};
const formTests = artifacts.filter((artifact) => {
  const uncommentedRuby = artifact.excerpt.replace(/^\s*#.*$/gm, '');
  const outcomeContent = /\.rb$/i.test(artifact.path) ? uncommentedRuby : artifact.excerpt;
  const bothOutcomes = /invalid[\s\S]*valid|valid[\s\S]*invalid/i.test(outcomeContent);
  const categorizedFormTest =
    /(?:spec|test)\/(?:(?:.*\/)?integration\/.*|.*(?:form|request|system).*)(?:_spec\.rb|_test\.rb|\.(?:test|spec)\.[jt]sx?)$/i.test(
      artifact.path,
    );
  const controllerIntegrationTest =
    /test\/controllers\/.*_test\.rb$/i.test(artifact.path) &&
    /^\s*class\s+[A-Za-z_][A-Za-z0-9_:]*\s*<\s*ActionDispatch::IntegrationTest\b/m.test(uncommentedRuby) &&
    /invalid[\s\S]*valid|valid[\s\S]*invalid/i.test(uncommentedRuby);
  return (
    (bothOutcomes && categorizedFormTest) ||
    controllerIntegrationTest ||
    semanticFormIntegrationTest(artifact, uncommentedRuby)
  );
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
    return targetCommand !== null && plainManifestBuildInvocation(targetCommand);
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
const testEvidenceTargets = (command) => {
  const rawLines = topLevelShellLines(command.command);
  const lines = stripSanitizedSetupPrefix(rawLines);
  const phaseLines = stripExplicitPgTestSetupPrefix(rawLines) ?? stripSanitizedPhaseSetupPrefix(rawLines);
  const directTargets = lines.length === 1 && recognizedTestInvocation(lines[0]) ? [lines[0]] : [];
  const statusMarkedTarget = statusMarkedRailsTestTarget(rawLines, command.output);
  const phaseStatusTarget = phaseStatusRailsTestTarget(phaseLines, command.output);
  if (statusMarkedTarget || phaseStatusTarget) {
    return [
      ...directTargets,
      ...(statusMarkedTarget ? [statusMarkedTarget] : []),
      ...(phaseStatusTarget ? [phaseStatusTarget] : []),
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
const testCommandsFor = (matchedArtifacts) =>
  testCommands.filter((command) => {
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
