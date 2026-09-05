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
const sanitizeTrustedEvent = (value) =>
  redactSensitiveValues(redactLocalPaths(value, [workspace, outputDir]), {
    runtimeGeneratedSecretMode: 'trusted',
  });

const truncate = (value, limit, sanitizer = sanitize) => {
  const safe = sanitizer(value);
  return { value: safe.slice(0, limit), truncated: safe.length > limit };
};

const { events, limits: eventLimits } = readBoundedEvents(eventsPath);

const commands = [];
for (const event of events) {
  const item = event?.item;
  if (event?.type === 'item.completed' && item?.type === 'command_execution') {
    const output = truncate(item.aggregated_output ?? item.output ?? '', MAX_OUTPUT, sanitizeTrustedEvent);
    const normalizedCommand = sanitizeTrustedEvent(normalizeCommand(item.command) || 'UNKNOWN');
    commands.push({
      id: `command-${commands.length + 1}`,
      command: normalizedCommand.replaceAll('<EVAL_WORKSPACE>', '<LOCAL_PATH>'),
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
const selectedSourceExtensions = new Set(['.erb', '.haml', '.js', '.jsx', '.slim', '.ts', '.tsx']);
const selectedSourceRoots = ['app/', 'spec/', 'test/'];
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
          const insideSelectedSourceRoot = selectedSourceRoots.some(
            (root) => relative.startsWith(root) || relative.includes(`/${root}`),
          );
          const selected =
            selectedBasenames.has(entry.name) ||
            path.extname(entry.name) === '.rb' ||
            (insideSelectedSourceRoot && selectedSourceExtensions.has(path.extname(entry.name)));
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

// Parsing these runner-owned inputs keeps malformed input fail-closed. They are
// evidence for a human reviewer, not authority for semantic grading.
JSON.parse(fs.readFileSync(reportPath, 'utf8'));
JSON.parse(fs.readFileSync(invocationPath, 'utf8'));

const sourceLimitsExceeded = eventLimits.exceeded || artifactLimits.exceeded;
const reviewReason = sourceLimitsExceeded
  ? 'Captured evidence exceeded a collection limit. Review the recorded limit facts and available evidence manually.'
  : 'Semantic coverage requires human review of the captured commands and artifacts; no source or shell semantic classifier was run.';
const rowIds = [
  'install.pro',
  'rsc.route',
  'form.validation',
  'tests.page',
  'tests.form',
  'build.production',
  'tests.green',
  'unaided',
  'evidence.complete',
];
const rubricResults = {
  schema_version: '1.0',
  overall: 'needs-review',
  items: rowIds.map((id) => ({
    id,
    status: 'unknown',
    reason: reviewReason,
    citations: ['command-evidence.json', 'artifact-evidence.json', 'invocation.json'],
  })),
};

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
