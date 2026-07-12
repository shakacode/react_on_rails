#!/usr/bin/env node
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const [eventsPath, workspace, outputDir, reportPath] = process.argv.slice(2);
if (!eventsPath || !workspace || !outputDir || !reportPath) {
  console.error('usage: derive-evidence.mjs EVENTS WORKSPACE OUTPUT REPORT');
  process.exit(64);
}

const MAX_OUTPUT = 12_000;
const MAX_EXCERPT = 16_000;
const sanitize = (value) =>
  String(value)
    .replaceAll(/\/Users\/[^\s"']+/g, '<LOCAL_PATH>')
    .replaceAll(/\/private\/tmp(?:\/[^\s"']*)?/g, '<LOCAL_PATH>')
    .replaceAll(/\/tmp\/[^\s"']+/g, '<LOCAL_PATH>')
    .replaceAll(/\/var\/folders\/[^\s"']+/g, '<LOCAL_PATH>')
    .replaceAll(/(authorization["'=: ]+)[^ ,"']+/gi, '$1[REDACTED]')
    .replaceAll(/(cookie["'=: ]+)[^ ,"']+/gi, '$1[REDACTED]')
    .replaceAll(/(password["'=: ]+)[^ ,"']+/gi, '$1[REDACTED]')
    .replaceAll(/((?:api[_-]?key|token|secret|license[_-]?key)["'=: ]+)[^ ,"']+/gi, '$1[REDACTED]')
    .replaceAll(
      /(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/gis,
      '$1[REDACTED]$2',
    );

const truncate = (value, limit) => {
  const safe = sanitize(value);
  return { value: safe.slice(0, limit), truncated: safe.length > limit };
};

const events = fs
  .readFileSync(eventsPath, 'utf8')
  .split('\n')
  .filter(Boolean)
  .map((line) => JSON.parse(line));

const commands = [];
for (const event of events) {
  const item = event?.item;
  if (event?.type !== 'item.completed' || item?.type !== 'command_execution') continue;
  const output = truncate(item.aggregated_output ?? item.output ?? '', MAX_OUTPUT);
  commands.push({
    id: `command-${commands.length + 1}`,
    command: sanitize(item.command ?? 'UNKNOWN'),
    exit_code: Number.isInteger(item.exit_code) ? item.exit_code : null,
    status: String(item.status ?? 'unknown'),
    output: output.value,
    output_truncated: output.truncated,
  });
}
const commandEvidence = { schema_version: '1.0', commands };

const excludedDirectories = new Set(['.git', 'node_modules', 'vendor', 'tmp', 'log', 'storage']);
const selectedBasenames = new Set(['Gemfile', 'package.json', 'routes.rb']);
const selectedExtensions = new Set(['.rb', '.js', '.jsx', '.ts', '.tsx']);
const selectedRoots = ['app/', 'spec/', 'test/'];
const artifacts = [];

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.isSymbolicLink() || excludedDirectories.has(entry.name)) continue;
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(absolute);
      continue;
    }
    if (!entry.isFile()) continue;
    const relative = path.relative(workspace, absolute).split(path.sep).join('/');
    const insideSelectedRoot = selectedRoots.some((root) => relative.includes(`/${root}`));
    if (
      !selectedBasenames.has(entry.name) &&
      !(insideSelectedRoot && selectedExtensions.has(path.extname(entry.name)))
    ) {
      continue;
    }
    const content = fs.readFileSync(absolute);
    const excerpt = truncate(content.toString('utf8'), MAX_EXCERPT);
    artifacts.push({
      path: relative,
      sha256: crypto.createHash('sha256').update(content).digest('hex'),
      size: content.length,
      excerpt: excerpt.value,
      excerpt_truncated: excerpt.truncated,
    });
  }
}
walk(workspace);
artifacts.sort((left, right) => left.path.localeCompare(right.path));
const artifactEvidence = { schema_version: '1.0', artifacts };

const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
const allArtifactText = artifacts
  .map((artifact) => `${artifact.path}\n${artifact.excerpt}`)
  .join('\n')
  .toLowerCase();
const successfulCommands = commands.filter((command) => command.exit_code === 0);
const successful = (pattern) => successfulCommands.filter((command) => pattern.test(command.command));
const artifactCitations = (pattern) =>
  artifacts
    .filter((artifact) => pattern.test(`${artifact.path}\n${artifact.excerpt}`))
    .map((artifact) => `artifact-evidence.json#${artifact.path}`);
const commandCitations = (matched) => matched.map((command) => `command-evidence.json#${command.id}`);

const installCitations = artifactCitations(/react[_-]on[_-]rails[_-]pro/i);
const installPass =
  allArtifactText.includes('react_on_rails_pro') && allArtifactText.includes('react-on-rails-pro');
const rscCitations = artifactCitations(
  /react server component|server_component|\.server\.|react-on-rails-rsc|rsc/i,
);
const routeCitations = artifactCitations(/routes\.rb|route/i);
const validationCitations = artifactCitations(
  /validates|errors\.add|unprocessable_entity|unprocessable_content/i,
);
const pageTestCitations = artifactCitations(/(?:spec|test).*?(?:page|rsc)|(?:page|rsc).*?(?:spec|test)/i);
const formTestCitations = artifactCitations(/(?:spec|test).*?form|form.*?(?:spec|test)|invalid.*valid/i);
const buildCommands = successful(
  /assets:precompile|shakapacker|webpack|rspack|vite|npm run build|pnpm (?:run )?build/i,
);
const testCommands = successful(
  /rspec|rails test|rake test|npm (?:run )?test|pnpm (?:run )?test|jest|playwright/i,
);

const items = [
  {
    id: 'install.pro',
    status: installPass ? 'pass' : 'unknown',
    reason: installPass
      ? 'Ruby and JavaScript Pro dependencies are present in captured manifests.'
      : 'Captured manifests do not independently prove a complete Pro install.',
    citations: installCitations,
  },
  {
    id: 'rsc.route',
    status: rscCitations.length > 0 && routeCitations.length > 0 ? 'pass' : 'unknown',
    reason:
      rscCitations.length > 0 && routeCitations.length > 0
        ? 'Captured route and source artifacts contain RSC implementation evidence.'
        : 'No complete RSC route can be proven from captured artifacts.',
    citations: [...new Set([...rscCitations, ...routeCitations])],
  },
  {
    id: 'form.validation',
    status: validationCitations.length > 0 ? 'pass' : 'unknown',
    reason:
      validationCitations.length > 0
        ? 'Captured server source contains validation or invalid-response behavior.'
        : 'Server-side invalid and successful form outcomes are not independently proven.',
    citations: validationCitations,
  },
  {
    id: 'tests.page',
    status: pageTestCitations.length > 0 && testCommands.length > 0 ? 'pass' : 'unknown',
    reason:
      pageTestCitations.length > 0 && testCommands.length > 0
        ? 'A captured page/RSC test is paired with a successful test command.'
        : 'No passing page/RSC test is independently proven.',
    citations: [...pageTestCitations, ...commandCitations(testCommands)],
  },
  {
    id: 'tests.form',
    status: formTestCitations.length > 0 && testCommands.length > 0 ? 'pass' : 'unknown',
    reason:
      formTestCitations.length > 0 && testCommands.length > 0
        ? 'Captured form tests are paired with a successful test command.'
        : 'Passing coverage of both form outcomes is not independently proven.',
    citations: [...formTestCitations, ...commandCitations(testCommands)],
  },
  {
    id: 'build.production',
    status: buildCommands.length > 0 ? 'pass' : 'unknown',
    reason:
      buildCommands.length > 0
        ? 'A production-relevant build command completed with exit status 0.'
        : 'No successful production build command was captured.',
    citations: commandCitations(buildCommands),
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
    status: report.human_interventions === 0 ? 'pass' : 'fail',
    reason: `The schema-constrained report records ${report.human_interventions} human interventions; the runner supplied no follow-up input.`,
    citations: ['agent-report.json#/human_interventions'],
  },
  {
    id: 'evidence.complete',
    status: 'pass',
    reason:
      'The evidence derivation completed; validate-run verifies schemas, hashes, paths, and secret patterns.',
    citations: ['command-evidence.json', 'artifact-evidence.json', 'SHA256SUMS'],
  },
];

const overall =
  report.status !== 'completed'
    ? 'incomplete'
    : items.every((item) => item.status === 'pass')
      ? 'pass'
      : 'fail';
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
