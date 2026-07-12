#!/usr/bin/env node
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { normalizeCommand } from './normalize-command.mjs';
import { redactSensitiveValues } from './sensitive-values.mjs';

const [eventsPath, workspace, outputDir, reportPath, invocationPath] = process.argv.slice(2);
if (!eventsPath || !workspace || !outputDir || !reportPath || !invocationPath) {
  console.error('usage: derive-evidence.mjs EVENTS WORKSPACE OUTPUT REPORT INVOCATION');
  process.exit(64);
}

const MAX_OUTPUT = 12_000;
const MAX_EXCERPT = 16_000;
const sanitize = (value) =>
  redactSensitiveValues(
    String(value)
      .replaceAll(/\/Users\/[^\s"']+/g, '<LOCAL_PATH>')
      .replaceAll(/\/private\/tmp(?:\/[^\s"']*)?/g, '<LOCAL_PATH>')
      .replaceAll(/\/tmp\/[^\s"']+/g, '<LOCAL_PATH>')
      .replaceAll(/\/var\/folders\/[^\s"']+/g, '<LOCAL_PATH>'),
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
const commandEvidence = { schema_version: '1.0', commands };

const excludedDirectories = new Set(['.git', 'node_modules', 'vendor', 'tmp', 'log', 'storage']);
const selectedBasenames = new Set(['Gemfile', 'package.json', 'routes.rb']);
const selectedExtensions = new Set(['.rb', '.js', '.jsx', '.ts', '.tsx']);
const selectedRoots = ['app/', 'spec/', 'test/'];
const artifacts = [];

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (!entry.isSymbolicLink() && !excludedDirectories.has(entry.name)) {
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        walk(absolute);
      } else if (entry.isFile()) {
        const relative = path.relative(workspace, absolute).replaceAll(path.sep, '/');
        const insideSelectedRoot = selectedRoots.some((root) => relative.includes(`/${root}`));
        const selected =
          selectedBasenames.has(entry.name) ||
          (insideSelectedRoot && selectedExtensions.has(path.extname(entry.name)));
        if (selected) {
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
    }
  }
}
walk(workspace);
artifacts.sort((left, right) => left.path.localeCompare(right.path));
const artifactEvidence = { schema_version: '1.0', artifacts };

const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
const invocation = JSON.parse(fs.readFileSync(invocationPath, 'utf8'));
const successfulCommands = commands.filter((command) => command.exit_code === 0);
const successfulOutcome = (commandPattern, outputPattern) =>
  successfulCommands.filter(
    (command) => commandPattern.test(command.command) && outputPattern.test(command.output),
  );
const matchingArtifacts = (pathPattern, contentPattern) =>
  artifacts.filter((artifact) => pathPattern.test(artifact.path) && contentPattern.test(artifact.excerpt));
const artifactCitations = (matched) => matched.map((artifact) => `artifact-evidence.json#${artifact.path}`);
const commandCitations = (matched) => matched.map((command) => `command-evidence.json#${command.id}`);
const unwrapShellCommand = (command) => {
  const match = command.match(/^\/(?:usr\/)?bin\/(?:zsh|bash|sh) -lc (['"])([\s\S]*)\1$/);
  return (match?.[2] ?? command).trim();
};
const isHelpOrVersion = (command) => /(?:^|\s)(?:--help|--version|-h|-V)(?:\s|$)/.test(command);

const rubyProManifests = matchingArtifacts(/Gemfile$/, /react_on_rails_pro/);
const jsProManifests = matchingArtifacts(/package\.json$/, /react-on-rails-pro/);
const installCommands = successfulCommands.filter((command) => {
  const invocation = unwrapShellCommand(command.command);
  if (isHelpOrVersion(invocation)) return false;
  return /^(?:npx(?: --yes)?|npm exec|pnpm dlx) create-react-on-rails-app(?:@[^\s]+)? [A-Za-z0-9][A-Za-z0-9._-]*(?:\s+[^;&|]+)?$/.test(
    invocation,
  );
});
const rscRoutes = matchingArtifacts(/config\/routes\.rb$/, /rsc|server_component|server-component/i);
const rscSources = matchingArtifacts(
  /app\/.*(?:\.server\.|rsc|server_component)/i,
  /export|class|module|render/i,
);
const validationModels = matchingArtifacts(/app\/models\/.*\.rb$/, /validates|validate\s/);
const validationControllers = matchingArtifacts(
  /app\/controllers\/.*\.rb$/,
  /unprocessable_entity|unprocessable_content|errors/,
);
const pageTests = matchingArtifacts(
  /(?:spec|test)\/.*(?:page|rsc).*(?:_spec\.rb|_test\.rb|\.(?:test|spec)\.[jt]sx?)$/i,
  /expect|assert|test\s|it\s/,
);
const formTests = matchingArtifacts(
  /(?:spec|test)\/.*(?:form|request|system).*(?:_spec\.rb|_test\.rb|\.(?:test|spec)\.[jt]sx?)$/i,
  /invalid[\s\S]*valid|valid[\s\S]*invalid/i,
);
const buildCommands = successfulCommands.filter((command) => {
  const invocation = unwrapShellCommand(command.command);
  if (isHelpOrVersion(invocation)) return false;
  const allowedInvocation =
    /^(?:(?:RAILS_ENV|NODE_ENV)=production\s+)?(?:(?:bin\/rails|bundle exec rails|bundle exec rake|rake) assets:precompile|(?:bin\/shakapacker|bundle exec rake shakapacker:compile)|(?:npm|pnpm) run build:production)$/i.test(
      invocation,
    );
  const buildResult =
    /compiled|compilation (?:complete|successful)|built successfully|assets? (?:written|built)|webpack compiled|rspack compiled/i.test(
      command.output,
    );
  const helpOutput = /usage:|options:|available commands/i.test(command.output);
  return allowedInvocation && buildResult && !helpOutput;
});
const testCommands = successfulOutcome(
  /rspec|rails test|rake test|npm (?:run )?test|pnpm (?:run )?test|jest|playwright/i,
  /0 failures|0 failed|pass(?:ed|ing)|[1-9][0-9]* examples?, 0 failures|[1-9][0-9]* tests?, 0 failures/i,
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
  const tokens = invocation.trim().split(/\s+/);
  return fullSuitePrefixes.some(
    (prefix) =>
      tokens.length === prefix.length &&
      prefix.every((token, index) => tokens[index]?.toLowerCase() === token) &&
      tokens.every((token) => !token.startsWith('-')),
  );
};
const testCommandsFor = (matchedArtifacts) =>
  testCommands.filter((command) => {
    const invocation = unwrapShellCommand(command.command);
    if (fullSuiteTest(invocation)) return true;
    return matchedArtifacts.some((artifact) => {
      const testPath = artifact.path.match(/(?:^|\/)((?:spec|test)\/.*)$/i)?.[1];
      if (!testPath) return false;
      return invocation.includes(testPath) || invocation.includes(path.posix.dirname(testPath));
    });
  });
const pageTestCommands = testCommandsFor(pageTests);
const formTestCommands = testCommandsFor(formTests);

const installProPassed =
  rubyProManifests.length > 0 && jsProManifests.length > 0 && installCommands.length > 0;
const rscRoutePassed = rscRoutes.length > 0 && rscSources.length > 0 && pageTestCommands.length > 0;
const formValidationPassed =
  validationModels.length > 0 &&
  validationControllers.length > 0 &&
  formTests.length > 0 &&
  formTestCommands.length > 0;
const pageTestsPassed = pageTests.length > 0 && pageTestCommands.length > 0;
const formTestsPassed = formTests.length > 0 && formTestCommands.length > 0;

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
      ? 'Model validation, invalid-response controller behavior, both-outcome tests, and successful test output are evidenced.'
      : 'Server validation, invalid-response behavior, both-outcome tests, and successful output are not all evidenced.',
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
      ? 'A test containing both invalid and valid outcomes is paired with successful test output.'
      : 'Passing coverage of both form outcomes is not independently proven.',
    citations: [...artifactCitations(formTests), ...commandCitations(formTestCommands)],
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
    status: invocation.human_followups_sent === 0 ? 'pass' : 'unknown',
    reason:
      invocation.human_followups_sent === 0
        ? 'The runner-owned invocation record proves that no human follow-up input was sent.'
        : 'Runner-owned evidence does not prove that the attempt was unaided.',
    citations: invocation.human_followups_sent === 0 ? ['invocation.json#/human_followups_sent'] : [],
  },
];

const reportCompleted = report.status === 'completed';
const outcomesComplete = reportCompleted && outcomeRows.every((item) => item.status === 'pass');
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
      reason: 'At least one required outcome row is not proven; evidence completeness remains UNKNOWN.',
      citations: [],
    };
const items = [...outcomeRows, completionRow];
let overall = 'incomplete';
if (outcomesComplete) {
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
